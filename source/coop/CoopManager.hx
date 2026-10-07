package coop;

import main.ChapterState;
import flixel.FlxG;
import flixel.util.FlxColor;
import main.Multiplayer.UdpClient;
import main.Multiplayer.Multiplayer;
#if !html5 import coop.NATUPnP; #end

class CoopManager
{
    public var udpClient:UdpClient;
    public var remotePlayers:Map<String, main.RemotePlayer> = new Map();

    public var networkTimer:Float = 0;
    public var tickRate:Float = 0.05;
    public var pingTimer:Float = 0;
    public var testingUDP:Bool = false;
    public var udpTestTimer:Float = 0;
    public var udpReceivedResponse:Bool = false;
    public var teleportCooldownTimer:Float = 0;

    public function new() {}

    public function init():Void
    {
        #if (!html5 && !mobile)
        Multiplayer.usingTCP = false;

        var clientAddr = UdpClient.getClientAddress();
        if (clientAddr != null)
        {
            trace("Multiplayer client active: " + clientAddr.host + ":" + clientAddr.port + " (bound to local port " + clientAddr.localPort + ")");
            NATUPnP.mapPortAsync(clientAddr.localPort);
        }
        else if (Multiplayer.activeMode == Local)
        {
            var host = Multiplayer.targetIP;
            var port = Multiplayer.targetPort;
            udpClient = new UdpClient(host, port, port);
            trace("Multiplayer client active (via Local Coop): " + host + ":" + port + " (bound to local port " + port + ")");
            NATUPnP.mapPortAsync(port);
        }
        else if (Multiplayer.activeMode == Server)
        {
            var host = Multiplayer.targetIP;
            var port = Multiplayer.targetPort;
            udpClient = new UdpClient(host, port, 0, false);
            testingUDP = true;
            udpTestTimer = 0;
            udpReceivedResponse = false;
            trace("Multiplayer client active (via Server Coop): " + host + ":" + port + " (testing UDP connectivity...)");
        }
        else
        {
            udpClient = null;
            trace("Multiplayer client inactive");
        }
        #end
    }

    public function update(state:ChapterState, elapsed:Float):Void
    {
        if (teleportCooldownTimer > 0) teleportCooldownTimer -= elapsed;

        #if (!mobile && !html5)
        // --- TELEPORT LOGIC ---
        if (FlxG.keys.justPressed.F && udpClient != null && state.player != null && state.player.alive)
        {
            if (teleportCooldownTimer <= 0)
            {
                FlxG.sound.play("assets/sounds/error.ogg", 0.65, false); // Update path if needed
                FlxG.camera.shake(0.01, 0.15);
                return;
            }
            var nearestPlayer:main.RemotePlayer = null;
            var minDistance:Float = 999999;
            for (rPlayer in remotePlayers)
            {
                if (rPlayer != null && rPlayer.exists && rPlayer.visible)
                {
                    var dx = rPlayer.x - state.player.x;
                    var dy = rPlayer.y - state.player.y;
                    var dist = Math.sqrt(dx * dx + dy * dy);
                    if (dist < minDistance)
                    {
                        minDistance = dist;
                        nearestPlayer = rPlayer;
                    }
                }
            }

            if (nearestPlayer != null)
            {
                teleportCooldownTimer = 2.0;
                state.player.x = nearestPlayer.x;
                state.player.y = nearestPlayer.y;

                var emitter = new flixel.effects.particles.FlxEmitter(state.player.x + (state.player.width / 2), state.player.y + (state.player.height / 2), 20);
                emitter.makeParticles(3, 3, FlxColor.WHITE, 20);
                emitter.color.set(FlxColor.RED, FlxColor.YELLOW, FlxColor.BLUE, FlxColor.LIME);
                emitter.lifespan.set(0.4, 0.8);
                emitter.speed.set(50, 150);
                emitter.launchMode = CIRCLE;
                state.add(emitter);
                emitter.start(true, 0, 20);

                FlxG.sound.play("assets/sounds/warp.ogg", 0.6, false); // Update path if needed
                trace("Teleported to remote player: " + nearestPlayer.username);
            }
        }

        // --- NETWORK SYNC LOGIC ---
        if (udpClient != null)
        {
            if (testingUDP)
            {
                udpTestTimer += elapsed;
                
                if (Math.floor(udpTestTimer / 0.3) > Math.floor((udpTestTimer - elapsed) / 0.3))
                {
                    var payload = '{"ping":true,"reply":false,"time":' + haxe.Timer.stamp() + '}';
                    udpClient.send(payload);
                }
                
                if (udpTestTimer >= 1.5)
                {
                    testingUDP = false;
                    trace("[Multiplayer] UDP test timed out. Falling back to TCP...");
                    udpClient.close();
                    
                    var host = Multiplayer.targetIP;
                    var port = Multiplayer.targetPort;
                    udpClient = new UdpClient(host, port, 0, true);
                    Multiplayer.usingTCP = true;
                }
            }

            pingTimer += elapsed;
            if (pingTimer >= 2.0)
            {
                pingTimer = 0;
                var payload = '{"ping":true,"reply":false,"time":' + haxe.Timer.stamp() + '}';
                udpClient.send(payload);
            }

            if (state.player != null && state.player.alive)
            {
                networkTimer += elapsed;
                if (networkTimer >= tickRate)
                {
                    networkTimer = 0;
                    var currentAnim = (state.player.animation.curAnim != null ? state.player.animation.curAnim.name : "idle");
                    var userStr = (Multiplayer.activeMode == Server) ? Multiplayer.username : "peer";
                    var payload:String = '{"x":' + state.player.x + ',"y":' + state.player.y + ',"flip":' + state.player.isFlipped + ',"facingRight":' + main.Player.isFacingRIGHT
                        + ',"skin":"' + main.PlayerData.currentSkin + '","anim":"' + currentAnim + '","currentRoom":"' + state.currentRoomName + '","username":"' + userStr + '"}';
                    udpClient.send(payload);
                }
            }

            var packet:String = null;
            while ((packet = udpClient.receive()) != null)
            {
                if (testingUDP)
                {
                    testingUDP = false;
                    udpReceivedResponse = true;
                    trace("[Multiplayer] UDP connection verified! Using UDP mode.");
                }
                try
                {
                    var data = haxe.Json.parse(packet);

                    if (data.ping == true)
                    {
                        var timeVal:Float = cast data.time;
                        if (data.reply == false)
                        {
                            var replyPayload = '{"ping":true,"reply":true,"time":' + timeVal + '}';
                            udpClient.send(replyPayload);
                        }
                        else
                        {
                            var rtt = haxe.Timer.stamp() - timeVal;
                            Multiplayer.currentPing = rtt * 1000;
                            trace("Current Ping: " + Multiplayer.currentPing + "ms");
                        }
                        continue;
                    }
                    
                    if (Multiplayer.activeMode == Server && data.username != null && data.username == Multiplayer.username) continue;

                    var peerKey = (Multiplayer.activeMode == Server) ? data.username : "peer";
                    if (peerKey == null || peerKey == "") peerKey = "peer";

                    if (data.death == true)
                    {
                        var dRoomStr:String = data.currentRoom != null ? cast data.currentRoom : "";
                        var cRoomStr:String = state.currentRoomName != null ? cast state.currentRoomName : "";
                        var isBossDeathMatch = (dRoomStr != "" && cRoomStr != "" && StringTools.startsWith(dRoomStr, "boss-")
                        && StringTools.startsWith(cRoomStr, "boss-") && dRoomStr.split("-")[1] == cRoomStr.split("-")[1]);
                        
                        if (data.currentRoom == null || data.currentRoom == state.currentRoomName || isBossDeathMatch) 
                        {
                            var rPlayer = remotePlayers.get(peerKey);
                            var spawnX = (data.x != null) ? data.x : (rPlayer != null ? rPlayer.x : 0);
                            var spawnY = (data.y != null) ? data.y : (rPlayer != null ? rPlayer.y : 0);
                            FlxG.sound.play("assets/sounds/kill_sound_effect.ogg", 0.75, false); // Update path if needed
                            state.bloodParticles(spawnX, spawnY);
                            if (rPlayer != null)
                            {
                                rPlayer.visible = false;
                                rPlayer.exists = false;
                                if (rPlayer.usernameText != null) rPlayer.usernameText.visible = false;
                            }
                        }
                    }
                    else if (data.x != null && data.y != null)
                    {
                        var rPlayer = remotePlayers.get(peerKey);
                        if (rPlayer == null)
                        {
                            rPlayer = new main.RemotePlayer(data.x, data.y, peerKey);
                            remotePlayers.set(peerKey, rPlayer);
                            state.add(rPlayer);
                            state.add(rPlayer.usernameText);
                        }
                        rPlayer.exists = true;
                        rPlayer.visible = true;
                        rPlayer.loadSkin(data.skin != null ? data.skin : "thekid");
                        rPlayer.applyNetworkPacket(data.x, data.y, data.flip == true, data.facingRight == true, data.anim, data.currentRoom != null ? data.currentRoom : "");
                    }
                }
                catch (e:Dynamic)
                {
                    trace("Error al procesar el paquete recibido: " + e);
                }
            }

            var inactiveKeys:Array<String> = [];
            for (key in remotePlayers.keys())
            {
                var rPlayer = remotePlayers.get(key);
                if (rPlayer != null && rPlayer.timeSincePacket >= 10.0)
                {
                    inactiveKeys.push(key);
                }
            }
            for (key in inactiveKeys)
            {
                var rPlayer = remotePlayers.get(key);
                if (rPlayer != null)
                {
                    FlxG.sound.play("assets/sounds/kill_sound_effect.ogg", 0.75, false);
                    state.bloodParticles(rPlayer.x, rPlayer.y);
                    state.remove(rPlayer.usernameText);
                    state.remove(rPlayer);
                    rPlayer.destroy();
                    remotePlayers.remove(key);
                }
            }
        }
        #end
    }

    public function sendDeathPacket(state:ChapterState):Void
    {
        if (udpClient != null) {
            var userStr = (Multiplayer.activeMode == Server) ? Multiplayer.username : "peer";
            var payload:String = '{"death": true, "x": ' + state.player.x + ', "y": ' + state.player.y + ', "currentRoom": "' + state.currentRoomName + '","username":"' + userStr + '"}';
            udpClient.send(payload);
        }
    }

    public function destroy(state:ChapterState):Void
    {
        if (udpClient != null)
        {
            udpClient.close();
            udpClient = null;
        }
        for (rPlayer in remotePlayers) {
            if (rPlayer != null) {
                state.remove(rPlayer.usernameText);
                rPlayer.destroy();
            }
        }
        remotePlayers.clear();
    }
}