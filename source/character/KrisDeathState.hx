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
    var soul:FlxSprite;
    var deathX:Float = 0;
    var deathY:Float = 0;
    var bg:FlxSprite;
    var gameOverText:FlxText;
    var fullText:String = "GAME OVER";
    var retryText:FlxText;
    var currentLetterCount:Int = 0;
    var textTimer:FlxTimer;

    override public function create():Void
    {
        super.create();

        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.scrollFactor.set(0, 0);
        add(bg);

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

        soul = new FlxSprite(deathX, deathY);
        
        soul.loadGraphic(AssetPaths.soul__png, true, 20, 16);
        soul.animation.add("break", [0, 1], 16, false);
        soul.animation.play("break");
        soul.scrollFactor.set(0, 0);
        soul.scale.set(1.5, 1.5);
        add(soul);

        FlxG.sound.play(AssetPaths.kris_hit__ogg, 1);

        gameOverText = new FlxText(0, 0, FlxG.width, "");
        gameOverText.setFormat(AssetPaths.deltarune__otf, 128, FlxColor.WHITE, CENTER);
        gameOverText.setBorderStyle(OUTLINE, 0xFF0000, 2);
        gameOverText.screenCenter();
        gameOverText.y -= 150;
        gameOverText.scrollFactor.set(0, 0);
        gameOverText.visible = false;
        FlxTween.tween(gameOverText, {y: gameOverText.y - 5}, 1, {type: PINGPONG, ease: FlxEase.sineInOut});
        add(gameOverText);

        retryText = new FlxText(0, 0, FlxG.width, "Press 'R' to try again.");
        retryText.setFormat(AssetPaths.deltarune__otf, 32, FlxColor.WHITE, CENTER);
        retryText.screenCenter();
        retryText.y = gameOverText.y + 300;
        retryText.scrollFactor.set(0, 0);
        retryText.visible = false;
        FlxTween.tween(retryText, {y: retryText.y - 2}, 1, {type: PINGPONG, ease: FlxEase.sineInOut});
        add(retryText);

        new FlxTimer().start(2.1, function(musicTimer:FlxTimer)
        {
            if (FlxG.sound.music != null)
            {
                FlxG.sound.music.stop();
            }

        FlxG.sound.playMusic(AssetPaths.determination__ogg, 1, true);

        gameOverText.visible = true;
        currentLetterCount = 0;

        textTimer = new FlxTimer().start(0.5, function(t:FlxTimer)
        {
            currentLetterCount++;
            gameOverText.text = fullText.substr(0, currentLetterCount);

            gameOverText.screenCenter(Y);

            if (currentLetterCount == fullText.length)
            {
                new FlxTimer().start(1, function(_)
                {
                    retryText.alpha = 0;
                    retryText.visible = true;
                    FlxTween.tween(retryText, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
                });
            }

        }, fullText.length);

    });

        new FlxTimer().start(0.95, function(tmplTimer:FlxTimer)
        {
            triggerBloodExplosion(chapterState);
        });
    }

    function triggerBloodExplosion(chapterState:ChapterState):Void
    {
        soul.visible = false;

        var substateBlood:FlxEmitter = new FlxEmitter(deathX + (soul.width / 2), deathY + (soul.height / 2));
        substateBlood.launchMode = CIRCLE;
        
        substateBlood.speed.set(300, 700);
        substateBlood.acceleration.set(0, 1200);
        substateBlood.lifespan.set(2, 4);
        substateBlood.alpha.set(1, 1, 0, 0);
        substateBlood.scale.set(1, 1, 2, 2);
        substateBlood.makeParticles(3, 3, FlxColor.RED, 10);
        
        add(substateBlood);
        substateBlood.start(true, 0, 10);

    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (FlxG.keys.justPressed.R)
        {
            if (FlxG.sound.music != null)
            {
                if (FlxG.sound.music != null) FlxG.sound.music.stop();
                PlayerData.totalDeaths++;
                leveldata.misc.SaveManager.saveGameRestart();
                leveldata.misc.SaveManager.loadGame();
                FlxG.resetState();
            }
        }
    }

    override public function destroy():Void
    {
        if (textTimer != null)
        {
            textTimer.cancel();
        }
        super.destroy();
    }
}