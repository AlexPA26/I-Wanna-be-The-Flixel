package gui;

import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class OptionsSubState extends FlxSubState
{
    var bg:FlxSprite;
    var buttonFullScreen:FlxSprite;
    var bgFadeTimer:Float = 0.025;
    var closeBoton = new FlxSprite();
    var assetsGroup:FlxGroup;
    var btnAnti:FlxSprite;
    var btnSync:FlxSprite;
    var btnFPS:FlxSprite;
    var buttonEnhancedVisuals:FlxSprite;
    
    override public function create()
    {
        var bgOption = new FlxSprite();
        var bgShader = new FlxSprite();
        var mainText = new FlxText();
        var fullScreenText = new FlxText();
        var enhancedVisualsText = new FlxText();

        super.create();

        openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.ARROW;

        assetsGroup = new FlxGroup();

        bg = new FlxSprite();
        bg.makeGraphic(1300,800, FlxColor.BLACK, false);
        bg.screenCenter();
        bg.alpha = 0;
        assetsGroup.add(bg);

        bgOption.loadGraphic(AssetPaths.OptionBG__png, false);
        bgOption.screenCenter();
        bgOption.alpha = 0.85;
        assetsGroup.add(bgOption);

        bgShader.makeGraphic(1150, 630, FlxColor.BLACK);
        bgShader.screenCenter();
        bgShader.alpha = 0.5;
        assetsGroup.add(bgShader);

        closeBoton.loadGraphic(AssetPaths.menuClose__png, true, 63, 63);
		closeBoton.animation.add("normal", [0], 1, false);
		closeBoton.animation.add("active", [1], 1, false);
        closeBoton.screenCenter();
        closeBoton.y -= 265;
        closeBoton.x += 520;
        assetsGroup.add(closeBoton);

        buttonFullScreen = new FlxSprite();
        buttonFullScreen.loadGraphic(AssetPaths.checkOptions__png, true, 64, 64);
        buttonFullScreen.animation.add("normal", [0], 1, false);
        buttonFullScreen.animation.add("active", [1], 1, false);
        buttonFullScreen.animation.play("normal");
        buttonFullScreen.screenCenter();
        buttonFullScreen.x -= 450;
        buttonFullScreen.y -= 100;
        assetsGroup.add(buttonFullScreen);

        fullScreenText.setFormat(null, 32, FlxColor.WHITE);
        fullScreenText.text = "Fullscreen";
        fullScreenText.screenCenter();
        fullScreenText.x -= 300;
        fullScreenText.y -= 100;
        assetsGroup.add(fullScreenText);

        buttonEnhancedVisuals = new FlxSprite();
        buttonEnhancedVisuals.loadGraphic(AssetPaths.checkOptions__png, true, 64, 64);
        buttonEnhancedVisuals.animation.add("normal", [0], 1, false);
        buttonEnhancedVisuals.animation.add("active", [1], 1, false);
        buttonEnhancedVisuals.animation.play(main.PlayerData.enhancedVisuals ? "active" : "normal");
        buttonEnhancedVisuals.screenCenter();
        buttonEnhancedVisuals.x -= 450;
        buttonEnhancedVisuals.y = buttonFullScreen.y + 100;
        assetsGroup.add(buttonEnhancedVisuals);

        enhancedVisualsText.setFormat(null, 32, FlxColor.WHITE);
        enhancedVisualsText.text = "Enhanced Visuals";
        enhancedVisualsText.screenCenter();
        enhancedVisualsText.x -= 225;
        enhancedVisualsText.y = fullScreenText.y + 100;
        assetsGroup.add(enhancedVisualsText);

        mainText = new FlxText("Options");
		mainText.size = 80;
		mainText.color = FlxColor.WHITE;
		mainText.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
		mainText.screenCenter();
		mainText.y -= 240;
        mainText.scrollFactor.set(0, 0);
        FlxTween.tween(mainText, {y: mainText.y - 3}, 0.8, {type: PINGPONG, ease: FlxEase.sineInOut});
		assetsGroup.add(mainText);
        add(assetsGroup);
        
        
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (bg.alpha < 0.65)
        {
            bg.alpha += bgFadeTimer;
        }

        #if !mobile

        if (FlxG.mouse.overlaps(closeBoton))
        {
            closeBoton.animation.play("active");
        }
        else
        {
            closeBoton.animation.play("normal");
        }

        if ((FlxG.mouse.overlaps(closeBoton) && FlxG.mouse.justPressed) || FlxG.keys.justPressed.ESCAPE)
        {   
            remove(assetsGroup, true);
            openfl.ui.Mouse.show();
            FlxG.camera.filters = [];
            close();
            return;
        }
        
        fullScreenButton();
        enhancedVisualsLogic();

        if (FlxG.mouse.overlaps(closeBoton) || FlxG.mouse.overlaps(buttonFullScreen) || FlxG.mouse.overlaps(buttonEnhancedVisuals))
        {
            openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.BUTTON;
        }
        else
        {
            openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.ARROW;
        }
        #end
    }

    function fullScreenButton():Void
    {
        if (FlxG.fullscreen) buttonFullScreen.animation.play("active");
        else buttonFullScreen.animation.play("normal");

        #if !mobile
        if (FlxG.mouse.overlaps(buttonFullScreen) && (FlxG.mouse.justPressed))
        {   
            if (FlxG.fullscreen == false)
            {
                FlxG.fullscreen = true;
                buttonFullScreen.animation.play("active");
            }
            else 
            {
                FlxG.fullscreen = false;
                buttonFullScreen.animation.play("normal");
            }
        }
        #end
    }

    function enhancedVisualsLogic():Void
    {
        #if !mobile
        if (FlxG.mouse.overlaps(buttonEnhancedVisuals) && (FlxG.mouse.justPressed))
        {   
            main.PlayerData.enhancedVisuals = !main.PlayerData.enhancedVisuals;
            buttonEnhancedVisuals.animation.play(main.PlayerData.enhancedVisuals ? "active" : "normal");
        }
        #end
    }


}