package main;

import flixel.util.FlxTimer;
import character.KrisDeathState;
import shaders.*;
import main.Multiplayer.UdpClient;
import main.Multiplayer.Multiplayer;
import main.Multiplayer.CoopMode;
import coop.NATUPnP;
import coop.LocalCoopSubstate.LocalCoopSubState;
import flixel.sound.FlxSound;
import openfl.media.Sound;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.editors.tiled.*;
import flixel.addons.editors.tiled.TiledLayer;
import flixel.effects.particles.FlxEmitter;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxVirtualPad;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;
import gui.DeathState;
import leveldata.background.*;
import leveldata.blockdata.*;
import leveldata.deco.*;
import leveldata.events.*;
import leveldata.hazards.*;
import leveldata.misc.*;
import leveldata.collectibles.*;
import flixel.addons.effects.FlxTrail;
import main.mods.ModLoader;
import flixel.ui.FlxBar;

@:allow(main.RoomLoader)
@:allow(leveldata.events.EventLoader)
@:allow(main.bosses.ch1)
class ChapterState extends FlxState
{
	var player:Player;
	var currentDeaths = PlayerData.totalDeaths;
	var blood:flixel.effects.particles.FlxEmitter;
	var cameraSnapTimer:Int = 1;
	var playerTrail:FlxTrail;
	var virtualPad:FlxVirtualPad;
	var padScale:Float = 2.5;
	var targetAlpha:Float = 0.5;
	var hudGroup:FlxGroup;
	var bullets:FlxTypedGroup<FlxSprite>;
	var playerGlow:FlxSprite;
	var cameraTarget:FlxObject;
	var cameraOffsetY:Float = -225;
	var scrollSpeed:Float = 0;
	var scrollOffsetX:Float = 0;
	var isAutoscrolling:Bool = false;
	var autoscrollType:String = "none";
	var fightingBoss:Bool;

	public var currentBossName:String = "";
	public var currentBoss:FlxSprite = null;
	public var krisDeathAlt:Bool;
	public var cameraType:String = "normal";
	public var isPaused:Bool = false;

	public var bg:FlxSprite;


	public var rainShader:RainShader;
	public var sunsetShader:SunsetRayShader;
	public var circusShader:JevilCircusBG;
	public var rainbowShader:RainbowCrazy;
	public var castleInsideShader:CastleInside;
	public var castleShader:CastleIndoors;
	public var toxicShader:ToxicShader;

	public var screenShader:flixel.system.FlxAssets.FlxShader;
	public var screenShaderName:String;




	public var currentBGName:String = "";
	public var mainTilesPath:String = "assets/images/levels/tiles/ch" + PlayerData.currentChapter + "tiles.png";
	public var currentConfig:ChapterConfig;

	var map:FlxTilemap;
	var mapDeco:FlxTilemap;
	var mapDeco2:FlxTilemap;

	public var tilemapLayers:Map<String, FlxTilemap> = new Map();
	public var tilemapGroup:flixel.group.FlxGroup;

	public var currentRoomName:String;
	public var warpsGroup:FlxTypedGroup<WarpTrigger>;

	public var backEffectObj:FlxBackdrop;
	public var currentBackEffectName:String = "";
	public var lastBackScrollBoost:Float = 0;

	public var backDecoEffectObj:FlxBackdrop;
	public var currentBackDecoEffectName:String = "";
	public var lastDecoScrollBoost:Float = 0;

	public var doubleEffectObj:FlxBackdrop;
	public var currentDoubleEffectName:String = "";
	public var lastDoubleScrollBoost:Float = 0;

	public var frontEffectObj:FlxBackdrop;
	public var currentFrontEffectName:String = "";
	public var lastFrontScrollBoost:Float = 0;

	public var topEffectObj:FlxBackdrop;
	public var currentTopEffectName:String = "";
	public var lastTopScrollBoost:Float = 0;

	public var roomImages:FlxTypedGroup<FlxSprite>;
	public var eventEffectGroup:FlxGroup;
	public var savesGroup:FlxTypedGroup<SavePoint>;
	public var popups:FlxTypedGroup<FlxText>;
	public var saveParticlesGroup:FlxTypedGroup<FlxEmitter>;
	public var redCoinParticlesGroup:FlxTypedGroup<FlxEmitter>;
	public var redCoinsGroup:FlxTypedGroup<RedCoin>;
	public var doubleJumpGroup:FlxTypedGroup<DoubleJumpObj>;
	public var flipGroup:FlxTypedGroup<FlipSwitch>;
	public var portalGroup:FlxTypedGroup<PortalWarp>;
	public var roomAcid:AcidFluid = null;
	public var waterDeco:WaterDeco = null;
	public var trampolines:FlxTypedGroup<NormalTrampoline>;
	public var trampolinesMini:FlxTypedGroup<NormalTrampolineMini>;
	public var platforms:FlxTypedGroup<MovingBlock>;
	public var fallingBlock:FlxTypedGroup<FallingBlock>;
	public var lightsGroup:FlxTypedGroup<LightTorch>;
	public var dangerObjects:FlxGroup;
	public var slabs:FlxTypedGroup<NormalSlab>;
	public var solidBlock:FlxTypedGroup<SolidBlock>;

	public var hud:FlxGroup;

	var spikes:FlxGroup;
	var whiteFade:FlxSprite;
	var blackFade:FlxSprite;
	var tiledData:TiledMap;
	var spawnTimer:Float = 0.1;
	var inmortal:Bool = false;
	var timeElapsed:FlxText;
	var currentChapter:FlxText;
	var playerDeaths:FlxText;
	var lastSave:FlxText;
	var bossHpBar:FlxBar;
    var bossDebugText:FlxText;
	public var jevil:main.bosses.ch1.BossJevil.Jevil;
	public var reznor:main.bosses.ch1.BossReznor.Reznor;

	var udpClient:UdpClient;

	public var remotePlayers:Map<String, main.RemotePlayer> = new Map();

	var networkTimer:Float = 0;
	var tickRate:Float = 0.05; // 20 ticks per second
	var pingTimer:Float = 0;
	var testingUDP:Bool = false;
	var udpTestTimer:Float = 0;
	var udpReceivedResponse:Bool = false;

	static var loopPoints:Map<String, Float> = null;

	override public function create():Void
	{
		Multiplayer.usingTCP = false;
		#if !debug
		#if !mobile
		FlxG.mouse.visible = false;
		#end
		#end

		#if debug
		#if !mobile
		FlxG.mouse.visible = true;
		#end
		#end

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
			// Start with UDP to check if NAT is open
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

		hudGroup = new FlxGroup();
		virtualPad = new FlxVirtualPad(LEFT_RIGHT, A);

		FlxG.bitmap.clearUnused();
		imgCache();
		sfxCache();

		roomImages = new FlxTypedGroup();
		dangerObjects = new FlxGroup();
		savesGroup = new FlxTypedGroup<SavePoint>();
		popups = new FlxTypedGroup<FlxText>();
		saveParticlesGroup = new FlxTypedGroup<FlxEmitter>();
		redCoinsGroup = new FlxTypedGroup<RedCoin>();
		redCoinParticlesGroup = new FlxTypedGroup<FlxEmitter>();
		doubleJumpGroup = new FlxTypedGroup<DoubleJumpObj>();
		eventEffectGroup = new FlxTypedGroup();
		flipGroup = new FlxTypedGroup<FlipSwitch>();
		portalGroup = new FlxTypedGroup<PortalWarp>();
		trampolines = new FlxTypedGroup<NormalTrampoline>();
		trampolinesMini = new FlxTypedGroup<NormalTrampolineMini>();
		platforms = new FlxTypedGroup<MovingBlock>();
		fallingBlock = new FlxTypedGroup<FallingBlock>();
		lightsGroup = new FlxTypedGroup<LightTorch>();
		slabs = new FlxTypedGroup<NormalSlab>();
		solidBlock = new FlxTypedGroup<SolidBlock>();
		bullets = new FlxTypedGroup<FlxSprite>();

		hud = new FlxGroup();

		playerGlow = new FlxSprite();
		playerGlow.loadGraphic(AssetPaths.playerGlow__png, false);
		playerGlow.blend = flash.display.BlendMode.ADD;
		playerGlow.alpha = 0.15;

		warpsGroup = new FlxTypedGroup<WarpTrigger>();
		add(warpsGroup);
		player = new Player(PlayerData.spawnX, PlayerData.spawnY);
		playerTrail = new FlxTrail(player, null, 24, 0, 0.2, 0.02);
		playerTrail.alpha = 0;

		whiteFade = new FlxSprite();
		whiteFade.makeGraphic(FlxG.width + 1, FlxG.height, FlxColor.WHITE, false);
		whiteFade.alpha = 0;
		whiteFade.scrollFactor.set(0, 0);

		blackFade = new FlxSprite();
		blackFade.makeGraphic(FlxG.width + 1, FlxG.height, FlxColor.BLACK, false);
		blackFade.alpha = 0;
		blackFade.scrollFactor.set(0, 0);

		RoomLoader.loadRoom(this, PlayerData.currentRoom);

		switch (PlayerData.currentChapter)
		{
			case 1:
				chapter1Cache();
			case 2:
				currentConfig = new ChapterConfig(2, "");
			default:
				currentConfig = new ChapterConfig(0, "");
		}

		// currentConfig.cacheAssets();
		// FlxG.stage.addEventListener(openfl.events.Event.DEACTIVATE, onFocusLost);

		super.create();
	}

	override public function update(elapsed:Float):Void
	{

		if (isAutoscrolling && cameraTarget != null)
		{
			if (autoscrollType == "scrollX")
			{
				cameraTarget.y = player.y;
			}
			else if (autoscrollType == "scrollY")
			{
				cameraTarget.x = (map.x + (map.width / 2)) + scrollOffsetX;
			}

			var limitOffset = 100;
			if (player.x + player.width < FlxG.camera.scroll.x - limitOffset || 
				player.x > FlxG.camera.scroll.x + FlxG.width + limitOffset ||
				player.y + player.height < FlxG.camera.scroll.y - limitOffset || 
				player.y > FlxG.camera.scroll.y + FlxG.height + limitOffset)
			{
				killPlayer();
			}
		}
		else if (!isAutoscrolling && cameraTarget != null)
		{
			#if !debug
			if (cameraType == "unlockX")
			{
				cameraTarget.x = player.x;
				cameraTarget.y = map.y;
			}
			else if (cameraType == "unlockY")
			{
				cameraTarget.x = map.x + (map.width / 2);
				var targetOffset:Float = (player.velocity.y > 50) ? 0 : -225;
				
				cameraOffsetY += (targetOffset - cameraOffsetY) * 5.0 * FlxG.elapsed;

				cameraTarget.y = player.y + cameraOffsetY;
			}
			else if (cameraType == "unlockXY")
			{
				cameraTarget.x = player.x;
				cameraTarget.y = player.y;
			}
			#end
		}

		#if !mobile
		if (FlxG.keys.justPressed.F11 || FlxG.keys.pressed.ALT && FlxG.keys.justPressed.ENTER)
		{
			if (FlxG.fullscreen == false)
				FlxG.fullscreen = true;
			else
				FlxG.fullscreen = false;
		}
		#end

		if (subState == null)
		{
			PlayerData.totalSeconds += elapsed;
		}


		super.update(elapsed);

		if (rainShader != null)
		{
			rainShader.update(elapsed);
		}

		if (castleShader != null)
		{
			castleShader.update(elapsed);
		}

		if (castleInsideShader != null)
		{
			castleInsideShader.update(elapsed);
		}
		
		if (toxicShader != null)
		{
			toxicShader.update(elapsed);
		}

		if (sunsetShader != null)
		{
			sunsetShader.update(elapsed);
		}

		if (circusShader != null)
		{
			if (bg != null) bg.shader = circusShader;
			bg.x = -200;
			circusShader.update(elapsed);
		}

		if (rainbowShader != null)
		{
			if (bg != null) bg.shader = rainbowShader;
			rainbowShader.data.time.value[0] += elapsed;
		}

		if (screenShader != null)
		{
			try
			{
				screenShader.data.time.value[0] += elapsed;
			}
			catch (e:Dynamic) {}
		}

		FlxG.collide(player, map);
		FlxG.collide(player, slabs);
		FlxG.collide(player, solidBlock);

		FlxG.overlap(player, warpsGroup, (p, w) -> { HandleWarp(cast w); });
		FlxG.overlap(player, savesGroup, (p, s) -> { SaveLogicSprite(cast s); });
		FlxG.overlap(player, redCoinsGroup, (p, c) -> { RedCoinLogic(cast c); });
		FlxG.overlap(player, doubleJumpGroup, (p, d) -> { DoubleJumpLogic(cast d); });
		FlxG.overlap(player, portalGroup, (p, pw) -> { PortalWarpLogic(cast pw); });
		FlxG.overlap(player, flipGroup, (p, sw) -> { FlipSwitchObjLogic(cast sw); });

		FlxG.collide(player, trampolines, (p, t) ->
		{
			var tramp:NormalTrampoline = cast t;
			if (player.touching == DOWN && tramp.touching == UP)
			{
				player.velocity.y = -1000;
				tramp.launch();
				FlxG.sound.play(AssetPaths.trampoline_bounce__ogg, 0.5, false);
			}
		});
		FlxG.collide(player, trampolinesMini, (p:Player, t:NormalTrampolineMini) ->
		{
			var trampMini:NormalTrampolineMini = cast t;
			if (trampMini.animation.curAnim != null && StringTools.startsWith(trampMini.animation.curAnim.name, "jump") && !trampMini.animation.finished)
			{
				return;
			}
				
			var hitFloor = p.touching.has(DOWN);
			var hitPlayerLeft = p.touching.has(LEFT);
			var hitPlayerRight = p.touching.has(RIGHT);

			switch (trampMini.launchDir)
			{
				case "up":
					if (hitFloor)
					{
						p.velocity.y = -730;
						p.canDoubleJump = true;
						trampMini.launch();
						FlxG.sound.play(AssetPaths.trampoline_bounce__ogg, 0.5);
					}

				case "left":
					if (hitPlayerLeft && !hitFloor)
					{
						p.maxVelocity.x = 800;
						p.velocity.x = 800;
						p.velocity.y = -600;
						p.canDoubleJump = true;
						trampMini.launch();
						FlxG.sound.play(AssetPaths.big_bounce__ogg, 0.5);
						FlxG.sound.play(AssetPaths.lateral_bounce__ogg, 0.5);
					}

				case "right":
					if (hitPlayerRight && !hitFloor)
					{
						p.maxVelocity.x = 800;
						p.velocity.x = -800;
						p.velocity.y = -600;
						p.canDoubleJump = true;
						trampMini.launch();
						FlxG.sound.play(AssetPaths.big_bounce__ogg, 0.5);
						FlxG.sound.play(AssetPaths.lateral_bounce__ogg, 0.5);
					}
			}
		});

		if (player != null && player.exists)
		{
			platforms.forEachAlive(function(plat:MovingBlock)
			{
				var deltaX = plat.x - plat.last.x;
				var deltaY = plat.y - plat.last.y;

				if (deltaX != 0 || deltaY != 0)
				{
					var playerBottom = player.y + player.height;
					var standingOnThis = player.x + player.width > plat.x &&
										 player.x < plat.x + plat.width &&
										 playerBottom >= plat.last.y - 4 &&
										 playerBottom <= plat.last.y + 8 &&
										 player.velocity.y >= 0;

					if (standingOnThis)
					{
						player.x += deltaX;
						player.y = plat.y - player.height;
						player.velocity.y = 0;
						player.isRidingPlatform = true;
						player.touching = flixel.util.FlxDirectionFlags.DOWN;
					}
				}
			});

			fallingBlock.forEachAlive(function(plat:FallingBlock)
			{
				var deltaX = plat.x - plat.last.x;
				var deltaY = plat.y - plat.last.y;

				if (deltaX != 0 || deltaY != 0)
				{
					var playerBottom = player.y + player.height;
					var standingOnThis = player.x + player.width > plat.x &&
										 player.x < plat.x + plat.width &&
										 playerBottom >= plat.last.y - 4 &&
										 playerBottom <= plat.last.y + 8 &&
										 player.velocity.y >= 0;

					if (standingOnThis)
					{
						player.x += deltaX;

						player.y = plat.y - player.height;

						player.velocity.y = 0;
						
						player.isRidingPlatform = true;
						player.touching = flixel.util.FlxDirectionFlags.DOWN;
					}
				}
			});
		}

		FlxG.collide(player, platforms);

		FlxG.collide(platforms, map, function(plat:MovingBlock, wall:FlxObject)
		{
			plat.stopMovement();
		});

		FlxG.collide(player, fallingBlock);

		if (spawnTimer > 0 || inmortal)
		{
			spawnTimer -= elapsed;
		}
		
		if (spawnTimer <= 0 && !inmortal)
		{
			FlxG.overlap(player, dangerObjects, function(p:flixel.FlxObject, hazard:flixel.FlxObject)
			{
				if (FlxG.pixelPerfectOverlap(player, cast hazard))
				{
					killPlayer();
				}
			});
		}

		if (currentBoss != null && currentBoss.exists && currentBoss.alive && currentBoss.visible && currentBoss.alpha > 0)
		{
			if (Std.isOfType(currentBoss, main.bosses.ch1.BossJevil.Jevil))
			{
				var jevilBoss:main.bosses.ch1.BossJevil.Jevil = cast currentBoss;
				if (jevilBoss.state != "waiting" && 
                jevilBoss.state != "precutscene" && 
                jevilBoss.state != "cutscene" && 
                jevilBoss.state != "startCube" && 
                jevilBoss.state != "attackingCube" && 
                jevilBoss.state != "returningCube" &&
                jevilBoss.state != "ultimate_cutscene" &&
                jevilBoss.state != "ultimate_transition" &&
                jevilBoss.state != "ultimate_barrage" &&
                jevilBoss.state != "dead")
            	{
					FlxG.overlap(player, currentBoss, function(p, b)
					{
						if (FlxG.pixelPerfectOverlap(player, jevilBoss))
						{
							killPlayer();
						}
					});
				}
			}
		}

		if (PlayerData.saveCooldown > 0)
		{
			PlayerData.saveCooldown -= elapsed;
			if (PlayerData.saveCooldown < 0)
				PlayerData.saveCooldown = 0;
		}

		if (timeElapsed != null)
		{
			timeElapsed.text = "Time: " + PlayerData.formatTime();
		}

		#if !mobile
		if (FlxG.keys.justPressed.TAB)
		{
			FlxG.debugger.drawDebug = !FlxG.debugger.drawDebug;
		}

		if (FlxG.keys.justPressed.R && player.exists && player.alive)
		{
			var currentSeconds = PlayerData.totalSeconds;
			if (PlayerData.tutorialCompleted == true) PlayerData.totalDeaths++;
			leveldata.misc.SaveManager.saveGameRestart();
			leveldata.misc.SaveManager.loadGame();
			PlayerData.totalSeconds = currentSeconds;
			FlxG.resetState();
		}

		if (FlxG.keys.justPressed.K && player.exists)
		{
			if (PlayerData.currentChapter == 0) return;
			killPlayer();
		}

		if (FlxG.keys.justPressed.S)
		{
			trace("===================");
			trace("Player X:" + player.x);
			trace("Player Y:" + player.y);
			trace("===================");
		}


		if (FlxG.keys.justPressed.Z && player.exists) playerShoot();
		{
			FlxG.collide(bullets, map, (bullet, wall) ->
			{
				bullet.kill();
			});
		}

		

		if (FlxG.keys.justPressed.ESCAPE && player.exists )
		{
			if (fightingBoss)
			{
				FlxG.sound.play(AssetPaths.error__ogg, 0.65, false);
				FlxG.camera.shake(0.01, 0.15);
				return;
			}

			isPaused = true;
			this.persistentUpdate = false;
			openSubState(new gui.PauseState());
		}
		#end

		if (whiteFade.alpha > 0) { whiteFade.alpha -= 0.01; }
		if (PlayerData.whiteFadeTrigger == true)
		{ 
			PlayerData.whiteFadeTrigger = false;
			whiteFade.alpha = 1;
		}

		if (blackFade.alpha > 0) { blackFade.alpha -= 0.01; }
		if (PlayerData.blackFadeTrigger == true)
		{ 
			PlayerData.blackFadeTrigger = false;
			blackFade.alpha = 1;
		}

		if (PlayerData.currentChapter >= 1 && player.exists && player.alive)
		{
			playerDeaths.visible = true;
			playerDeaths.text = "Total Resets: " + PlayerData.totalDeaths;
		}

		else if (playerDeaths != null)
		{
			playerDeaths.visible = false;
		}

		bullets.forEachAlive((bullet) ->
		{
			if (!bullet.isOnScreen())
			{
				bullet.kill();
			}
		});

		if (player != null && player.exists && playerGlow != null)
		{
			playerGlow.exists = true;
			playerGlow.x = player.x + (player.width / 2) - (playerGlow.width / 2);
			playerGlow.y = player.y + (player.height / 2) - (playerGlow.height / 2);
		}
		else if (playerGlow != null)
		{
			playerGlow.exists = false;
		}

		var trailTarget = player.velocity.y >= 800 ? 0.05 : 0.0;
		playerTrail.alpha = flixel.math.FlxMath.lerp(playerTrail.alpha, trailTarget, 0.02);

		#if mobile
		if (virtualPad.buttonA.justPressed)
			playerShoot();
		{
			FlxG.collide(bullets, map, (bullet, wall) ->
			{
				bullet.kill();
			});
		}
		#end

		if (player.x > map.width + 100 || player.y > map.height + 100)
		{
			killPlayer();
		}

		if (FlxG.keys.justPressed.T)
		{
			trace("PLAYER X: " + player.x + " ||| PLAYER Y: " + player.y);
		}

		if (FlxG.keys.justPressed.Y)
		{
			trace("MAP WIDTH: " + map.width);
			trace("MAP HEIGHT: " + map.height);
		}

		if (FlxG.keys.justPressed.B)
		{
			trace("CURRENT ROOM: " + currentRoomName);
		}


		if (currentBoss != null && Std.isOfType(currentBoss, main.bosses.ch1.BossJevil.Jevil))
		{
			var bossJevil:main.bosses.ch1.BossJevil.Jevil = cast currentBoss;
			if (bossJevil != null && bossJevil.state == "waiting" && player.x > map.x + (map.width / 3))
			{
				bossJevil.preCutscene();
			}
		}

		if (currentBoss != null && currentBoss.exists && currentBoss.alive)
		{
			if (currentBossName == "reznor")
			{
				var reznorBoss:main.bosses.ch1.BossReznor.Reznor = cast currentBoss;
				
				if (reznorBoss.status != "waiting" && reznorBoss.status != "cutscene")
				{
					for (minion in reznorBoss.minions)
					{
						if (minion.alive && minion.exists)
						{
							FlxG.overlap(bullets, minion, function(bullet, m)
							{
								var rm:main.bosses.ch1.BossReznor.ReznorMinion = cast m;
								rm.takeDamage(30);
								bullet.kill();
							});
						}
					}
				}
			}
			else 
			{
				FlxG.overlap(bullets, currentBoss, function(bullet, boss)
				{
					if (Std.isOfType(boss, main.bosses.ch1.BossJevil.Jevil))
					{
						var jevilBoss:main.bosses.ch1.BossJevil.Jevil = cast boss;
						
						if (jevilBoss.isVulnerable)
						{
							jevilBoss.takeDamage(1);
							bullet.kill();
						}
					}
					else 
					{
						var invul:Bool = Reflect.field(boss, "isInvulnerable");
						if (!invul)
						{
							bullet.kill();
						}
					}
				});
			}
		}

		#if !mobile
		if (FlxG.keys.justPressed.ONE)
		{
			PlayerData.currentChapter = 1;
			RoomLoader.loadRoom(this, "map02");
		}
		if (FlxG.keys.justPressed.TWO)
		{
			PlayerData.currentChapter = 1;
			RoomLoader.loadRoom(this, "map41");
		}
		if (FlxG.keys.justPressed.THREE)
		{
			PlayerData.currentChapter = 1;
			RoomLoader.loadRoom(this, "map09");
		}

		if (FlxG.keys.justPressed.FOUR)
		{
			PlayerData.currentChapter = 1;
			RoomLoader.loadRoom(this, "map37");
		}

		if (FlxG.keys.justPressed.SEVEN)
		{
			PlayerData.currentChapter = 1;
			RoomLoader.loadRoom(this, "map23");
		}

		if (FlxG.keys.justPressed.EIGHT)
		{
			PlayerData.currentChapter = 1;
			RoomLoader.loadRoom(this, "boss-reznor01");
		}

		if (FlxG.keys.justPressed.NINE)
		{
			PlayerData.currentChapter = 1;
			RoomLoader.loadRoom(this, "boss-jevil01");
		}

		
		if (FlxG.keys.justPressed.ZERO)
		{
			PlayerData.currentChapter = 1;
			RoomLoader.loadRoom(this, "testing");
		}
		if (FlxG.keys.justPressed.I)
		{
			inmortal = !inmortal;
		}

		#end

		if (FlxG.keys.justPressed.P)
		{
			trace("--- COIN STATUS ---");
			trace("Total Coins: " + PlayerData.getCoinCount());
			trace("IDs in memory: " + PlayerData.collectedCoins);
		}

		if (cameraType != "normal" && !isAutoscrolling)
		{
			if (cameraSnapTimer >= 0)
			{
				if (cameraSnapTimer <= 0)
				{
					FlxG.camera.follow(cameraTarget, PLATFORMER, 0.1);
				}
				else
				{
					FlxG.camera.follow(cameraTarget, PLATFORMER, 1);
					cameraSnapTimer -= 1;
				}
			}
		}
		if (udpClient != null) {
			if (testingUDP) {
				udpTestTimer += elapsed;
				
				// Send a probe ping every 0.3 seconds to test connection quickly
				if (Math.floor(udpTestTimer / 0.3) > Math.floor((udpTestTimer - elapsed) / 0.3)) {
					var payload = '{"ping":true,"reply":false,"time":' + haxe.Timer.stamp() + '}';
					udpClient.send(payload);
				}
				
				if (udpTestTimer >= 1.5) {
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
			if (pingTimer >= 2.0) {
				pingTimer = 0;
				var payload = '{"ping":true,"reply":false,"time":' + haxe.Timer.stamp() + '}';
				udpClient.send(payload);
			}

			if (player != null && player.alive) {
				networkTimer += elapsed;
				if (networkTimer >= tickRate)
				{
					networkTimer = 0;
					var currentAnim = (player.animation.curAnim != null ? player.animation.curAnim.name : "idle");
					var userStr = (Multiplayer.activeMode == Server) ? Multiplayer.username : "peer";
					var payload:String = '{"x":' + player.x + ',"y":' + player.y + ',"flip":' + player.isFlipped + ',"facingRight":' + Player.isFacingRIGHT
						+ ',"skin":"' + PlayerData.currentSkin + '","anim":"' + currentAnim + '","currentRoom":"' + currentRoomName + '","username":"' + userStr + '"}';
					udpClient.send(payload);
				}
			}

			// Recibir todos los paquetes pendientes
			var packet:String = null;
			while ((packet = udpClient.receive()) != null) {
				if (testingUDP) {
					testingUDP = false;
					udpReceivedResponse = true;
					trace("[Multiplayer] UDP connection verified! Using UDP mode.");
				}
				try {
					var data = haxe.Json.parse(packet);

					// Handle Ping packets
					if (data.ping == true) {
						var timeVal:Float = cast data.time;
						if (data.reply == false) {
							var replyPayload = '{"ping":true,"reply":true,"time":' + timeVal + '}';
							udpClient.send(replyPayload);
						} else {
							var rtt = haxe.Timer.stamp() - timeVal;
							Multiplayer.currentPing = rtt * 1000;
							trace("Current Ping: " + Multiplayer.currentPing + "ms");
						}
						continue;
					}
					
					// Ignore packets sent by ourselves in Server mode
					if (Multiplayer.activeMode == Server && data.username != null && data.username == Multiplayer.username) {
						continue;
					}

					var peerKey = (Multiplayer.activeMode == Server) ? data.username : "peer";
					if (peerKey == null || peerKey == "") {
						peerKey = "peer";
					}

					if (data.death == true) {
						var dRoomStr:String = data.currentRoom != null ? cast data.currentRoom : "";
						var cRoomStr:String = currentRoomName != null ? cast currentRoomName : "";
						var isBossDeathMatch = (dRoomStr != "" && cRoomStr != "" && StringTools.startsWith(dRoomStr, "boss-") && StringTools.startsWith(cRoomStr, "boss-") && dRoomStr.split("-")[1] == cRoomStr.split("-")[1]);
						if (data.currentRoom == null || data.currentRoom == currentRoomName || isBossDeathMatch) {
							var rPlayer = remotePlayers.get(peerKey);
							var spawnX = (data.x != null) ? data.x : (rPlayer != null ? rPlayer.x : 0);
							var spawnY = (data.y != null) ? data.y : (rPlayer != null ? rPlayer.y : 0);
							bloodParticles(spawnX, spawnY);
							if (rPlayer != null) {
								rPlayer.visible = false;
								rPlayer.exists = false;
								if (rPlayer.usernameText != null) {
									rPlayer.usernameText.visible = false;
								}
							}
						}
					} else if (data.x != null && data.y != null) {
						var rPlayer = remotePlayers.get(peerKey);
						if (rPlayer == null) {
							rPlayer = new main.RemotePlayer(data.x, data.y, peerKey);
							remotePlayers.set(peerKey, rPlayer);
							add(rPlayer);
							add(rPlayer.usernameText);
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

			// Clean up inactive players (timeout after 10 seconds)
			var inactiveKeys:Array<String> = [];
			for (key in remotePlayers.keys()) {
				var rPlayer = remotePlayers.get(key);
				if (rPlayer != null && rPlayer.timeSincePacket >= 10.0) {
					inactiveKeys.push(key);
				}
			}
			for (key in inactiveKeys) {
				var rPlayer = remotePlayers.get(key);
				if (rPlayer != null) {
					bloodParticles(rPlayer.x, rPlayer.y);
					remove(rPlayer.usernameText);
					remove(rPlayer);
					rPlayer.destroy();
					remotePlayers.remove(key);
				}
			}
		}
	}

	override public function destroy():Void
	{
		if (udpClient != null)
		{
			udpClient.close();
			udpClient = null;
		}
		for (rPlayer in remotePlayers) {
			if (rPlayer != null) {
				remove(rPlayer.usernameText);
				rPlayer.destroy();
			}
		}
		remotePlayers.clear();

		super.destroy();
		remotePlayers.clear();

		super.destroy();
	}

	function imgCache():Void
	{
		FlxG.bitmap.add(AssetPaths.save__png);
		FlxG.bitmap.add(AssetPaths.playerGlow__png);
	}

	function sfxCache():Void
	{
		FlxG.sound.cache(AssetPaths.jump__ogg);
		FlxG.sound.cache(AssetPaths.doublejump__ogg);
		FlxG.sound.cache(AssetPaths.break_block__ogg);
		FlxG.sound.cache(AssetPaths.savedgame__ogg);
		FlxG.sound.cache(AssetPaths.death_bgm__ogg);
	}

	function chapter1Cache():Void
	{
		FlxG.sound.cache(AssetPaths.castle1__ogg);
		FlxG.sound.cache(AssetPaths.castle_underground__ogg);
		FlxG.bitmap.add(AssetPaths.ch1tiles__png);
	}

	function chapter2Cache():Void
	{
		// TODO:
	}

	function playerShoot():Void
	{
		if (!player.active || player.alpha == 0 || player.visible == false) return;

		var bullet = new FlxSprite();
		bullet.loadGraphic(AssetPaths.bullet__png, false);
		add(bullet);

		if (Player.isFacingRIGHT == false)
		{
			bullet.velocity.x = -800;
			bullet.x = player.x + -20;
			bullet.y = player.y + 4;
		}
		else if (Player.isFacingRIGHT == true)
		{
			bullet.velocity.x = 800;
			bullet.x = player.x + 30;
			bullet.y = player.y + 4;
		}

		bullets.add(bullet);
		FlxG.sound.play(AssetPaths.playershoot__ogg, 0.5, false);
	}

	function HandleWarp(w:WarpTrigger):Void
	{
		
		if (w.newChapter != null && w.newChapter != "")
		{
			PlayerData.currentChapter = Std.parseInt(w.newChapter);
		}

		var oldWidth:Float = map.width;
		var relativeX:Float = player.x - map.x;

		RoomLoader.loadRoom(this, w.targetRoom);

		switch (w.direction)
		{
			case "up":
				player.y = map.y + map.height - player.height - 60;
				var relativeX:Float = player.x - map.x;

			case "down":
				player.y = map.y + 60;

			case "left":
				player.x = map.x + map.width - player.width - 60;

			case "right":
				player.x = map.x + 60;
		}

		var minX:Float = map.x + 20;
		var maxX:Float = map.x + map.width - player.width - 20;

		if (player.x < minX)
			player.x = minX;
		if (player.x > maxX)
			player.x = maxX;

		#if !debug
		if (cameraTarget != null && cameraType != "normal")
		{
			if (cameraType == "unlockY")
				cameraTarget.x = FlxG.width / 2;
			else
				cameraTarget.x = player.x;

			if (cameraType == "unlockX")
				cameraTarget.y = FlxG.height / 2;
			else
				cameraTarget.y = player.y;
		}
		#end

		spawnTimer = 0.15;
	}

	function setupHUD():Void
	{
		#if debug
		currentChapter = new FlxText(50, FlxG.height - 90, 0, "Chapter: ", 18);
		currentChapter.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		currentChapter.scrollFactor.set(0, 0);
		currentChapter.alpha = 0.5;
		add(hud);

		lastSave = new FlxText(50, FlxG.height - 60, 0, "Last Save: ", 18);
		lastSave.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		lastSave.scrollFactor.set(0, 0);
		lastSave.alpha = 0.5;
		add(hud);
		#end

		#if !mobile
		playerDeaths = new FlxText(FlxG.width - 260, FlxG.height - 80, 0, "Total Resets: ", 22);
		playerDeaths.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		playerDeaths.scrollFactor.set(0, 0);
		playerDeaths.alpha = 0.5;
		playerDeaths.visible = false;
		add(hud);
		#end

		#if mobile
		playerDeaths = new FlxText(FlxG.width - 260, 30, 0, "Total Deaths: ", 22);
		playerDeaths.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		playerDeaths.scrollFactor.set(0, 0);
		playerDeaths.alpha = 0.5;
		playerDeaths.visible = false;
		add(hud);
		#end

		timeElapsed = new FlxText(50, 20, 0, "Time: 00:00:00", 22);
		timeElapsed.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		timeElapsed.scrollFactor.set(0, 0);
		timeElapsed.visible = false;
		add(timeElapsed);
	}

	function SaveLogicSprite(saveObj:SavePoint):Void
	{
		if (saveObj.alive)
		{
			if (PlayerData.currentRoom == currentRoomName)
			{
				saveObj.alive = false;
				saveObj.visible = false;
				saveObj.kill();
				return;
			}
			PlayerData.spawnX = player.x;
			PlayerData.spawnY = player.y + 60;
			PlayerData.currentRoom = currentRoomName;

			if (PlayerData.saveCooldown <= 0)
			{
				saveObj.pop(player);
				whiteFade.alpha = 0.5;
				FlxG.sound.play(AssetPaths.savedgame__ogg, 0.5, false);
				SaveManager.saveGame();
			}

			saveObj.alive = false;
			saveObj.visible = false;
			saveObj.kill();
		}
	}

	function RedCoinLogic(redCoin:RedCoin):Void
	{
		if (redCoin == null || !redCoin.exists || !redCoin.alive)
			return;
		if (redCoin.alive && redCoin.exists) 
		{
			if (!PlayerData.isCoinCollected(redCoin.coinID))
			{
				trace("Pushing coin ID to memory: " + redCoin.coinID);
				PlayerData.collectedCoins.push(redCoin.coinID);
			}

			whiteFade.alpha = 0.5;
			redCoin.pop(player);
			trace("Collected coin with ID: " + redCoin.coinID);
			FlxG.sound.play(AssetPaths.coin__ogg, 0.5, false);
			redCoin.kill();
		}
	}

	function DoubleJumpLogic(doublejObj:DoubleJumpObj):Void
	{
		if (doublejObj.alive)
		{
			if (player.canDoubleJump == false)
			{
				player.canDoubleJump = true;
			}
			doublejObj.kill();
		}
	}

	function FlipSwitchObjLogic(flipSwitchObj:FlipSwitch):Void
	{
		if (!flipSwitchObj.alive)
			return;

		flipSwitchObj.kill();
		FlxG.sound.play(AssetPaths.flip__ogg);

		player.flipGravity();

		FlxTween.tween(FlxG.camera,
		{
			angle: player.isFlipped ? 180 : 0
		}, 0.5,
		{
			ease: FlxEase.sineInOut
		});
	}

	function PortalWarpLogic(portalLogic:PortalWarp):Void
	{
		PlayerData.tutorialCompleted = true;
		PlayerData.currentChapter = 1;
		PlayerData.currentRoom = "map01";
		PlayerData.totalDeaths = 0;
		player.exists = false;
		
		whiteFade.alpha = 1;
		playerDeaths.visible = false;
		
		if (FlxG.sound.music != null) { FlxG.sound.music.stop(); }
		FlxG.sound.play(AssetPaths.warp__ogg, 0.85, false);
		FlxG.camera.shake(0.01, 0.25);

		new FlxTimer().start(3, function(_)
        {
            FlxTween.tween(blackFade, {alpha: 1}, 3,
			{
				ease: FlxEase.quadOut,

			 	onComplete: function(_)
				{
					trace("Tutorial Complete!");
					SaveManager.saveGame();
					FlxG.switchState(gui.IntroState.new);
				}
			});

        });

	}

	function killPlayer():Void
	{
		if (PlayerData.currentChapter == 0)
		{
			player.x = 250;
			player.y = 450;
			player.velocity.set(0, 0);
			FlxG.sound.play(AssetPaths.warp__ogg, 0.75, false);
			FlxG.camera.shake(0.01, 0.2);
			whiteFade.alpha = 0.65;

			return;
		}
		

		if (player != null && player.exists && player.alive)
		{
			if (FlxG.sound.music != null)
			{
				PlayerData.lastMusicTime = FlxG.sound.music.time;
			}

			PlayerData.isRespawning = true;
			PlayerData.saveCooldown = 1.0;

			PlayerData.deathX = player.x;
			PlayerData.deathY = player.y;
			playerGlow.visible = false;
			player.kill();

			if (playerTrail != null)
			{
				playerTrail.kill();
			}

			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();
			this.persistentUpdate = true;
			PlayerData.totalDeaths -= 1;

			bloodParticles();

			/* if multiplayer */
			if (udpClient != null) {
				var userStr = (Multiplayer.activeMode == Server) ? Multiplayer.username : "peer";
				var payload:String = '{"death": true, "x": ' + player.x + ', "y": ' + player.y + ', "currentRoom": "' + currentRoomName + '","username":"' + userStr + '"}';
				udpClient.send(payload);
			}

			var isJevilRoom = (currentRoomName != null && StringTools.startsWith(currentRoomName, "boss-jevil")) || (currentBossName == "jevil");
			if (isJevilRoom)
			{
				if (jevil != null && jevil.ultimateManager != null)
				{
					jevil.ultimateManager.cancelBarrage();
				}

				openSubState(new KrisDeathState());
				return;
			}

            openSubState(new DeathState());
		}
	}

	function initLoopPoints():Void
	{
		if (loopPoints != null)
			return;

		loopPoints = new Map<String, Float>();

		var fileContent:String = openfl.Assets.getText("assets/data/music/loopPoints.txt");

		if (fileContent != null)
		{
			var lines:Array<String> = fileContent.split("\n");
			for (line in lines)
			{
				var parts:Array<String> = line.split(":");
				if (parts.length == 2)
				{
					var songName:String = StringTools.trim(parts[0]);
					var loopTime:Float = Std.parseFloat(StringTools.trim(parts[1]));
					loopPoints.set(songName, loopTime);
				}
			}
		}
	}

	function updateMusic():Void
	{
		if (player != null && !player.alive)
			return;
		if (subState != null)
			return;

		var musicLayer = tiledData.getLayer("music");
		if (musicLayer == null)
			return;
		var songName:String = musicLayer.properties.get("songName");

		var relativePath = "music/chapters/chapter" + PlayerData.currentChapter + "bgm/" + songName + ".ogg";
		var songPath = ModLoader.getAsset(relativePath);

		#if sys
		var isModded:Bool = ModLoader.overrides.exists(relativePath);
		#else
		var isModded:Bool = false;
		#end

		initLoopPoints();
		var loopStartMs:Float = 0;

		if (!isModded && loopPoints.exists(songName))
		{
			loopStartMs = loopPoints.get(songName) * 1000;
		}

		if (PlayerData.currentSong == songPath && FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			if (PlayerData.isRespawning)
			{
				FlxG.sound.music.time = PlayerData.lastMusicTime;
				PlayerData.isRespawning = false;
			}
			return;
		}

		PlayerData.currentSong = songPath;

		#if sys
		if (ModLoader.overrides.exists(relativePath))
		{
			var customSound = openfl.media.Sound.fromFile(songPath);
			if (customSound != null)
			{
				FlxG.sound.playMusic(customSound, 0.75, true);
			}
			else
			{
				FlxG.sound.playMusic("assets/" + relativePath, 0.75, true); // Fallback
			}
		}
		else
		{
			FlxG.sound.playMusic(songPath, 0.75, true);
		}
		#else
		FlxG.sound.playMusic(songPath, 0.75, true);
		#end

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.loopTime = loopStartMs;
		}

		if (PlayerData.isRespawning)
		{
			if (FlxG.sound.music != null)
				FlxG.sound.music.update(0);

			FlxG.sound.music.time = PlayerData.lastMusicTime;
			PlayerData.isRespawning = false;
		}
	}

	function autoScroll():Void
	{
		isAutoscrolling = false;
		autoscrollType = "none";
		scrollOffsetX = 0;
		scrollSpeed = 0;

		for (layer in tiledData.layers)
		{
			if (layer.type == TiledLayerType.OBJECT)
			{
				var objLayer:TiledObjectLayer = cast layer;

				if (layer.name.toLowerCase() == "autoscroll")
				{
					if (objLayer.properties.contains("autoscrollType"))
					{
						autoscrollType = objLayer.properties.get("autoscrollType");
					}
					
					if (objLayer.properties.contains("speed"))
					{
						scrollSpeed = Std.parseFloat(objLayer.properties.get("speed"));
					}

					if (objLayer.properties.contains("offsetX"))
					{
						scrollOffsetX = Std.parseFloat(objLayer.properties.get("offsetX"));
					}

					if (autoscrollType == "scrollX" || autoscrollType == "scrollY")
					{
						isAutoscrolling = true;
					}
				}

				if (layer.name == "PlayerSpeed" && objLayer.properties.contains("value"))
				{
					var pSpeed = Std.parseFloat(objLayer.properties.get("value"));
					player.mapMaxSpeed = pSpeed;
					player.maxVelocity.x = pSpeed;
				}
			}
		}
	}

	function cameraScroll():Void
	{
		cameraType = "normal";
		FlxG.camera.target = null;

		var camLayer = tiledData.getLayer("camera");
		if (camLayer != null && camLayer.properties.contains("cameraType"))
		{
			cameraType = camLayer.properties.get("cameraType");
		}

		if (map != null)
		{
			switch (cameraType)
			{
				case "unlockX":
					trace("UnlockX");
					FlxG.camera.setScrollBoundsRect(map.x + 60, map.y + 65, map.width - 120, map.height + 65, false);

				case "unlockY":
					trace("UnlockY");
					FlxG.camera.setScrollBoundsRect(map.x + 60, map.y + 65, map.width - 120, map.height - 115, false);

				case "unlockXY":
					trace("UnlockXY");
					FlxG.camera.setScrollBoundsRect(map.x + 60, map.y + 65, map.width - 120, map.height - 115, false);

				case "debug":
					trace("debug");
					FlxG.camera.follow(player, FlxCameraFollowStyle.LOCKON);

				default:
					trace("Default");
					FlxG.camera.setScrollBoundsRect(map.x + 60, map.y + 65, map.width - 50, map.height + 65, false);
			}

			FlxG.worldBounds.set(map.x - 200, map.y - 200, map.width + 400, map.height + 400);
		}

		if (cameraTarget == null)
		{
			cameraTarget = new flixel.FlxObject(player.x, player.y, 1, 1);
			add(cameraTarget);
		}

		if (this.isAutoscrolling)
		{
			if (autoscrollType == "scrollX")
			{
				FlxG.camera.minScrollX = null;
                FlxG.camera.maxScrollX = null;

                if (map != null)
                {
                    FlxG.camera.minScrollY = map.y;
                    FlxG.camera.maxScrollY = map.y + map.height;
                }

                cameraTarget.setPosition(player.x, player.y);
                cameraTarget.velocity.x = scrollSpeed;
                cameraTarget.velocity.y = 0;

			}
			else if (autoscrollType == "scrollY")
			{
				if (map != null)
                {
					FlxG.camera.minScrollX = null;
					FlxG.camera.maxScrollX = null;

					FlxG.camera.minScrollY = null;
					FlxG.camera.maxScrollY = map.y + map.height;
                }

				var startX = (map != null ? map.x + (map.width / 2) : player.x) + scrollOffsetX;
                var startY = map != null ? (map.y + map.height - (FlxG.height / 2)) : player.y;

                cameraTarget.setPosition(startX, startY);
                cameraTarget.velocity.y = -scrollSpeed;
                cameraTarget.velocity.x = 0;
			}
			FlxG.camera.focusOn(cameraTarget.getPosition());
			FlxG.camera.follow(cameraTarget, LOCKON, 1);
		}
		else if (cameraType != "normal")
		{
			var cameraMarginX:Float = 0;
			var cameraMarginY:Float = 0;
			var cameraMarginW:Float = 0;
			var cameraMarginH:Float = 0;

			if (cameraType == "unlockX")
			{
				cameraMarginX = FlxG.width * 0.3;
				cameraMarginW = FlxG.width * 0.3;

				cameraMarginY = FlxG.height / 2;
				cameraMarginH = 0;
			}
			else if (cameraType == "unlockY")
			{
				cameraMarginX = FlxG.width / 2;
				cameraMarginW = 0;

				cameraMarginY = FlxG.height * 0.3;
				cameraMarginH = FlxG.height * 0.4;
			}
			else if (cameraType == "unlockXY")
			{
				cameraMarginX = FlxG.width * 0.3;
				cameraMarginW = FlxG.width * 0.4;
				cameraMarginY = FlxG.height * 0.3;
				cameraMarginH = FlxG.height * 0.4;
			}

			FlxG.camera.deadzone = flixel.math.FlxRect.get(cameraMarginX, cameraMarginY, cameraMarginW, cameraMarginH);
		}
		else
		{
			if (map != null)
			{
				FlxG.camera.scroll.set(-260, -265);
			}
		}
	}

	function bloodParticles(?x:Float, ?y:Float):Void
	{
		var spawnX = (x != null) ? x : PlayerData.deathX;
		var spawnY = (y != null) ? y : PlayerData.deathY;
		blood = new flixel.effects.particles.FlxEmitter(spawnX, spawnY, 250);
		blood.makeParticles(3, 3, flixel.util.FlxColor.RED, 250);
		blood.launchMode = CIRCLE;
		blood.speed.set(300, 700);
		blood.acceleration.set(0, 1200);
		blood.lifespan.set(2, 4);
		blood.alpha.set(1, 1, 0, 0);

		blood.scale.set(0.5, 0.5, 1.5, 1.5);
		add(blood);
		blood.start(true, 0, 250);
	}

	function layoutVirtualPad():Void
	{
		if (virtualPad == null)
			return;
		var padScale:Float = 2.5;
		var hitboxPadding:Float = 40;

		var allButtons = [virtualPad.getButton(LEFT), virtualPad.getButton(RIGHT), virtualPad.getButton(A)];

		for (button in allButtons)
		{
			if (button == null)
				continue;
			button.scale.set(padScale, padScale);
			button.updateHitbox();
			button.width += hitboxPadding;
			button.height += hitboxPadding;

			button.offset.x -= hitboxPadding / 2;
			button.offset.y -= hitboxPadding / 2;

			button.scrollFactor.set(0, 0);
			button.alpha = targetAlpha;
		}

		if (virtualPad.getButton(LEFT) != null)
		{
			virtualPad.getButton(LEFT).x = 100;
			virtualPad.getButton(LEFT).y = FlxG.height - virtualPad.getButton(LEFT).height - 90;
		}

		if (virtualPad.getButton(RIGHT) != null && virtualPad.getButton(LEFT) != null)
		{
			virtualPad.getButton(RIGHT)
				.x = virtualPad.getButton(LEFT)
					.x + virtualPad.getButton(LEFT)
					.width + 40;
			virtualPad.getButton(RIGHT).y = virtualPad.getButton(LEFT).y;
		}

		if (virtualPad.getButton(A) != null)
		{
			virtualPad.getButton(A).x = FlxG.width - virtualPad.getButton(A).width - 140;
			virtualPad.getButton(A).y = FlxG.height - virtualPad.getButton(A).height - 200;
		}
	}

    public function initBossHUD(bossInstance:main.bosses.ch1.BossJevil.Jevil):Void
    {
        this.jevil = bossInstance;

        bossHpBar = new FlxBar((FlxG.width - 400) / 4, 20, LEFT_TO_RIGHT, 800, 20, jevil, "hp", 0, 120);
        bossHpBar.createFilledBar(0xFF551111, 0xFFFFFFFF, true, 0xFF000000);
		bossHpBar.screenCenter();
		bossHpBar.y = 10;
        bossHpBar.scrollFactor.set(0, 0);
		bossHpBar.visible = true;
        if (player.alive && player.active) { add(bossHpBar); }

    }
}
