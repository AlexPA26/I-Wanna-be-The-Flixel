package animation;

import main.ChapterState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class TutoralCutscene extends FlxState
{
    var logo:FlxSprite;
    var creditText:FlxText;
    var activeTimers:Array<FlxTimer> = [];
    var state = ChapterState;

    override public function create():Void
    {
        super.create();

        logo = new FlxSprite();
        logo.loadGraphic(AssetPaths.logo_intro__png, false);
        logo.screenCenter();
        logo.y -= 100;
        logo.scale.set(0.65, 0.65);
        add(logo);

        FlxG.sound.play(AssetPaths.beep__ogg, 1, false);

        FlxTween.tween(logo, {y: logo.y - 3}, 0.8, {type: PINGPONG, ease: FlxEase.sineInOut});

        mkTimer(4, function(_)
        {
            creditText = new FlxText(0, 0, FlxG.width, "By: DarkuDev");
            creditText.setFormat(null, 42, FlxColor.WHITE, CENTER);
            creditText.screenCenter();
            creditText.y = logo.y + logo.height + 40;
            add(creditText);

            FlxG.sound.play(AssetPaths.beep__ogg, 1, false);

            FlxTween.tween(creditText, {y: creditText.y - 3}, 0.8, {type: PINGPONG, ease: FlxEase.sineInOut});

            mkTimer(2.5, function(_)
            {
                FlxTween.cancelTweensOf(logo);
                FlxTween.cancelTweensOf(creditText);
                logo.visible = false;
                creditText.visible = false;
                FlxG.sound.play(AssetPaths.beep__ogg, 1, false);

                mkTimer(2, function(_)
                {
                    main.PlayerData.blackFadeTrigger = true;
                    FlxG.switchState(ChapterState.new);
                });
            });
        });
    }

    function mkTimer(time:Float, callback:FlxTimer->Void):FlxTimer
    {
        var t = new FlxTimer().start(time, callback);
        activeTimers.push(t);
        return t;
    }

    override public function destroy():Void
    {
        for (t in activeTimers)
        {
            if (t != null)
            {
                t.cancel();
                t.destroy();
            }
        }
        activeTimers = [];

        if (logo != null) FlxTween.cancelTweensOf(logo);
        if (creditText != null) FlxTween.cancelTweensOf(creditText);

        super.destroy();
    }
}
