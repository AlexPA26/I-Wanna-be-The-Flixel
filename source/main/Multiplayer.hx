package main;

import sys.net.Host;
import sys.net.UdpSocket;
import sys.net.Address;
import haxe.io.Bytes;

enum CoopMode {
    None;
    Local;
    Server;
}

class Multiplayer {
    public static var activeMode:CoopMode = None;
    
    public static var targetIP:String = "127.0.0.1";
    public static var targetPort:Int = 22336;
    
    public static var username:String = "Player";
    public static var currentPing:Float = 0;
    public static var usingTCP:Bool = false;
}

#if sys
class UdpClient {
    private var isTCP:Bool = false;
    private var socket:UdpSocket;
    private var tcpSocket:sys.net.Socket;
    private var port:Int;
    private var host:Host;
    
    private var tcpInputBuffer:String = "";
    
    public function new(hostStr:String, port:Int, localPort:Int, useTCP:Bool = false) {
        this.isTCP = useTCP;
        this.host = new Host(hostStr);
        this.port = port;
        
        if (isTCP) {
            this.tcpSocket = new sys.net.Socket();
            try {
                this.tcpSocket.connect(this.host, this.port);
                this.tcpSocket.setBlocking(false);
                this.tcpSocket.setFastSend(true);
                trace("[TCP] Connected successfully to " + hostStr + ":" + port);
            } catch (e:Dynamic) {
                trace("[TCP] Failed to connect: " + e);
            }
        } else {
            this.socket = new UdpSocket();
            try {
                this.socket.bind(new Host("0.0.0.0"), localPort);
            } catch (e:Dynamic) {
                trace("No se pudo enlazar al puerto local " + localPort + ", usando puerto efímero. Detalle: " + e);
                this.socket.bind(new Host("0.0.0.0"), 0);
            }
            this.socket.setBroadcast(false);
            this.socket.setBlocking(false);
        }
    }

    public function send(data:String):Void {
        if (isTCP) {
            if (tcpSocket != null) {
                try {
                    tcpSocket.write(data + "\n");
                } catch (e:Dynamic) {
                    trace("[TCP] Error sending: " + e);
                }
            }
        } else {
            var bytes = Bytes.ofString(data);
            var addr = new Address();
            addr.host = this.host.ip;
            addr.port = this.port;
            try {
                this.socket.sendTo(bytes, 0, bytes.length, addr);
            } catch (e:Dynamic) {
                trace("Error al enviar UDP: " + e);
            }
        }
    }

    public function receive():String {
        if (isTCP) {
            if (tcpSocket == null) return null;
            
            // Read lines from the non-blocking TCP stream
            try {
                var buffer = Bytes.alloc(2048);
                var bytesRead = tcpSocket.input.readBytes(buffer, 0, buffer.length);
                if (bytesRead > 0) {
                    tcpInputBuffer += buffer.sub(0, bytesRead).toString();
                }
            } catch (e:haxe.io.Error) {
                // Blocked is expected when no data is available
            } catch (e:haxe.io.Eof) {
                trace("[TCP] Server disconnected (EOF)");
                tcpSocket.close();
                tcpSocket = null;
            } catch (e:Dynamic) {
                trace("[TCP] Receive error: " + e);
            }
            
            var newlineIndex = tcpInputBuffer.indexOf("\n");
            if (newlineIndex >= 0) {
                var line = tcpInputBuffer.substring(0, newlineIndex);
                tcpInputBuffer = tcpInputBuffer.substring(newlineIndex + 1);
                return line;
            }
            return null;
        } else {
            var buffer = Bytes.alloc(4096);
            var senderAddress = new Address();
            try {
                var bytesRead = this.socket.readFrom(buffer, 0, buffer.length, senderAddress);
                if (bytesRead > 0) {
                    return buffer.sub(0, bytesRead).toString();
                }
            } catch (e:haxe.io.Error) {
                // En modo no-bloqueante, si no hay datos, lanza haxe.io.Error.Blocked
            } catch (e:Dynamic) {
                trace("Error al recibir UDP: " + e);
            }
            return null;
        }
    }

    public function close():Void {
        if (isTCP) {
            if (tcpSocket != null) {
                tcpSocket.close();
                tcpSocket = null;
            }
        } else {
            if (socket != null) {
                this.socket.close();
            }
        }
    }

    public static function getClientAddress():Null<{host:String, port:Int, localPort:Int}> {
        #if sys
        var args = Sys.args();
        for (i in 0...args.length) {
            if (args[i] == "-client" && i + 1 < args.length) {
                var addrStr = args[i + 1];
                var parts = addrStr.split(":");
                if (parts.length == 2) {
                    var host = parts[0];
                    var port = Std.parseInt(parts[1]);
                    if (port != null) {
                        return {host: host, port: port, localPort: port};
                    }
                } else if (parts.length == 3) {
                    var host = parts[0];
                    var port = Std.parseInt(parts[1]);
                    var localPort = Std.parseInt(parts[2]);
                    if (port != null && localPort != null) {
                        return {host: host, port: port, localPort: localPort};
                    }
                }
            }
        }
        #end
        return null;
    }
}
#else
class UdpClient {
    public function new(hostStr:String, port:Int, localPort:Int, useTCP:Bool = false) {}
    public function send(data:String):Void {}
    public function receive():String { return null; }
    public function close():Void {}
    public static function getClientAddress():Null<{host:String, port:Int, localPort:Int}> { return null; }
}
#end