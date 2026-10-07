import flixel.FlxG;
import main.CacheState;
import main.ChapterState;
import flixel.FlxSprite;
import flixel.FlxGame;
import openfl.display.FPS;
import openfl.display.Sprite;
import main.ChapterState;
import debug.BattleState;
import debug.DebugState;
import main.MenuState;
import main.mods.ModLoader;
import lime.app.Application;
import openfl.Lib;

class Main extends Sprite
{
	var allowQuit:Bool = false;


	public function new()
	{
		super();

		FlxSprite.defaultAntialiasing = false;
		var gameWidth:Int = 1280;
		var gameHeight:Int = 720;
		var initialState = CacheState;
		var debugState = CacheState;
		var zoom:Float = 1;
		var refreshRate:Int = Lib.current.stage.window.displayMode.refreshRate;
		if (refreshRate <= 0) refreshRate = 60;
		var updateFramerate:Int = refreshRate;
		var drawFramerate:Int = refreshRate;
		var skipSplash:Bool = true;
		var startFullscreen:Bool = false;

		/*
		#if !html5
		trace("======= ModLoader Active =======");
		ModLoader.init();
		trace("======= ModLoader Fin =======");
		#end
		*/

		#if html5
			var document = js.Browser.document;
			document.addEventListener("contextmenu", function(event:js.html.Event) { event.preventDefault(); });
		#end
		
		#if !debug
			addChild(new FlxGame(gameWidth, gameHeight, initialState, updateFramerate, drawFramerate, skipSplash, startFullscreen));
			flixel.FlxG.fixedTimestep = false;
		#end

		#if debug
			addChild(new FlxGame(gameWidth, gameHeight, debugState, updateFramerate, drawFramerate, skipSplash, startFullscreen));
			flixel.FlxG.fixedTimestep = false;
		#end
		


		#if !mobile
			addChild(new FPS(10, 10, 0xffffff));
		#end


		flixel.FlxG.autoPause = false;
		
	}


}
