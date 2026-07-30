package main;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;

class CacheState extends FlxState
{
    var bg:FlxSprite;
    var player:FlxSprite;
    var scanline:FlxBackdrop;
    var scanline2:FlxBackdrop;
    var vignite:FlxSprite;
    var fade:FlxSprite;
    var finishedCaching:Bool = false;

    var progressBar:FlxBar;
    var loadingText:FlxText;

    var cacheTasks:Array<Void->Void> = [];
    var currentTask:Int = 0;

    static var BAR_COLORS:Array<FlxColor> = [FlxColor.RED, FlxColor.CYAN, FlxColor.BLUE, FlxColor.GREEN, FlxColor.YELLOW];

    override public function create():Void
    {
        super.create();

        #if !debug
		#if !mobile
		FlxG.mouse.visible = false;
		#end
		#end

        bg = new FlxSprite();
        bg.makeGraphic(1280, 720, 0xFF62A1FF, false);
        bg.screenCenter();
        bg.alpha = 0.3;
        add(bg);

        scanline = new FlxBackdrop(AssetPaths.scanline__png, Y);
        scanline.velocity.set(0, 40);
        scanline.scrollFactor.set(0, 0);
        scanline.alpha = 0.1;
        add(scanline);

        scanline2 = new FlxBackdrop(AssetPaths.scanline__png, Y);
        scanline2.velocity.set(0, 40);
        scanline2.scrollFactor.set(0, 0);
        scanline2.alpha = 0.05;
        scanline2.y = 10;
        add(scanline2);

        player = new FlxSprite();
        main.mods.ModLoader.loadModGraphic(player, "images/skins/" + PlayerData.currentSkin + ".png", "skin_" + PlayerData.currentSkin, 50, 50);
        player.animation.add("walking", [8, 9, 10, 11, 12, 13], 14, true);
        player.animation.add("idle", [0, 1, 2, 3], 11, true);
        player.animation.play("idle");
        player.scale.set(3, 3);
        player.updateHitbox();
        player.screenCenter();
        player.y -= 50;

        add(player);

        vignite = new FlxSprite();
        vignite.loadGraphic(AssetPaths.vigniteTitle__png, false);
        vignite.scrollFactor.set(0, 0);
        vignite.screenCenter();
        vignite.alpha = 0.65;
        add(vignite);

        loadingText = new FlxText(0, FlxG.height - 130, FlxG.width, "Initializing Assets...", 24);
        loadingText.setFormat(null, 24, FlxColor.WHITE, CENTER);
        loadingText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        add(loadingText);

        FlxTween.tween(loadingText, {y: loadingText.y - 6}, 0.9, {type: PINGPONG, ease: FlxEase.sineInOut});

        var barColor:FlxColor = BAR_COLORS[FlxG.random.int(0, BAR_COLORS.length - 1)];

        progressBar = new FlxBar((FlxG.width - 600) / 2, FlxG.height - 80, LEFT_TO_RIGHT, 600, 20, this, "currentTask", 0, 100);
        progressBar.createFilledBar(0xFF1F1A24, barColor, true, 0xFF000000);
        add(progressBar);

        fade = new FlxSprite().makeGraphic(1280, 720, FlxColor.BLACK);
        fade.scrollFactor.set();
        fade.alpha = 0;
        add(fade);

        queueBitmap(AssetPaths.save__png);
        queueBitmap(AssetPaths.haxeflixelLogo__png);
        queueBitmap(AssetPaths.logo__png);
        queueBitmap(AssetPaths.playerGlow__png);
		queueBitmap(AssetPaths.ch0tiles__png);
        queueBitmap(AssetPaths.ch1tiles__png);

        queueSound(AssetPaths.jump__ogg);
        queueSound(AssetPaths.doublejump__ogg);
        queueSound(AssetPaths.playershoot__ogg);
        queueSound(AssetPaths.break_block__ogg);
        queueSound(AssetPaths.savedgame__ogg);
        queueSound(AssetPaths.death_bgm__ogg);

        queueSound(AssetPaths.tutorial__ogg);
        queueSound(AssetPaths.jevil_fight__ogg);
        queueSound(AssetPaths.reznor_fight__ogg);
        queueSound(AssetPaths.castle_underground__ogg);
        queueSound(AssetPaths.castle1__ogg);
        queueSound(AssetPaths.rain__ogg);
        queueSound(AssetPaths.death_bgm__ogg);

        queueSound(AssetPaths.mainMenu__ogg);
        queueSound(AssetPaths.beep__ogg);

        progressBar.setRange(0, cacheTasks.length);
    }

    inline function queueBitmap(path:String):Void
    {
        cacheTasks.push(function()
        {
            loadingText.text = "Caching Images...";
            FlxG.bitmap.add(path);
        });
    }

    inline function queueSound(path:String):Void
    {
        cacheTasks.push(function()
        {
            loadingText.text = "Caching Music...";
            FlxG.sound.cache(path);
        });
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (currentTask < cacheTasks.length)
        {
            cacheTasks[currentTask]();
            currentTask++;
        }
        else if (!finishedCaching)
        {
            finishedCaching = true;
            player.animation.play("walking");
            player.velocity.x = 600;

            FlxTween.tween(fade, {alpha: 1}, 1.5,
            {
                ease: FlxEase.quadOut
            });

            new FlxTimer().start(2, function(_)
            {
                var hasSave:Bool = leveldata.misc.SaveManager.loadGame();

                if (!hasSave || PlayerData.currentRoom == null || PlayerData.currentRoom == "")
                {
                    PlayerData.currentChapter = 0;
                    PlayerData.currentRoom = "map01";
                    PlayerData.spawnX = 250; // Initial tutorial spawn X
                    PlayerData.spawnY = 450; // Initial tutorial spawn Y
                }

                if (PlayerData.tutorialCompleted == false)
                {
                    FlxG.switchState(ChapterState.new);
                }

                else
                {
                    FlxG.switchState(MenuState.new);
                }
            });
        }

		scanline.alpha = 0.1 - (Math.random() * 0.05);
        scanline2.alpha = 0.1 - (Math.random() * 0.1);
    }
}
