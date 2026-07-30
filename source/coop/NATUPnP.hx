package coop;

import haxe.Http;
import sys.net.Host;
import sys.net.UdpSocket;
import sys.net.Address;
import sys.thread.Thread;

class NATUPnP {
	public static function mapPortAsync(port:Int):Void {
		Thread.create(function() {
			try {
				trace("[UPnP] Starting port mapping for port " + port + "...");
				var localIP = getLocalIP();
				trace("[UPnP] Local IP resolved to: " + localIP);
				if (localIP == "127.0.0.1") return;

				var location = discoverGateway();
				if (location == null) {
					trace("[UPnP] No UPnP Gateway found via SSDP.");
					return;
				}
				trace("[UPnP] Gateway found at: " + location);

				var serviceInfo = getControlURL(location);
				if (serviceInfo == null) {
					trace("[UPnP] Could not find WANIPConnection or WANPPPConnection service.");
					return;
				}

				var controlURL = serviceInfo.controlURL;
				var serviceType = serviceInfo.serviceType;
				trace("[UPnP] Control URL: " + controlURL + " (Type: " + serviceType + ")");

				// Map UDP
				var successUDP = sendAddPortMapping(controlURL, serviceType, port, "UDP", localIP);
				trace("[UPnP] UDP Port mapping status: " + (successUDP ? "SUCCESS" : "FAILED"));

				// Map TCP
				var successTCP = sendAddPortMapping(controlURL, serviceType, port, "TCP", localIP);
				trace("[UPnP] TCP Port mapping status: " + (successTCP ? "SUCCESS" : "FAILED"));
			} catch (e:Dynamic) {
				trace("[UPnP] Error during mapping: " + e);
			}
		});
	}

	static function getLocalIP():String {
		try {
			var socket = new UdpSocket();
			socket.connect(new Host("8.8.8.8"), 53);
			var local = socket.host();
			socket.close();
			return local.host.toString();
		} catch (e:Dynamic) {
			return "127.0.0.1";
		}
	}

	static function discoverGateway():String {
		try {
			var socket = new UdpSocket();
			socket.bind(new Host("0.0.0.0"), 0);
			socket.setBlocking(false);

			var requestStr = "M-SEARCH * HTTP/1.1\r\n" +
				"HOST: 239.255.255.250:1900\r\n" +
				"MAN: \"ssdp:discover\"\r\n" +
				"MX: 2\r\n" +
				"ST: urn:schemas-upnp-org:device:InternetGatewayDevice:1\r\n\r\n";

			var requestBytes = haxe.io.Bytes.ofString(requestStr);
			var targetAddr = new Address();
			targetAddr.host = new Host("239.255.255.250").ip;
			targetAddr.port = 1900;
			socket.sendTo(requestBytes, 0, requestBytes.length, targetAddr);

			var start = haxe.Timer.stamp();
			var buffer = haxe.io.Bytes.alloc(2048);
			var srcAddr = new Address();
			while (haxe.Timer.stamp() - start < 2.0) {
				try {
					var bytesRead = socket.readFrom(buffer, 0, buffer.length, srcAddr);
					var response = buffer.getString(0, bytesRead);
					var lines = response.split("\r\n");
					for (line in lines) {
						if (StringTools.startsWith(line.toUpperCase(), "LOCATION:")) {
							var loc = StringTools.trim(line.substring(9));
							socket.close();
							return loc;
						}
					}
				} catch (e:Dynamic) {
					// Socket block/no data
				}
				Sys.sleep(0.1);
			}
			socket.close();
		} catch (e:Dynamic) {
			trace("[UPnP] SSDP discovery error: " + e);
		}
		return null;
	}

	static function getControlURL(location:String):{controlURL:String, serviceType:String} {
		try {
			var http = new Http(location);
			var responseXML:String = "";
			http.onData = function(data) {
				responseXML = data;
			};
			http.request(false);

			if (responseXML == "") return null;

			var xml = Xml.parse(responseXML);
			var foundService:Xml = findServiceNode(xml);
			if (foundService != null) {
				var serviceType = "";
				var controlURL = "";
				for (child in foundService.elements()) {
					if (child.nodeName == "serviceType") serviceType = child.firstChild().nodeValue;
					if (child.nodeName == "controlURL") controlURL = child.firstChild().nodeValue;
				}

				// Resolve relative URL
				if (!StringTools.startsWith(controlURL, "http")) {
					var base = "";
					var parts = location.split("/");
					base = parts[0] + "//" + parts[2];
					if (StringTools.startsWith(controlURL, "/")) {
						controlURL = base + controlURL;
					} else {
						controlURL = base + "/" + controlURL;
					}
				}
				return {controlURL: controlURL, serviceType: serviceType};
			}
		} catch (e:Dynamic) {
			trace("[UPnP] XML parse error: " + e);
		}
		return null;
	}

	static function findServiceNode(node:Xml):Xml {
		if (node.nodeType == Xml.Element && node.nodeName == "service") {
			var isTarget = false;
			for (child in node.elements()) {
				if (child.nodeName == "serviceType" && 
					(child.firstChild().nodeValue.indexOf("WANIPConnection:") >= 0 || 
					 child.firstChild().nodeValue.indexOf("WANPPPConnection:") >= 0)) {
					isTarget = true;
				}
			}
			if (isTarget) return node;
		}
		for (child in node) {
			var found = findServiceNode(child);
			if (found != null) return found;
		}
		return null;
	}

	static function sendAddPortMapping(controlURL:String, serviceType:String, port:Int, protocol:String, localIP:String):Bool {
		try {
			var http = new Http(controlURL);
			var soapAction = serviceType + "#AddPortMapping";
			http.addHeader("SOAPAction", '"' + soapAction + '"');
			http.addHeader("Content-Type", "text/xml; charset=\"utf-8\"");

			var xmlBody = '<?xml version="1.0" ?>' +
				'<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">' +
				'<s:Body>' +
				'<u:AddPortMapping xmlns:u="' + serviceType + '">' +
				'<NewRemoteHost></NewRemoteHost>' +
				'<NewExternalPort>' + port + '</NewExternalPort>' +
				'<NewProtocol>' + protocol + '</NewProtocol>' +
				'<NewInternalPort>' + port + '</NewInternalPort>' +
				'<NewInternalClient>' + localIP + '</NewInternalClient>' +
				'<NewEnabled>1</NewEnabled>' +
				'<NewPortMappingDescription>I Wanna Be The Flixel Co-op</NewPortMappingDescription>' +
				'<NewLeaseDuration>0</NewLeaseDuration>' +
				'</u:AddPortMapping>' +
				'</s:Body>' +
				'</s:Envelope>';

			http.setPostData(xmlBody);
			var success = false;
			http.onStatus = function(status) {
				if (status == 200) success = true;
			};
			http.request(true);
			return success;
		} catch (e:Dynamic) {
			trace("[UPnP] SOAP request error: " + e);
			return false;
		}
	}
}
