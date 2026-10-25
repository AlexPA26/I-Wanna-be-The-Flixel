package character;

import main.PlayerData;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.effects.particles.FlxEmitter;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import main.ChapterState;

class KrisDeathState extends FlxSubState
{
    public static var jevilDeathCount:Int = 0;

    var breakingSoul:FlxSprite;
    var choiceSoul:FlxSprite;
    var gameOverImage:FlxSprite;
    var deathX:Float = 0;
    var deathY:Float = 0;
    
    var bg:FlxSprite;
    var whiteFade:FlxSprite;
    var blackFade:FlxSprite;

    var mainText:FlxText;
    var subText:FlxText;
    var yesText:FlxText;
    var noText:FlxText;

    var isChoosing:Bool = false;
    var isYes:Bool = true;
    var canReset:Bool = true;
    
    var activeTimers:Array<FlxTimer> = [];

    override public function create():Void
    {
        super.create();

        jevilDeathCount++;

        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.scrollFactor.set(0, 0);
        insert(0, bg);

        if (FlxG.camera.angle != 0) FlxG.camera.angle = 0;

        var chapterState:ChapterState = Std.downcast(FlxG.state, ChapterState);
        if (chapterState != null && Reflect.field(chapterState, "player") != null)
        {
            var playerRef = Reflect.field(chapterState, "player");
            var worldX:Float = Reflect.field(playerRef, "x");
            var worldY:Float = Reflect.field(playerRef, "y");
            
            deathX = worldX - FlxG.camera.scroll.x;
            deathY = worldY - FlxG.camera.scroll.y;
        }
        else
        {
            deathX = FlxG.width / 2;
            deathY = FlxG.height / 2;
        }

        breakingSoul = new FlxSprite(deathX, deathY);
        breakingSoul.loadGraphic(AssetPaths.soul__png, true, 20, 16);
        breakingSoul.animation.add("break", [0, 1], 16, false);
        breakingSoul.animation.play("break");
        breakingSoul.scrollFactor.set(0, 0);
        breakingSoul.scale.set(1.5, 1.5);
        add(breakingSoul);

        FlxG.sound.play(AssetPaths.thekid_hit__ogg, 1, false);

        gameOverImage = new FlxSprite();
        gameOverImage.loadGraphic(AssetPaths.jevil_gameOver__png);
        gameOverImage.screenCenter();
        gameOverImage.y -= 200;
        gameOverImage.scrollFactor.set(0, 0);
        gameOverImage.alpha = 0;
        gameOverImage.scale.set(2.5, 2.5);
        FlxTween.tween(gameOverImage, {y: gameOverImage.y - 5}, 3.0, {type: PINGPONG, ease: FlxEase.sineInOut});
        add(gameOverImage);

        mainText = new FlxText(0, 0, FlxG.width, "");
        mainText.setFormat(AssetPaths.deltarune__otf, 48, FlxColor.WHITE, CENTER);
        mainText.setBorderStyle(OUTLINE, FlxColor.fromRGB(64, 64, 64), 3);
        mainText.screenCenter();
        mainText.y += 75;
        mainText.scrollFactor.set(0, 0);
        mainText.alpha = 0.85;
        FlxTween.tween(mainText, {y: mainText.y - 3}, 0.8, {type: PINGPONG, ease: FlxEase.sineInOut});
        addGlowPulse(mainText);
        add(mainText);

        subText = new FlxText(0, 0, FlxG.width, "");
        subText.setFormat(AssetPaths.deltarune__otf, 48, FlxColor.WHITE, CENTER);
        subText.setBorderStyle(OUTLINE, FlxColor.fromRGB(64, 64, 64), 2);
        subText.screenCenter();
        subText.y += 15;
        subText.scrollFactor.set(0, 0);
        subText.alpha = 0.85;
        FlxTween.tween(subText, {y: subText.y - 3}, 0.8, {type: PINGPONG, ease: FlxEase.sineInOut});
        addGlowPulse(subText);
        add(subText);

        yesText = new FlxText(0, 0, 0, "YES");
        yesText.setFormat(AssetPaths.deltarune__otf, 32, FlxColor.WHITE, CENTER);
        yesText.screenCenter();
        yesText.y += 200;
        yesText.x -= 150;
        yesText.scrollFactor.set(0, 0);
        yesText.alpha = 0;
        add(yesText);

        noText = new FlxText(0, 0, 0, "NO");
        noText.setFormat(AssetPaths.deltarune__otf, 32, FlxColor.WHITE, CENTER);
        noText.screenCenter();
        noText.y += 200;
        noText.x += 150;
        noText.scrollFactor.set(0, 0);
        noText.alpha = 0;
        add(noText);

        choiceSoul = new FlxSprite(0, 0);
        choiceSoul.loadGraphic(AssetPaths.soul__png, true, 20, 16);
        choiceSoul.animation.add("idle", [0], 0, false);
        choiceSoul.animation.play("idle");
        choiceSoul.scrollFactor.set(0, 0);
        choiceSoul.scale.set(4, 4);
        choiceSoul.updateHitbox();
        choiceSoul.visible = false;
        choiceSoul.alpha = 0.85;
        choiceSoul.y -= 35;
        insert(1, choiceSoul);

        whiteFade = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
        whiteFade.scrollFactor.set(0, 0);
        whiteFade.alpha = 0;
        add(whiteFade);

        blackFade = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        blackFade.scrollFactor.set(0, 0);
        blackFade.alpha = 0;
        add(blackFade);

        mkTimer(1.2, function(tmplTimer:FlxTimer)
        {
            triggerBloodExplosion(chapterState);
            FlxG.sound.play(AssetPaths.thekid_broken__ogg, 1, false);
        });

        mkTimer(3, function(musicTimer:FlxTimer)
        {
            if (FlxG.sound.music != null)
            {
                FlxG.sound.music.stop();
            }

            FlxG.sound.playMusic(AssetPaths.game_over_jevil__ogg, 1, true);
            startCutsceneSequence();
        });
    }

    function mkTimer(time:Float, callback:FlxTimer->Void, loops:Int = 1):FlxTimer
    {
        var t = new FlxTimer().start(time, callback, loops);
        activeTimers.push(t);
        return t;
    }

    function addGlowPulse(text:FlxText):Void
    {
        FlxTween.tween(text, {alpha: 0.8}, 0.5, {type: PINGPONG, ease: FlxEase.sineInOut});
    }

    function triggerBloodExplosion(chapterState:ChapterState):Void
    {
        breakingSoul.visible = false;

        var substateBlood:FlxEmitter = new FlxEmitter(deathX + (breakingSoul.width / 2), deathY + (breakingSoul.height / 2));
        substateBlood.launchMode = CIRCLE;
        
        substateBlood.speed.set(300, 400);
        substateBlood.acceleration.set(0, 400);
        substateBlood.lifespan.set(2, 4);
        substateBlood.alpha.set(1, 1, 0, 0);
        substateBlood.scale.set(1, 1, 2, 2);
        substateBlood.makeParticles(3, 3, FlxColor.RED, 10);
        
        add(substateBlood);
        substateBlood.start(true, 0, 10);
    }

    function startCutsceneSequence():Void
    {
        FlxTween.tween(gameOverImage, {alpha: 1}, 2.0);

        mkTimer(3.0, function(_)
        {
            var promptText:String = (jevilDeathCount <= 2) ? "WILL YOU TRY AGAIN?" : "DO NOT GIVE UP!";

            typeText(mainText, promptText, 0.1, function()
            {
                FlxTween.tween(yesText, {alpha: 1}, 1.0);
                FlxTween.tween(noText, {alpha: 1}, 1.0, {
                    onComplete: function(_)
                    {
                        isChoosing = true;
                        choiceSoul.visible = true;
                        updateSoulPosition();
                    }
                });
            });
        });
    }

    function typeText(textObj:FlxText, content:String, speed:Float, onComplete:Void->Void):Void
    {
        textObj.text = "";
        textObj.visible = true;
        var count = 0;
        
        mkTimer(speed, function(t:FlxTimer)
        {
            count++;
            textObj.text = content.substr(0, count);
            FlxG.sound.play(AssetPaths.jevil_talk__ogg, 0.75, false);
            if (count >= content.length && onComplete != null)
            {
                onComplete();
            }
        }, content.length);
    }

    function updateSoulPosition():Void
    {
        if (isYes)
        {
            choiceSoul.x = yesText.x + (yesText.width / 2) - (choiceSoul.width / 2);
            choiceSoul.y = yesText.y + 10;
        }
        else
        {
            choiceSoul.x = noText.x + (noText.width / 2) - (choiceSoul.width / 2);
            choiceSoul.y = noText.y + 10;
        }
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        var gamepad:flixel.input.gamepad.FlxGamepad = FlxG.gamepads.lastActive;
        #if !mobile
        var resetPressed = FlxG.keys.justPressed.R;

        if (gamepad != null)
		{
			if (gamepad.justPressed.LEFT_SHOULDER || gamepad.justPressed.RIGHT_SHOULDER) resetPressed = true;
		}
        if (resetPressed && canReset)
        {
            PlayerData.totalDeaths += 1;
            quickReset();
        }

        if (isChoosing)
        {
            if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.LEFT)
            {
                isYes = true;
                updateSoulPosition();
            }
            else if (FlxG.keys.justPressed.D || FlxG.keys.justPressed.RIGHT)
            {
                isYes = false;
                updateSoulPosition();
            }

            if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.Z || FlxG.keys.justPressed.SPACE)
            {
                isChoosing = false;
                canReset = false;

                if (FlxG.sound.music != null) FlxG.sound.music.stop();
                FlxG.sound.play(AssetPaths.restart_jevil__ogg, 1, false);

                FlxTween.tween(yesText, {alpha: 0}, 0.5);
                FlxTween.tween(noText, {alpha: 0}, 0.5);
                FlxTween.tween(choiceSoul, {alpha: 0}, 0.5, {
                    onComplete: function(_) { choiceSoul.visible = false; }
                });

                if (isYes) executeYes();
                else executeNo();
            }
        }
        #end
    }

    function executeYes():Void
    {
        mkTimer(0.5, function(_)
        {
            mainText.alpha = 1;
            mainText.y -= 150;
            gameOverImage.visible = false;
            mainText.text = "THEN THE FUTURE IS IN YOUR HANDS";
            
            FlxTween.tween(whiteFade, {alpha: 1}, 2.5, {
                onComplete: function(_)
                {
                    mkTimer(0.5, function(_)
                    {
                        PlayerData.totalDeaths += 1;
                        PlayerData.whiteFadeTrigger = true;
                        quickReset();
                    });
                }
            });
        });
    }

    function executeNo():Void
    {
        mkTimer(0.5, function(_)
        {
            mainText.alpha = 1;
            
            typeText(mainText, "THEN THE WORLD WAS COVERED IN DARKNESS", 0.08, function()
            {
                mkTimer(1.0, function(_)
                {
                    blackFade.alpha = 1; 
                    
                    mkTimer(2.0, function(_)
                    {
                        PlayerData.totalDeaths += 1;
                        FlxG.switchState(main.MenuState.new);
                    });
                });
            });
        });
    }

    function quickReset():Void
    {
        if (FlxG.sound.music != null) FlxG.sound.music.stop();
        PlayerData.totalDeaths++;
        leveldata.misc.SaveManager.saveGameRestart();
        leveldata.misc.SaveManager.loadGame();
        FlxG.resetState();
    }

    override public function destroy():Void
    {
        for (t in activeTimers)
        {
            if (t != null) t.cancel();
        }
        super.destroy();
    }
}