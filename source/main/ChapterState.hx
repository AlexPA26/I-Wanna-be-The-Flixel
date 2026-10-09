package main;

import leveldata.backgrounds3D.CircusBackground;
import main.InputManager.Action;
import backgrounds3D.*;
import flixel.util.FlxTimer;
import character.KrisDeathState;
import shaders.*;
import main.Multiplayer.UdpClient;
import main.Multiplayer.Multiplayer;
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

#if !html5 import coop.NATUPnP; #end

@:allow(main.iwbtf)
@:allow(main.RoomLoader)
@:allow(leveldata.events.EventLoader)
@:allow(coop)
@:allow(main.bosses.ch1)
class ChapterState extends FlxState
{
	var player:Player;
	var currentDeaths = PlayerData.totalDeaths;
	public var playerDeathsTrigger:Bool = false;
	public var chapterHUD:gui.ChapterHUD;
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
	public var specialState:Bool = false;

	public var bg:FlxSprite;
	public var circusBG:leveldata.backgrounds3D.CircusBackground;

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
	public var portalGroup:FlxTypedGroup<TutorialWarp>;
	public var invisPortalGroup:FlxTypedGroup<InvisWarp>;
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
	public var invisBlock:FlxTypedGroup<InvisibleBlock>;

	public var hud:FlxGroup;

	var spikes:FlxGroup;
	var whiteFade:FlxSprite;
	var blackFade:FlxSprite;
	var tiledData:TiledMap;
	var spawnTimer:Float = 0.1;
	var inmortal:Bool = false;
	var bossHpBar:FlxBar;
    var bossDebugText:FlxText;
	public var jevil:main.bosses.ch1.BossJevil.Jevil;
	public var reznor:main.bosses.ch1.BossReznor.Reznor;

	public var tpBar:FlxBar; public var currentTP:Float = 0; public var maxTP:Float = 100;
	public var tpBarDeco:FlxSprite; public var tpText:FlxText;
    public var grazeHitbox:FlxSprite; public var grazedObjects:Array<flixel.FlxObject> = [];

	public var coopManager:coop.CoopManager;

	override public function create():Void
	{
		#if (!html5 && !mobile)
		Multiplayer.usingTCP = false;
			#if !debug
				#if !mobile
					FlxG.mouse.visible = false;
				#end
			#end
		#end

		#if debug
			#if !mobile
				FlxG.mouse.visible = true;
			#end
		#end

		hudGroup = new FlxGroup();
		chapterHUD = new gui.ChapterHUD(); add(chapterHUD);
		virtualPad = new FlxVirtualPad(LEFT_RIGHT, A);
		coopManager = new coop.CoopManager();
		coopManager.init();

		FlxG.bitmap.clearUnused();

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
		portalGroup = new FlxTypedGroup<TutorialWarp>();
		invisPortalGroup = new FlxTypedGroup<InvisWarp>();
		trampolines = new FlxTypedGroup<NormalTrampoline>();
		trampolinesMini = new FlxTypedGroup<NormalTrampolineMini>();
		platforms = new FlxTypedGroup<MovingBlock>();
		fallingBlock = new FlxTypedGroup<FallingBlock>();
		lightsGroup = new FlxTypedGroup<LightTorch>();
		slabs = new FlxTypedGroup<NormalSlab>();
		solidBlock = new FlxTypedGroup<SolidBlock>();
		invisBlock = new FlxTypedGroup<InvisibleBlock>();
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

		if (InputManager.justPressed(Action.FULLSCREEN))
		{
			FlxG.fullscreen = !FlxG.fullscreen;
		}

		if (subState == null)
		{
			PlayerData.totalSeconds += elapsed;
		}


		super.update(elapsed);

		coopManager.update(this, elapsed);
		shaders.ShaderManager.updateShaders(this, elapsed);

		var pExists = player != null && player.exists;
		var pAlive = player != null && player.alive;
		chapterHUD.updateTimeAndDeaths(pExists, pAlive, playerDeathsTrigger);

		FlxG.collide(player, map);
		FlxG.collide(player, slabs);
		FlxG.collide(player, solidBlock);
		FlxG.collide(player, invisBlock);

		FlxG.overlap(player, warpsGroup, (p, w) -> { HandleWarp(cast w); });
		FlxG.overlap(player, savesGroup, (p, s) -> { SaveLogicSprite(cast s); });
		FlxG.overlap(player, redCoinsGroup, (p, c) -> { RedCoinLogic(cast c); });
		FlxG.overlap(player, doubleJumpGroup, (p, d) -> { DoubleJumpLogic(cast d); });
		FlxG.overlap(player, portalGroup, (p, pw) -> { TutorialWarpLogic(cast pw); });
		FlxG.overlap(player, invisPortalGroup, (p, ipw) -> { InvisWarpLogic(cast ipw); });
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
						if (plat.velocity.y <= 0)
						{
							player.y = plat.y - player.height;
							player.velocity.y = 0;
							player.isRidingPlatform = true;
							player.touching = flixel.util.FlxDirectionFlags.DOWN;
						}
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
		
		if (spawnTimer <= 0 && !inmortal && player.active)
		{
			FlxG.overlap(player, dangerObjects, function(p:flixel.FlxObject, hazard:flixel.FlxObject)
			{
				if (FlxG.pixelPerfectOverlap(player, cast hazard))
				{
					killPlayer();
				}
			});
		}

		if (grazeHitbox != null && player != null && player.exists)
        {
            grazeHitbox.x = player.x + (player.width / 2) - (grazeHitbox.width / 2);
            grazeHitbox.y = player.y + (player.height / 2) - (grazeHitbox.height / 2);

            if (grazeHitbox.alpha > 0)
            {
                grazeHitbox.alpha -= elapsed * 3;
                if (grazeHitbox.alpha < 0) grazeHitbox.alpha = 0;
            }

            var i:Int = grazedObjects.length;
            while (i-- > 0)
            {
                var obj = grazedObjects[i];
                if (obj == null || !obj.exists || !obj.alive)
                {
                    grazedObjects.splice(i, 1);
                }
            }

            if (fightingBoss && !inmortal && jevil.state != "attackingCube" && jevil.state != "returningCube")
            {
                FlxG.overlap(grazeHitbox, dangerObjects, function(hitbox:flixel.FlxObject, hazard:flixel.FlxObject)
                {
                    if (!grazedObjects.contains(hazard))
                    {
                        grazedObjects.push(hazard);
                        
                        currentTP += jevil.tpIncrease;
                        if (currentTP > maxTP) currentTP = maxTP;

                        grazeHitbox.alpha = 0.4;
                        FlxG.sound.play(AssetPaths.jevil_graze__ogg, 0.8, false);
                    }
                });
            }

			if (tpText != null && tpText.exists)
			{
				if (currentTP >= maxTP)
				{
					tpText.text = "MAX";
					tpText.color = flixel.util.FlxColor.YELLOW;
				}
				else
				{
					tpText.text = Std.string(Std.int(currentTP));
					tpText.color = flixel.util.FlxColor.WHITE;
				}
			}
        }

		if (currentBoss != null && currentBoss.exists && currentBoss.alive && currentBoss.visible && currentBoss.alpha > 0 && !inmortal && spawnTimer <= 0)
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


		#if !mobile
		if (FlxG.keys.justPressed.TAB)
		{
			FlxG.debugger.drawDebug = !FlxG.debugger.drawDebug;
		}
		#end
		if (InputManager.justPressed(Action.RESTART) && player.exists && player.alive && player.active && !specialState && spawnTimer <= 0)
		{
			if (fightingBoss && FlxG.sound.music != null) FlxG.sound.music.stop();
			var currentSeconds = PlayerData.totalSeconds;
			if (PlayerData.currentChapter != 0) PlayerData.totalDeaths++;
			leveldata.misc.SaveManager.saveGameRestart();
			leveldata.misc.SaveManager.loadGame();
			PlayerData.totalSeconds = currentSeconds;
			FlxG.resetState();
		}

		#if !mobile
		if (FlxG.keys.justPressed.K && player.exists && player.alive && player.active && !specialState)
		{
			if (PlayerData.currentChapter == 0) return;
			killPlayer();
		}
		#end

		var gamepad:flixel.input.gamepad.FlxGamepad = FlxG.gamepads.lastActive;
		var shootPressed:Bool = false;
		var pausePressed:Bool = false;

		#if !mobile
		shootPressed = FlxG.keys.justPressed.Z;
		pausePressed = FlxG.keys.justPressed.ESCAPE;
		#end
		if (gamepad != null)
		{
			if (gamepad.justPressed.RIGHT_TRIGGER || gamepad.justPressed.LEFT_TRIGGER) shootPressed = true;
			if (gamepad.justPressed.START) pausePressed = true;
		}

		if (shootPressed && player.exists)
		{
			playerShoot();
			FlxG.collide(bullets, map, (bullet, wall) ->
			{
				bullet.kill();
			});
		}

		if (pausePressed && player.exists)
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

		if (whiteFade.alpha > 0) { whiteFade.alpha -= 0.01; }
		if (PlayerData.whiteFadeTrigger == true)
		{ 
			PlayerData.whiteFadeTrigger = false;
			whiteFade.alpha = 1;
		}

		if (blackFade.alpha > 0) { blackFade.alpha -= 0.002; }
		if (PlayerData.blackFadeTrigger == true)
		{ 
			PlayerData.blackFadeTrigger = false;
			blackFade.alpha = 1;
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
								rm.takeDamage(1);
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
							var jCenterX = jevilBoss.x + (jevilBoss.width / 2);
                            var jCenterY = jevilBoss.y + (jevilBoss.height / 2);
                            
                            var bCenterX = bullet.x + (bullet.width / 2);
                            var bCenterY = bullet.y + (bullet.height / 2);
                            
                            var dx = bCenterX - jCenterX;
                            var dy = bCenterY - jCenterY;
                            var distance = Math.sqrt((dx * dx) + (dy * dy));
                            
                            if (distance < 50)
                            {
								var isCrit = FlxG.random.int(1, 2) == 1;
								var damage = isCrit ? 2 : 1;
                                jevilBoss.takeDamage(damage, false);
								jevilBoss.jevilWasHit = true;
                                bullet.kill();
                            }
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
		if (FlxG.keys.justPressed.ONE && !fightingBoss)
		{
			PlayerData.currentChapter = 1;
			RoomLoader.loadRoom(this, "map01");
		}
		if (FlxG.keys.justPressed.TWO && !fightingBoss)
		{
			PlayerData.currentChapter = 1;
			RoomLoader.loadRoom(this, "map25");
		}
		if (FlxG.keys.justPressed.THREE && !fightingBoss)
		{
			PlayerData.currentChapter = 1;
			RoomLoader.loadRoom(this, "map37");
		}

		if (FlxG.keys.justPressed.FOUR && !fightingBoss)
		{
			PlayerData.currentChapter = 1;
			RoomLoader.loadRoom(this, "map41");
		}

		if (FlxG.keys.justPressed.FIVE && !fightingBoss)
		{
			PlayerData.currentChapter = 1;
			RoomLoader.loadRoom(this, "map43");
		}

		if (FlxG.keys.justPressed.SIX && !fightingBoss)
		{
			PlayerData.currentChapter = 1;
			RoomLoader.loadRoom(this, "map43");
		}

		if (FlxG.keys.justPressed.SEVEN && !fightingBoss)
		{
			PlayerData.currentChapter = 1;
			RoomLoader.loadRoom(this, "map50");
		}

		if (FlxG.keys.justPressed.EIGHT && !fightingBoss)
		{
			PlayerData.currentChapter = 1;
			RoomLoader.loadRoom(this, "map23");
		}

		if (FlxG.keys.justPressed.NINE && !fightingBoss)
		{
			PlayerData.currentChapter = 1;
			RoomLoader.loadRoom(this, "boss-jevil01");
		}

		
		if (FlxG.keys.justPressed.ZERO && !fightingBoss)
		{
			PlayerData.currentChapter = 1;
			RoomLoader.loadRoom(this, "testing");
		}
		if (FlxG.keys.justPressed.I)
		{
			inmortal = !inmortal;
		}

		if (FlxG.keys.justPressed.P)
		{
			trace("--- COIN STATUS ---");
			trace("Total Coins: " + PlayerData.getCoinCount());
			trace("IDs in memory: " + PlayerData.collectedCoins);
		}

		#end

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

	}

	override public function destroy():Void
	{
		coopManager.destroy(this);
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
		FlxG.sound.play(AssetPaths.playershoot__ogg, 1, false);
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

	function TutorialWarpLogic(portalLogic:TutorialWarp):Void
	{
		PlayerData.tutorialCompleted = true;
		PlayerData.currentRoom = "map01";
		PlayerData.currentChapter = 1;
		PlayerData.totalDeaths = 0;
		player.exists = false;
		
		whiteFade.alpha = 1;
		
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
					FlxG.switchState(animation.TutoralCutscene.new);
				}
			});

        });

	}

	function InvisWarpLogic(portalLogic:InvisWarp):Void
	{

		invisPortalGroup.active = false;
		if (FlxG.sound.music != null) { FlxG.sound.music.stop(); }
		FlxG.sound.play(AssetPaths.warp__ogg, 0.85, false);
		FlxG.sound.play(AssetPaths.jevil_hypnosis__ogg, 0.5, false);
		FlxG.camera.shake(0.01, 0.25);
		PlayerData.jevilDialogueRead = false;
		whiteFade.alpha = 1;

		RoomLoader.loadRoom(this, "boss-jevil01");

		var blur:openfl.filters.BlurFilter = new openfl.filters.BlurFilter(8, 8, 2);
        if (FlxG.camera.filters == null) FlxG.camera.filters = [];

        FlxG.camera.filters.push(blur);
        FlxTween.num(16, 0, 0.5, { ease: FlxEase.quadOut, onComplete: function(_)
        {
            if (FlxG.camera.filters != null)
            {
                FlxG.camera.filters.remove(blur);
                if (FlxG.camera.filters.length == 0)
                    FlxG.camera.filters = null;
            }
        }},
        function(v:Float)
        {
            if (blur != null)
            {
                blur.blurX = v;
                blur.blurY = v;
            }
        });

	}

	function killPlayer():Void
	{
		if (PlayerData.currentChapter == 0)
		{
			coopManager.sendDeathPacket(this);
			player.x = 250;
			player.y = 450;
			player.velocity.set(0, 0);
			FlxG.sound.play(AssetPaths.warp__ogg, 0.75, false);
			FlxG.camera.shake(0.01, 0.2);
			whiteFade.alpha = 0.65;
			FlxG.sound.music.pitch = 1.0;

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

			if (FlxG.sound.music != null) FlxG.sound.music.stop();
			this.persistentUpdate = true;
			PlayerData.totalDeaths -= 1;

			bloodParticles();

			var isJevilRoom = (currentBossName == "jevil");
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
					trace("New Camera triggered: UnlockX");
					FlxG.camera.setScrollBoundsRect(map.x + 60, map.y + 65, map.width - 120, map.height + 65, false);

				case "unlockY":
					trace("New Camera triggered: UnlockY");
					FlxG.camera.setScrollBoundsRect(map.x + 60, map.y + 65, map.width - 120, map.height - 115, false);

				case "unlockXY":
					trace("New Camera triggered: UnlockXY");
					FlxG.camera.setScrollBoundsRect(map.x + 60, map.y + 65, map.width - 120, map.height - 115, false);

				case "debug":
					trace("New Camera triggered: debug");
					FlxG.camera.follow(player, FlxCameraFollowStyle.LOCKON);

				default:
					trace("New Camera triggered: Default");
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

		tpBar = new FlxBar(70, (FlxG.height / 2) - 250, BOTTOM_TO_TOP, 30, 300, this, "currentTP", 0, maxTP);
        tpBar.createFilledBar(0xff8b0d00, 0xFFFFA500, false, 0xFF000000);
        tpBar.scrollFactor.set(0, 0);
        if (player.alive && player.active) { add(tpBar); }

		tpBarDeco = new FlxSprite();
		tpBarDeco.loadGraphic(AssetPaths.jevil_tpBar__png, false);
		tpBarDeco.x = 20;
		tpBarDeco.y = 110;
		tpBarDeco.scrollFactor.set(0, 0);
		if (player.alive && player.active) { add(tpBarDeco); }

		tpText = new flixel.text.FlxText(tpBar.x + tpBar.width - 86, tpBar.y + (tpBar.height / 2) - 46, 0, "0", 22);
        tpText.setFormat("assets/fonts/deltarune.otf", 28, flixel.util.FlxColor.WHITE, "center", flixel.text.FlxText.FlxTextBorderStyle.OUTLINE, flixel.util.FlxColor.TRANSPARENT);
        tpText.scrollFactor.set(0, 0);
        if (player.alive && player.active) { add(tpText); }
		
		grazeHitbox = new FlxSprite();
        grazeHitbox.loadGraphic(AssetPaths.glaze_boss__png, false);
        grazeHitbox.alpha = 0;
		grazeHitbox.y -= 5;
        add(grazeHitbox);

		currentTP = 0;
        grazedObjects = [];

    }
}
