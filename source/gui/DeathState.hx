package gui;
import main.bosses.ch1.BossJevil.Jevil;
import flixel.sound.FlxSound;
import openfl.media.Sound;
import main.mods.ModLoader;
import flixel.input.gamepad.id.SwitchJoyconLeftID;
import main.ChapterState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.effects.particles.FlxEmitter;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import character.KrisDeathState;
import main.PlayerData;
import main.bosses.ch1.BossJevil;

class DeathState extends FlxSubState
{        
    var particles:FlxSprite;
    var bg:FlxSprite;
    var maintext:FlxText;
    var subtext:FlxText;
    var timerTip:Float = 1;
    var deathCamera:flixel.FlxCamera;

    override public function create():Void
    {

        deathCamera = new flixel.FlxCamera(0, 0, FlxG.width, FlxG.height);
        deathCamera.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(deathCamera, false);

        var tips:Array<String> =
        [
        "Don't die :)",
        "Spikes kill you",
        "Ctrl + Shift + Alt + Win + L",
        "Lasers are bad too",
        "You're here again!?",
        "Just a pixel off",
        "Play Kill The Guy instead",
        "Look behind you.",
        "You shouldn't die",
        "Forced clip.",
        "Totally planned",
        "You need Dream's luck",
        "Is this screen scary?",
        "Alt + F4",
        "Blind jumps are cool",
        "Hahahaha",
        "Maybe you should uninstall",
        "The Guy? THE GUUUYY?!",
        "Error 404: Skill Not Found",
        "Maybe restarting the router?",
        "I saw that..",
        "Better luck next time!",
        "Oops! You slipped!",
        "Why so bad?",
        "That was the attempt?",
        "69420th Attempt soon?",
        "Friday Guy Funkin'",
        "DO NOT REDEEM THE CARD!",
        "You have ONE life left!",
        "I didn't see that..",
        "Just jump better",
        "A and D to move BTW",
        "Stop playing the game.",
        "Next room is even worse..",
        "This is the easy part!",
        "Not your game.. At all.",
        "Easier than Boshy",
        "YOU HAVE ONE LIFE LEFT!",
        "And you cry",
        "Don't you love this music?",
        "The Guy deserved better.",
        "IDK just play Minecraft",
        "Easier than Kamilia",
        "The Binding of the Guy...",
        "Focus, K",
        "You forgot to survive",
        "Try no hits next time!",
        "Spikes deal much damage",
        "Maybe whale in this game..??",
        "Are you sad?",
        "Don't explode",
        "Everything is balanced :)",
        "Glitches are intentional",
        "Nothing personnel kid",
        "Rage quit incoming?",
        "I love spikes and so should you",
        "And you die",
        "Kid, kid, what is your problem, kid?",
        "Five Nights at This Screen",
        "Lol"
        ];

        var proTip:String = FlxG.random.getObject(tips);

        switch (PlayerData.currentSkin)
        {
            case "boshy":
                ModLoader.playModMusic("music/death/lol_u_died.ogg", 0.7, true);
                FlxG.sound.play(AssetPaths.kill_sound_effect__ogg, 0.5, false);

            case "boyfriend":
                ModLoader.playModMusic("music/death/bf_death.ogg", 0.7, true);

            case "thekris":
                openSubState(new KrisDeathState());

            default:
                ModLoader.playModMusic("music/death/death_bgm.ogg", 0.7, false);
        }

        bg = new FlxSprite();
        bg.makeGraphic(FlxG.width + 1, FlxG.height, FlxColor.BLACK);
        bg.screenCenter();
        bg.alpha = 0;
        bg.scrollFactor.set(0, 0);
        bg.cameras = [deathCamera];
        add(bg);

        maintext = new FlxText("GAME OVER");
		maintext.size = 100;
		maintext.color = FlxColor.WHITE;
		maintext.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
		maintext.screenCenter();
		maintext.y -= 120;
        maintext.scrollFactor.set(0, 0);
        maintext.cameras = [deathCamera];
        FlxTween.angle(maintext, -20, 20, 1, {type: PINGPONG, ease: FlxEase.sineInOut});
		add(maintext);

        subtext = new FlxText("Pro Tip: " + proTip);
		subtext.size = 26;
		subtext.color = FlxColor.WHITE;
		subtext.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
        subtext.screenCenter();
		subtext.y = 450;
        subtext.scrollFactor.set(0, 0);
        subtext.visible = false;
        subtext.cameras = [deathCamera];
        FlxTween.tween(subtext, {y: subtext.y - 5}, 1, {type: PINGPONG, ease: FlxEase.sineInOut});
		add(subtext);
        

        super.create();
        

    }

    override public function update(elapsed:Float):Void
    {
        
        super.update(elapsed);

        #if !mobile
        if (FlxG.keys.justPressed.F11)
        {
            if (FlxG.fullscreen == false) FlxG.fullscreen = true;
            else FlxG.fullscreen = false;
        }
        #end

        if (bg.alpha < 1)
        {
            bg.alpha += 0.0025; 
        }

        if (timerTip > 0) { timerTip -= 0.0075; }
        if (timerTip <= 0) { subtext.visible = true; }

        var gamepad:flixel.input.gamepad.FlxGamepad = FlxG.gamepads.lastActive;
        #if !mobile
        var resetPressed = FlxG.keys.justPressed.R;


        if (gamepad != null)
		{
			if (gamepad.justPressed.LEFT_SHOULDER || gamepad.justPressed.RIGHT_SHOULDER) resetPressed = true;
		}
        if (resetPressed)
        {
            PlayerData.totalDeaths += 1;
            restartLevel();
        }
        #else
        if (FlxG.touches.justStarted().length > 0)
        {
            restartLevel();
        }
        #end

    }

	override public function destroy():Void
	{
		if (maintext != null)
		{
			FlxTween.cancelTweensOf(maintext);
		}

        if (deathCamera != null)
        {
            FlxG.cameras.remove(deathCamera);
            deathCamera = null;
        }

		super.destroy();
	}
    
    function restartLevel():Void
    {
        if (FlxG.sound.music != null) FlxG.sound.music.stop();
        PlayerData.totalDeaths++;
        leveldata.misc.SaveManager.saveGameRestart();
        leveldata.misc.SaveManager.loadGame();
        FlxG.resetState();
    }

}