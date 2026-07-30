package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"net"
	"os"
	"sync"
	"time"
)

type Client struct {
	Addr     *net.UDPAddr
	Conn     net.Conn // For TCP clients
	LastSeen time.Time
	Username string
}

type Packet struct {
	Username string `json:"username"`
}

var (
	clients   = make(map[string]*Client)
	clientsMu sync.Mutex
	timeout   = 10 * time.Second
	udpConn   *net.UDPConn
)

func main() {
	portStr := "22336"
	if len(os.Args) > 1 {
		portStr = os.Args[1]
	}

	// Background cleanup routine to prune inactive clients
	go func() {
		for {
			time.Sleep(5 * time.Second)
			clientsMu.Lock()
			now := time.Now()
			for key, client := range clients {
				if now.Sub(client.LastSeen) > timeout {
					fmt.Printf("[Server] Client timed out: %s (%s)\n", client.Username, key)
					if client.Conn != nil {
						client.Conn.Close()
					}
					delete(clients, key)
				}
			}
			clientsMu.Unlock()
		}
	}()

	// Start UDP Server in goroutine
	go startUDPServer(portStr)

	// Start TCP Server in main thread
	startTCPServer(portStr)
}

func startUDPServer(portStr string) {
	addr, err := net.ResolveUDPAddr("udp", ":"+portStr)
	if err != nil {
		fmt.Printf("Error resolving UDP address: %v\n", err)
		return
	}

	pc, err := net.ListenUDP("udp", addr)
	if err != nil {
		fmt.Printf("Error starting UDP server on port %s: %v\n", portStr, err)
		return
	}
	udpConn = pc
	defer pc.Close()

	fmt.Printf("[Server] UDP Co-op Server listening on port %s...\n", portStr)
	buffer := make([]byte, 4096)
	for {
		n, addr, err := pc.ReadFrom(buffer)
		if err != nil {
			fmt.Printf("[UDP Server] Read error: %v\n", err)
			continue
		}

		payload := buffer[:n]
		addrStr := addr.String()

		// Attempt to parse username for logging purposes
		var pkt Packet
		var username = "unknown"
		if err := json.Unmarshal(payload, &pkt); err == nil && pkt.Username != "" {
			username = pkt.Username
		}

		// If it's a ping request, echo it back immediately
		var isPingRequest bool
		var pingMap map[string]interface{}
		if err := json.Unmarshal(payload, &pingMap); err == nil {
			if pVal, ok := pingMap["ping"]; ok {
				if bVal, ok := pVal.(bool); ok && bVal {
					if rVal, ok := pingMap["reply"]; ok {
						if bReply, ok := rVal.(bool); ok && !bReply {
							isPingRequest = true
						}
					}
				}
			}
		}

		if isPingRequest {
			pingMap["reply"] = true
			replyPayload, err := json.Marshal(pingMap)
			if err == nil {
				_, _ = pc.WriteTo(replyPayload, addr)
			} else {
				_, _ = pc.WriteTo(payload, addr)
			}
			continue
		}

		clientsMu.Lock()
		client, exists := clients[addrStr]
		if !exists {
			fmt.Printf("[Server] New connection from %s (%s) [UDP]\n", username, addrStr)
			client = &Client{
				Addr: addr.(*net.UDPAddr),
			}
			clients[addrStr] = client
		}
		client.LastSeen = time.Now()
		client.Username = username

		// Broadcast raw packet to all other registered clients
		broadcastPacket(payload, addrStr)
		clientsMu.Unlock()
	}
}

func startTCPServer(portStr string) {
	listener, err := net.Listen("tcp", ":"+portStr)
	if err != nil {
		fmt.Printf("Error starting TCP server on port %s: %v\n", portStr, err)
		return
	}
	defer listener.Close()

	fmt.Printf("[Server] TCP Co-op Server listening on port %s...\n", portStr)

	for {
		conn, err := listener.Accept()
		if err != nil {
			fmt.Printf("[TCP Server] Accept error: %v\n", err)
			continue
		}
		if tcpConn, ok := conn.(*net.TCPConn); ok {
			_ = tcpConn.SetNoDelay(true)
		}

		go handleTCPClient(conn)
	}
}

func handleTCPClient(conn net.Conn) {
	addrStr := conn.RemoteAddr().String()

	clientsMu.Lock()
	client := &Client{
		Conn:     conn,
		LastSeen: time.Now(),
		Username: "unknown",
	}
	clients[addrStr] = client
	fmt.Printf("[Server] New connection from %s [TCP]\n", addrStr)
	clientsMu.Unlock()

	defer func() {
		conn.Close()
		clientsMu.Lock()
		delete(clients, addrStr)
		fmt.Printf("[Server] Connection closed for %s (%s) [TCP]\n", client.Username, addrStr)
		clientsMu.Unlock()
	}()

	reader := bufio.NewReader(conn)
	for {
		line, err := reader.ReadBytes('\n')
		if err != nil {
			break
		}

		clientsMu.Lock()
		client.LastSeen = time.Now()

		var pkt Packet
		if err := json.Unmarshal(line, &pkt); err == nil && pkt.Username != "" {
			if client.Username == "unknown" {
				fmt.Printf("[Server] TCP Client %s registered username: %s\n", addrStr, pkt.Username)
			}
			client.Username = pkt.Username
		}

		// If it's a ping request, echo it back immediately
		var isPingRequest bool
		var pingMap map[string]interface{}
		if err := json.Unmarshal(line, &pingMap); err == nil {
			if pVal, ok := pingMap["ping"]; ok {
				if bVal, ok := pVal.(bool); ok && bVal {
					if rVal, ok := pingMap["reply"]; ok {
						if bReply, ok := rVal.(bool); ok && !bReply {
							isPingRequest = true
						}
					}
				}
			}
		}

		if isPingRequest {
			pingMap["reply"] = true
			replyPayload, err := json.Marshal(pingMap)
			if err == nil {
				_, _ = conn.Write(append(replyPayload, '\n'))
			} else {
				_, _ = conn.Write(line)
			}
			clientsMu.Unlock()
			continue
		}

		broadcastPacket(line, addrStr)
		clientsMu.Unlock()
	}
}

func broadcastPacket(payload []byte, senderAddrStr string) {
	// Normalize payload by removing any trailing newline
	var cleanPayload []byte
	if len(payload) > 0 && payload[len(payload)-1] == '\n' {
		cleanPayload = payload[:len(payload)-1]
	} else {
		cleanPayload = payload
	}

	for key, otherClient := range clients {
		if key != senderAddrStr {
			if otherClient.Conn != nil {
				// Send to TCP client (with newline)
				_, _ = otherClient.Conn.Write(append(cleanPayload, '\n'))
			} else if otherClient.Addr != nil && udpConn != nil {
				// Send to UDP client
				_, _ = udpConn.WriteTo(cleanPayload, otherClient.Addr)
			}
		}
	}
}
