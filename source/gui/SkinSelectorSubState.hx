package gui;

import main.mods.ModLoader;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import main.PlayerData;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import openfl.display.BitmapData;

typedef SkinData =
{
    var name:String;
    var assetName:String;
    var unlockAt:Int;
    @:optional var milestone:String;
}

class SkinSelectorSubState extends FlxSubState
{
    var assetsGroup:FlxGroup;
    var skinPreview:FlxSprite;
    var skinNameText:FlxText;
    var unlockText:FlxText;
    var coinCountText:FlxText;
    var applyBtn:FlxButton;
    var skinEmitter:FlxEmitter;
    
    var skins:Array<SkinData> =
    [
        {name: "The Kid", assetName: "thekid", unlockAt: 0},
        {name: "Ginger", assetName: "ginger", unlockAt: 0, milestone: "sewers"},
        {name: "Toxic Boy", assetName: "toxickid", unlockAt: 0, milestone: "morning"},
        {name: "Boyfriend", assetName: "boyfriend", unlockAt: 5},
        {name: "Boshy", assetName: "boshy", unlockAt: 10},
        {name: "The Kris", assetName: "thekris", unlockAt: 15},

    ];
    
    var curSelected:Int = 0;
    var closeBoton:FlxSprite;

    override public function create()
    {
        openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.ARROW;

        super.create();
        assetsGroup = new FlxGroup();

        var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0.6;
        assetsGroup.add(bg);

        var bgOption = new FlxSprite();
        bgOption.loadGraphic(AssetPaths.OptionBG__png);
        bgOption.alpha = 0.85;
        bgOption.screenCenter();
        assetsGroup.add(bgOption);

        var title = new FlxText(0, 80, FlxG.width, "Personalize");
        title.setFormat(null, 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        FlxTween.tween(title, {y: title.y - 3}, 0.8, {type: PINGPONG, ease: FlxEase.sineInOut});
        assetsGroup.add(title);

        coinCountText = new FlxText(0, 175, FlxG.width, "Red Coins: " + PlayerData.collectedCoins.length);
        coinCountText.setFormat(null, 24, FlxColor.RED, CENTER, OUTLINE, FlxColor.BLACK);
        assetsGroup.add(coinCountText);

        skinPreview = new FlxSprite().makeGraphic(50, 50, FlxColor.TRANSPARENT);
        skinPreview.scale.set(4, 4);
        skinPreview.screenCenter();
        skinPreview.y = skinPreview.y - 50;

        skinEmitter = new FlxEmitter();
        skinEmitter.x = skinPreview.x + skinPreview.width / 2;
        skinEmitter.y = skinPreview.y + skinPreview.height + 20;

        assetsGroup.add(skinEmitter);
        assetsGroup.add(skinPreview);



        skinNameText = new FlxText(0, 450, FlxG.width, "");
        skinNameText.setFormat(null, 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        assetsGroup.add(skinNameText);

        unlockText = new FlxText(0, 500, FlxG.width, "");
        unlockText.setFormat(null, 20, FlxColor.RED, CENTER);
        assetsGroup.add(unlockText);

        applyBtn = new FlxButton(0, 550, "Apply", clickApply);
        setupButtonStyle(applyBtn);
        applyBtn.screenCenter(X);
        assetsGroup.add(applyBtn);

        closeBoton = new FlxSprite();
        closeBoton.loadGraphic(AssetPaths.menuClose__png, true, 63, 63);
        closeBoton.animation.add("normal", [0], 1, false);
		closeBoton.animation.add("active", [1], 1, false);
        closeBoton.screenCenter();
        closeBoton.y -= 265;
        closeBoton.x += 520;
        assetsGroup.add(closeBoton);

        add(assetsGroup);

        for (i in 0...skins.length)
        {
            if (skins[i].assetName == PlayerData.currentSkin) curSelected = i;
        }

        updateSelection();

    }

    function updateSelection()
    {
        var skin = skins[curSelected];
        var isUnlocked:Bool = false;
        if (skin.milestone != null)
        {
            if (skin.milestone == "sewers") isUnlocked = PlayerData.reachedSewers;
            if (skin.milestone == "morning") isUnlocked = PlayerData.reachedMorning;
        }
        else
        {
            isUnlocked = PlayerData.collectedCoins.length >= skin.unlockAt;
        }

        skinNameText.text = skin.name;

        ModLoader.loadModGraphic(skinPreview, "images/skins/" + skin.assetName + ".png", "skin_" + skin.assetName, 50, 50);
        skinPreview.animation.add("idle", [0, 1, 2, 3], 11, true);
        skinPreview.animation.play("idle");

        skinEmitter.x = skinPreview.x + skinPreview.width / 2;
        skinEmitter.y = skinPreview.y + skinPreview.height + 15;

        if (isUnlocked)
        {
            skinEmitter.visible = true;
            skinPreview.color = FlxColor.WHITE;
            unlockText.text = "UNLOCKED";
            unlockText.color = FlxColor.LIME;
            applyBtn.visible = true;
            
            if (PlayerData.currentSkin == skin.assetName)
            {
                applyBtn.label.text = "EQUIPPED";
                applyBtn.active = false;
                applyBtn.alpha = 0.6;
            }
            else
            {
                applyBtn.label.text = "APPLY";
                applyBtn.active = true;
                applyBtn.alpha = 1.0;
            }
        }
        else
        {
            skinPreview.color = FlxColor.BLACK;

            if (skin.milestone == "sewers")
            {
                unlockText.text = "Reach the Sewers";
            }

            else if (skin.milestone == "morning")
            {
                unlockText.text = "Exit the Sewers";
            }

            else
            {
                unlockText.text = "Locked: Need " + skin.unlockAt + " Coins";
            }
                
            unlockText.color = FlxColor.RED;
            applyBtn.visible = false;
            skinEmitter.visible = false;
        }

        switch (skins[curSelected].assetName)
        {
            case "thekid":
                skinEmitter.color.set(FlxColor.BLUE, FlxColor.RED, FlxColor.BLUE, FlxColor.WHITE);
                setupParticles();
            case "ginger":
                skinEmitter.color.set(FlxColor.ORANGE, FlxColor.YELLOW, FlxColor.ORANGE, FlxColor.WHITE);
                setupParticles();
            case "toxickid":
                skinEmitter.color.set(FlxColor.GREEN, FlxColor.LIME, FlxColor.YELLOW, FlxColor.GREEN);
                setupParticles();
            case "boyfriend":
                skinEmitter.color.set(FlxColor.BLUE, FlxColor.RED, FlxColor.BLUE, FlxColor.RED);
                setupParticles();
            case "boshy":
                skinEmitter.color.set(FlxColor.YELLOW, FlxColor.YELLOW, FlxColor.WHITE);
                setupParticles();
            default:
                skinEmitter.color.set(FlxColor.WHITE);
                setupParticles();

        }

        if (!skinEmitter.emitting && isUnlocked) 
        {
            skinEmitter.start(true, 0.02);

        }
    
    }

    function clickApply()
    {
        var skin = skins[curSelected];
        PlayerData.currentSkin = skin.assetName;
        
        FlxG.sound.play(AssetPaths.trigger__ogg, 0.3);
        updateSelection();
        leveldata.misc.SaveManager.saveGame();
    }

    function setupButtonStyle(btn:FlxButton)
    {
        btn.loadGraphic(AssetPaths.buttonTitle__png, false, 250, 60); 
        btn.label.setFormat(null, 24, FlxColor.WHITE, CENTER);
        btn.label.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        for (offset in btn.labelOffsets) { offset.y += 10; }
    }

    function setupParticles():Void
    {
        skinEmitter.makeParticles(5, 5, FlxColor.WHITE, 50);
        skinEmitter.lifespan.set(0.25, 0.5);
        skinEmitter.speed.set(200, 500);
        skinEmitter.launchMode = CIRCLE;
        skinEmitter.acceleration.set(0, 0); 
        skinEmitter.drag.set(40, 40);
        skinEmitter.angularVelocity.set(-300, 300);
    }
    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        #if !mobile

        if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A)
        {
            curSelected--;
            if (curSelected < 0) curSelected = skins.length - 1;
            updateSelection();
        }
        if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D)
        {
            curSelected++;
            if (curSelected >= skins.length) curSelected = 0;
            updateSelection();
        }

        if (FlxG.mouse.overlaps(closeBoton))
        {
            openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.BUTTON;
            closeBoton.animation.play("active");
            if (FlxG.mouse.justPressed) close();
        }
        else
        {
            if (!FlxG.mouse.overlaps(applyBtn)) openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.ARROW;
            closeBoton.animation.play("normal");
        }


        if (FlxG.keys.justPressed.ESCAPE)
        {
            openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.ARROW;
            close();
        }

        #end
    }
}