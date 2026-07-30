package gui;

import openfl.filters.BlurFilter;
import openfl.filters.BitmapFilter;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import main.ChapterState;
import flixel.FlxCamera;
import shaders.SunsetWarmShader;

class PauseState extends FlxSubState
{
    var bg:FlxSprite;
    var assetsGroup:FlxGroup;
    var pauseText:FlxText;
    var alphaText:Float = 0;
    var bgFadeTimer:Float = 0.0025;
    var btnTitle:FlxButton;
    var optionsBtn:FlxButton;
    var btnStages:FlxButton;
    var respawnBtn:FlxButton;
    var statsText:FlxText;
    var originalVolume:Float = 1.0;

    var originalFilters:Array<BitmapFilter> = [];
    var isClosing:Bool = false;

    var activeTweens:Map<FlxButton, FlxTween> = new Map();
    var activeLabelTweens:Map<FlxText, FlxTween> = new Map();
    var pauseTween:FlxTween;
    
    var uiCamera:FlxCamera;

    override public function create()
    {
        super.create();
        openfl.ui.Mouse.show();

        originalVolume = FlxG.sound.volume;
        FlxG.sound.volume = originalVolume * 0.3;

        uiCamera = new FlxCamera(0, 0, FlxG.width, FlxG.height);
        uiCamera.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(uiCamera, false);

        if (FlxG.camera.filters != null)
        {
            originalFilters = FlxG.camera.filters.copy();
        }
        // Deliberately NOT copying originalFilters onto uiCamera — it renders the
        // pause menu itself (buttons, text, stats), which should always look crisp
        // and untinted regardless of whatever gameplay shader is active underneath.

        // Force the shader/filter chain to do its (apparently expensive) recompile
        // NOW, while the pause menu is already up and a brief hitch is unnoticeable —
        // rather than at resume time, where the same hitch felt like a jarring freeze.
        FlxG.camera.filters = [];
        FlxG.camera.filters = originalFilters;

        #if debug
        traceFilterChain("create() — captured originalFilters");
        #end

        var pauseFilters = originalFilters.copy();
        pauseFilters.push(new BlurFilter(2, 2, 2));
        FlxG.camera.filters = pauseFilters;
        assetsGroup = new FlxGroup();

        bg = new FlxSprite();
        bg.makeGraphic(1300, 800, FlxColor.BLACK, false);
        bg.screenCenter();
        bg.alpha = 0;
        assetsGroup.add(bg);

        pauseText = new FlxText("Game Paused");
        pauseText.size = 80;
        pauseText.color = FlxColor.WHITE;
        pauseText.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
        pauseText.screenCenter();
        pauseText.y -= 240;
        pauseText.scrollFactor.set(0, 0);
        assetsGroup.add(pauseText);

        pauseTween = FlxTween.tween(pauseText, {y: pauseText.y - 3}, 0.8, {type: PINGPONG, ease: FlxEase.sineInOut});

        
        add(assetsGroup);

        respawnBtn = new FlxButton(0, 0, "Respawn", clickRespawn);
        setupButtonPosition(respawnBtn, 350, -120);

        optionsBtn = new FlxButton(0, 0, "Options", clickOptions);
        setupButtonPosition(optionsBtn, 350, -20);

        btnTitle = new FlxButton(0, 0, "Main Menu", clickMainMenu);
        setupButtonPosition(btnTitle, 350, 80);

        btnStages = new FlxButton(0, 0, "Stages", clickStages);
        setupButtonPosition(btnStages, 350, 180);

        assetsGroup.cameras = [uiCamera];
        respawnBtn.cameras = [uiCamera];
        optionsBtn.cameras = [uiCamera];
        btnTitle.cameras = [uiCamera];
        btnStages.cameras = [uiCamera];

        var statsStr:String =
                        "Red Coins: " + main.PlayerData.collectedCoins.length + "\n" +
                        "\nChapter: " + main.PlayerData.currentChapter + "\n" +
                      "\nDeaths: " + main.PlayerData.totalDeaths + "\n" +
                      "\nTime: " + main.PlayerData.formatTime();

        statsText = new FlxText(40, FlxG.height - 250, 0, statsStr);
        statsText.setFormat(null, 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        statsText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        statsText.scrollFactor.set(0, 0);
        statsText.alpha = 0;
        assetsGroup.add(statsText);
    }

    function cleanup():Void
    {
        if (pauseTween != null) pauseTween.cancel();

        for (btn in activeTweens.keys())
        {
            if (activeTweens.get(btn) != null) activeTweens.get(btn).cancel();
        }
        for (txt in activeLabelTweens.keys())
        {
            if (activeLabelTweens.get(txt) != null) activeLabelTweens.get(txt).cancel();
        }
        
        FlxTween.globalManager.cancelTweensOf(pauseText);
        FlxTween.globalManager.cancelTweensOf(respawnBtn);
        FlxTween.globalManager.cancelTweensOf(optionsBtn);
        FlxTween.globalManager.cancelTweensOf(btnTitle);
        FlxTween.globalManager.cancelTweensOf(btnStages);
        FlxTween.globalManager.cancelTweensOf(statsText);

        FlxG.sound.volume = originalVolume;

        FlxG.camera.filters = originalFilters;

        if (uiCamera != null)
        {
            uiCamera.filters = [];
            FlxG.cameras.remove(uiCamera);
        }
        openfl.ui.Mouse.hide();

    }

    override public function destroy():Void
    {
        cleanup();
        super.destroy();
    }

    function setupButtonPosition(btn:FlxButton, xOff:Float, yOff:Float)
    {
        btn.screenCenter();
        btn.x += xOff;
        btn.y += yOff;
        customizeButton(btn);
        add(btn);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (alphaText < 1)
        {
            alphaText += elapsed;
            if (alphaText > 1) alphaText = 1;
        }

        statsText.alpha = alphaText;

        if (!isClosing && bg.alpha < 0.4) bg.alpha += bgFadeTimer;


        if (FlxG.keys.justPressed.ESCAPE && !isClosing)
        {
            isClosing = true;
            setUIEnabled(false);

            FlxG.camera.filters = originalFilters;

            FlxTween.tween(bg, {alpha: 0}, 0.01,
            {
                onComplete: function(_)
                {
                    cleanup();
                    close();
                }
            });
        }
    }

    function clickMainMenu():Void
    {
        if (FlxG.sound.music != null) FlxG.sound.music.stop();        
        cleanup();
        FlxG.switchState(main.MenuState.new);
    }

    function clickRespawn():Void
    {
        main.PlayerData.totalDeaths++;
        cleanup();
        FlxG.resetState();
    }

    function clickStages():Void
    {
        setUIEnabled(false);
        var stageSub = new gui.StageSelectSubState();
        stageSub.cameras = [uiCamera]; 
        stageSub.closeCallback = function() { setUIEnabled(true); };
        openSubState(stageSub);
    }

    function clickOptions():Void
    {
        setUIEnabled(false);
        var optionsSub = new gui.OptionsSubState();
        optionsSub.cameras = [uiCamera];
        optionsSub.closeCallback = function() { setUIEnabled(true); };
        openSubState(optionsSub);
    }

    function setUIEnabled(state:Bool):Void
    {
        assetsGroup.visible = state;
        respawnBtn.visible = state;
        optionsBtn.visible = state;
        btnTitle.visible = state;
        btnStages.visible = state;
        statsText.visible = state;        
        respawnBtn.active = state;
        optionsBtn.active = state;
        btnTitle.active = state;
        btnStages.active = state;
    }

    function customizeButton(btn:FlxButton):Void
    {
        var w:Int = 250;
        var h:Int = 60;
        btn.loadGraphic(AssetPaths.buttonTitle__png, false, w, h);

        if (btn.label != null) 
        {
            btn.label.setFormat(null, 28, FlxColor.WHITE, CENTER);
            btn.label.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
            btn.label.fieldWidth = w;
            for (offset in btn.labelOffsets) { offset.y += 10; }
        }

        btn.onOver.callback = function()
        {
            openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.BUTTON;
            FlxTween.tween(btn.label.scale, {x: 1.1, y: 1.1}, 0.05);
            FlxTween.tween(btn.scale, {x: 1.1, y: 1.1}, 0.05);

            activeTweens.set(btn, FlxTween.angle(btn, -5, 5, 0.6, {type: PINGPONG, ease: FlxEase.sineInOut}));
            activeLabelTweens.set(btn.label, FlxTween.angle(btn.label, -5, 5, 0.6, {type: PINGPONG, ease: FlxEase.sineInOut}));
            FlxG.sound.play(AssetPaths.trigger__ogg, 0.1, false);
        };

        btn.onOut.callback = function()
        {
            openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.ARROW;
            FlxTween.tween(btn.label.scale, {x: 1.0, y: 1.0}, 0.05);
            FlxTween.tween(btn.scale, {x: 1.0, y: 1.0}, 0.05);

            if (activeTweens.exists(btn) && activeTweens.get(btn) != null)
                activeTweens.get(btn).cancel();
            
            if (activeLabelTweens.exists(btn.label) && activeLabelTweens.get(btn.label) != null)
                activeLabelTweens.get(btn.label).cancel();

            btn.angle = 0;
            btn.label.angle = 0;
        };
    }
}