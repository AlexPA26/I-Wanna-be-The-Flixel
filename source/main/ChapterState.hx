package main;

import character.PlayerCombat;
import character.PlayerDeathHandler;
import debug.DebugCheats;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.effects.FlxTrail;
import flixel.addons.editors.tiled.TiledMap;
import flixel.effects.particles.FlxEmitter;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.ui.FlxBar;
import flixel.ui.FlxVirtualPad;
import flixel.util.FlxColor;
import gui.VirtualPadHelper;
import leveldata.background.*;
import leveldata.backgrounds3D.CircusBackground;
import leveldata.blockdata.*;
import leveldata.collectibles.*;
import leveldata.deco.*;
import leveldata.events.*;
import leveldata.hazards.*;
import leveldata.misc.*;
import main.InputManager.Action;
import main.bosses.BossCombatManager;
import shaders.*;

#if !html5
import coop.NATUPnP;
#end

@:allow(main.iwbtf)
@:allow(main.RoomLoader)
@:allow(leveldata.events.EventLoader)
@:allow(coop)
@:allow(main.bosses.ch1)
class ChapterState extends FlxState
{
	public var player:Player;
	public var playerDeathsTrigger:Bool = false;
	public var chapterHUD:gui.ChapterHUD;
	public var cameraSnapTimer:Int = 1;
	public var playerTrail:FlxTrail;
	public var virtualPad:FlxVirtualPad;
	public var padScale:Float = 2.5;
	public var targetAlpha:Float = 0.5;
	public var hudGroup:FlxGroup;
	public var bullets:FlxTypedGroup<FlxSprite>;
	public var playerGlow:FlxSprite;
	public var cameraTarget:FlxObject;
	public var cameraOffsetY:Float = -225;
	public var scrollSpeed:Float = 0;
	public var scrollOffsetX:Float = 0;
	public var isAutoscrolling:Bool = false;
	public var autoscrollType:String = "none";
	public var fightingBoss:Bool = false;

	public var currentBossName:String = "";
	public var currentBoss:FlxSprite = null;
	public var cameraType:String = "normal";
	public var isPaused:Bool = false;
	public var specialState:Bool = false;

	public var bg:FlxSprite;
	public var circusBG:CircusBackground;

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

	public var map:FlxTilemap;
	public var mapDeco:FlxTilemap;
	public var mapDeco2:FlxTilemap;

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

	public var whiteFade:FlxSprite;
	public var blackFade:FlxSprite;
	public var tiledData:TiledMap;
	public var spawnTimer:Float = 0.1;
	public var inmortal:Bool = false;
	public var bossHpBar:FlxBar;
	public var jevil:main.bosses.ch1.BossJevil.Jevil;

	public var tpBar:FlxBar;
	public var currentTP:Float = 0;
	public var maxTP:Float = 100;
	public var tpBarDeco:FlxSprite;
	public var tpText:FlxText;
	public var grazeHitbox:FlxSprite;
	public var grazedObjects:Array<FlxObject> = [];

	public var coopManager:coop.CoopManager;

	override public function create():Void
	{
		#if (!html5 && !mobile)
		main.Multiplayer.Multiplayer.usingTCP = false;
			#if !debug
			FlxG.mouse.visible = false;
			#end
		#end

		#if debug
			#if !mobile
			FlxG.mouse.visible = true;
			#end
		#end

		hudGroup = new FlxGroup();
		chapterHUD = new gui.ChapterHUD();
		add(chapterHUD);

		virtualPad = new FlxVirtualPad(ANALOG, A);
		coopManager = new coop.CoopManager();
		coopManager.init();

		FlxG.bitmap.clearUnused();

		roomImages = new FlxTypedGroup<FlxSprite>();
		dangerObjects = new FlxGroup();
		savesGroup = new FlxTypedGroup<SavePoint>();
		popups = new FlxTypedGroup<FlxText>();
		saveParticlesGroup = new FlxTypedGroup<FlxEmitter>();
		redCoinsGroup = new FlxTypedGroup<RedCoin>();
		redCoinParticlesGroup = new FlxTypedGroup<FlxEmitter>();
		doubleJumpGroup = new FlxTypedGroup<DoubleJumpObj>();
		eventEffectGroup = new FlxGroup();
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
		ShaderManager.updateShaders(this, elapsed);

		var pExists = player != null && player.exists;
		var pAlive = player != null && player.alive;
		chapterHUD.updateTimeAndDeaths(pExists, pAlive, playerDeathsTrigger);

		// Modularized updates
		CameraManager.update(this, elapsed);
		InteractionHandler.handleAllInteractions(this, elapsed);
		PlayerCombat.updateBullets(this);
		BossCombatManager.update(this, elapsed);
		DebugCheats.handleDebugKeys(this);

		handleTimers(elapsed);
		handleGameInputs();
		updateFades();
		updatePlayerVisuals();
	}

	function handleTimers(elapsed:Float):Void
	{
		if (spawnTimer > 0 || inmortal)
		{
			spawnTimer -= elapsed;
		}

		if (PlayerData.saveCooldown > 0)
		{
			PlayerData.saveCooldown -= elapsed;
			if (PlayerData.saveCooldown < 0)
				PlayerData.saveCooldown = 0;
		}
	}

	function handleGameInputs():Void
	{
		if (player == null || !player.exists)
			return;

		if (InputManager.justPressed(Action.RESTART) && player.alive && player.active && !specialState && spawnTimer <= 0)
		{
			if (fightingBoss && FlxG.sound.music != null)
				FlxG.sound.music.stop();

			var currentSeconds = PlayerData.totalSeconds;
			if (PlayerData.currentChapter != 0)
				PlayerData.totalDeaths++;

			leveldata.misc.SaveManager.saveGameRestart();
			leveldata.misc.SaveManager.loadGame();
			PlayerData.totalSeconds = currentSeconds;
			FlxG.resetState();
			return;
		}

		var gamepad:flixel.input.gamepad.FlxGamepad = FlxG.gamepads.lastActive;
		var shootPressed:Bool = false;
		var pausePressed:Bool = false;

		#if !mobile
		shootPressed = FlxG.keys.justPressed.Z;
		pausePressed = FlxG.keys.justPressed.ESCAPE;
		#end

		if (gamepad != null)
		{
			if (gamepad.justPressed.RIGHT_TRIGGER || gamepad.justPressed.LEFT_TRIGGER)
				shootPressed = true;
			if (gamepad.justPressed.START)
				pausePressed = true;
		}

		#if mobile
		var actionButton = virtualPad == null ? null : virtualPad.getButton(A);
		if (actionButton != null && actionButton.justPressed)
		{
			shootPressed = true;
		}
		#end

		if (shootPressed)
		{
			playerShoot();
		}

		if (pausePressed)
		{
			if (fightingBoss)
			{
				FlxG.sound.play(AssetPaths.error__ogg, 0.65, false);
				FlxG.camera.shake(0.01, 0.15);
				return;
			}

			isPaused = true;
			persistentUpdate = false;
			openSubState(new gui.PauseState());
		}
	}

	function updateFades():Void
	{
		if (whiteFade != null)
		{
			if (whiteFade.alpha > 0)
				whiteFade.alpha -= 0.01;
			if (PlayerData.whiteFadeTrigger)
			{
				PlayerData.whiteFadeTrigger = false;
				whiteFade.alpha = 1;
			}
		}

		if (blackFade != null)
		{
			if (blackFade.alpha > 0)
				blackFade.alpha -= 0.002;
			if (PlayerData.blackFadeTrigger)
			{
				PlayerData.blackFadeTrigger = false;
				blackFade.alpha = 1;
			}
		}
	}

	function updatePlayerVisuals():Void
	{
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

		if (playerTrail != null && player != null)
		{
			var trailTarget = player.velocity.y >= 800 ? 0.05 : 0.0;
			playerTrail.alpha = flixel.math.FlxMath.lerp(playerTrail.alpha, trailTarget, 0.02);
		}
	}

	override public function destroy():Void
	{
		coopManager.destroy(this);
	}

	public function playerShoot():Void
	{
		PlayerCombat.shoot(this);
	}

	public function killPlayer():Void
	{
		PlayerDeathHandler.killPlayer(this);
	}

	public function bloodParticles(?x:Float, ?y:Float):Void
	{
		PlayerDeathHandler.spawnBlood(this, x, y);
	}

	public function autoScroll():Void
	{
		CameraManager.setupAutoscroll(this);
	}

	public function cameraScroll():Void
	{
		CameraManager.setupCamera(this);
	}

	public function layoutVirtualPad():Void
	{
		VirtualPadHelper.layout(virtualPad, padScale, targetAlpha);
	}

	public function initBossHUD(bossInstance:main.bosses.ch1.BossJevil.Jevil):Void
	{
		BossCombatManager.initBossHUD(this, bossInstance);
	}
}
