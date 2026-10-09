package animation;

import main.ChapterState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import main.PlayerData;
import openfl.filters.ShaderFilter;
import flixel.FlxCamera;

class NewGameCutscene extends FlxSubState
{
    var blackFade:FlxSprite;
    var ch1Txt:FlxText;
    var subTxt:FlxText;

    var vhsShader:shaders.VHSShader;
    var cutsceneCam:FlxCamera;

    inline static final FONT_SIZE:Int = 64;
    inline static final SUB_SIZE:Int = 42;
    
    override public function create()
    {
        #if !mobile
        FlxG.mouse.visible = false;
        #end
        super.create();

        cutsceneCam = new FlxCamera();
        cutsceneCam.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(cutsceneCam, false);


        vhsShader = new shaders.VHSShader(); 
        cutsceneCam.filters = [new ShaderFilter(vhsShader)];

        blackFade = new FlxSprite(0, 0);
        blackFade.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK, false);
        blackFade.alpha = 0;
        add(blackFade);

        ch1Txt = new FlxText(0, 0, FlxG.width, "Chapter 1", FONT_SIZE);
        ch1Txt.setFormat(null, FONT_SIZE, FlxColor.WHITE, CENTER);
        ch1Txt.screenCenter();
        ch1Txt.y -= 100;
        ch1Txt.alpha = 0;
        add(ch1Txt); 

        subTxt = new FlxText(0, 0, FlxG.width, "The Chaos Castle", SUB_SIZE);
        subTxt.setFormat(null, SUB_SIZE, FlxColor.WHITE, CENTER);
        subTxt.screenCenter();
        subTxt.alpha = 0;
        add(subTxt);

        FlxTween.tween(ch1Txt, {y: ch1Txt.y - 3}, 1.5, {type: PINGPONG, ease: FlxEase.sineInOut});
        FlxTween.tween(subTxt, {x: ch1Txt.x - 2}, 0.5, {type: PINGPONG, ease: FlxEase.sineInOut});

        if (FlxG.sound.music != null) FlxTween.tween(FlxG.sound.music, { volume: 0 }, 5);
        
        FlxTween.tween(blackFade, { alpha: 1 }, 5,
        { 
            ease: FlxEase.linear,
            onComplete: function(_)
            {
                this.cameras = [cutsceneCam];
                initCutscene();
            }
        });
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (vhsShader != null)
        {
            vhsShader.update(elapsed); 
        }
    }

    function initCutscene():Void
    {
        FlxTween.tween(ch1Txt, { alpha: 1 }, 1.5,
        { 
            ease: FlxEase.linear,
            onComplete: function(_) 
            {
                new FlxTimer().start(2.5, function(_) 
                {
                    FlxTween.tween(ch1Txt, { alpha: 0 }, 1.5,
                    { 
                        ease: FlxEase.linear,
                        onComplete: function(_) 
                        {

                            new FlxTimer().start(1.5, function(_) 
                            {
                                if (!FlxG.mouse.enabled) FlxG.mouse.enabled = true;
                                if (!FlxG.mouse.visible) FlxG.mouse.visible = true;
                                PlayerData.blackFadeTrigger = true;
                                FlxTween.cancelTweensOf(ch1Txt);
                                FlxTween.cancelTweensOf(subTxt);
                                vhsShader = null;
                                #if !mobile
                                FlxG.mouse.visible = true;
                                #end
                                FlxG.switchState(ChapterState.new);
                                FlxG.cameras.remove(cutsceneCam);

                            });
                        }
                    });

                    FlxTween.tween(subTxt, { alpha: 0 }, 1.5, { ease: FlxEase.linear });
                });
            }
        });

        FlxTween.tween(subTxt, { alpha: 1 }, 1.5, { ease: FlxEase.linear });
    }

    override public function destroy():Void
    {
        if (cutsceneCam != null)
        {
            FlxG.cameras.remove(cutsceneCam);
        }
        super.destroy();
    }
}