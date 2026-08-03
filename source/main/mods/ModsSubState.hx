package main.mods;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ui.FlxButton;
import openfl.display.BitmapData;
import haxe.io.Path;
import haxe.Json;

#if sys
import sys.FileSystem;
import haxe.Json;
import sys.io.File;
#end

class ModsSubState extends FlxSubState
{
    #if !mobile
    var assetsGroup:FlxGroup;
    var bgOption:FlxSprite;
    var title:FlxText;
    var closeBoton:FlxSprite;
    var previewSprite:FlxSprite;
    var metadataText:FlxText;
    
    var modsList:Array<String> = [];
    var modTexts:Array<FlxText> = [];
    var currentHoveredIndex:Int = -1;

    override public function create()
    {
        openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.ARROW;

        super.create();
        assetsGroup = new FlxGroup();

        var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0.6;
        assetsGroup.add(bg);

        bgOption = new FlxSprite();
        bgOption.loadGraphic(AssetPaths.OptionBG__png);
        bgOption.alpha = 0.85;
        bgOption.screenCenter();
        assetsGroup.add(bgOption);

        title = new FlxText(0, 80, FlxG.width, "Loaded Mods");
        title.setFormat(null, 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        assetsGroup.add(title);

        closeBoton = new FlxSprite();
        closeBoton.loadGraphic(AssetPaths.menuClose__png, true, 63, 63);
        closeBoton.animation.add("normal", [0], 1, false);
        closeBoton.animation.add("active", [1], 1, false);
        closeBoton.screenCenter();
        closeBoton.y -= 265;
        closeBoton.x += 520;
        assetsGroup.add(closeBoton);

        previewSprite = new FlxSprite();
        previewSprite.makeGraphic(300, 300, FlxColor.TRANSPARENT);
        assetsGroup.add(previewSprite);

        metadataText = new FlxText(0, 0, 300, "");
        metadataText.setFormat(null, 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        assetsGroup.add(metadataText);

        #if sys
        var modsPath = Path.normalize(Sys.getCwd() + "../../../mods");
        
        if (FileSystem.exists(modsPath))
        {
            for (mod in FileSystem.readDirectory(modsPath))
            {
                if (mod.charAt(0) == ".") continue;
                var root = modsPath + "/" + mod + "/assets";
                if (FileSystem.exists(root))
                {
                    modsList.push(mod);
                }
            }
        }
        #end

        var startX = bgOption.x + 80;
        var startY = bgOption.y + 160;
        var spacingY = 42;

        for (i in 0...modsList.length)
        {
            var txt = new FlxText(startX, startY + (i * spacingY), 450, modsList[i]);
            txt.setFormat(null, 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
            assetsGroup.add(txt);
            modTexts.push(txt);
        }

        add(assetsGroup);

        updatePreviewImage("");
    }

    function updatePreviewImage(modName:String):Void
    {
        var loaded = false;
        var authorName:String = "Unknown";
        var versionName:String = "-";

        #if sys
        if (modName != "")
        {
            var modsPath = Path.normalize(Sys.getCwd() + "../../../mods");
            var iconPath = modsPath + "/" + modName + "/mod-icon.png";
            var jsonPath = modsPath + "/" + modName + "/metadata.json";
            
            if (FileSystem.exists(iconPath))
            {
                var bmp = BitmapData.fromFile(iconPath);
                if (bmp != null)
                {
                    previewSprite.loadGraphic(bmp);
                    loaded = true;
                }
            }

            if (FileSystem.exists(jsonPath))
            {
                try
                {
                    var jsonString = File.getContent(jsonPath);
                    var rawData:Dynamic = Json.parse(jsonString);
                    
                    if (rawData.author != null) authorName = rawData.author;
                    if (rawData.version != null) versionName = rawData.version;
                }
                catch(e:Dynamic)
                {
                    trace("No metadata.json found: " + e);
                }
            }
        }
        #end

        if (!loaded)
        {
            var fallbackPath = "C:\\HaxeFlixel\\IWBTF\\assets\\images\\title\\thumbnails\\thumbnail_default.png";
            #if sys
            if (FileSystem.exists(fallbackPath))
            {
                var bmp = BitmapData.fromFile(fallbackPath);
                if (bmp != null)
                {
                    previewSprite.loadGraphic(bmp);
                    loaded = true;
                }
            }
            #end
        }

        if (!loaded)
        {
            previewSprite.makeGraphic(300, 300, FlxColor.GRAY);
        }

        previewSprite.setGraphicSize(300, 300);
        previewSprite.updateHitbox();
        previewSprite.x = bgOption.x + bgOption.width - 380;
        previewSprite.y = bgOption.y + 130;

        if (modName == "")
        {
            metadataText.text = "";
        }
        else
        {
            metadataText.text = "Created by " + authorName + "\nVersion: " + versionName;
        }

        metadataText.x = previewSprite.x;
        metadataText.y = previewSprite.y + previewSprite.height + 20;
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        var anyHovered = false;
        
        for (i in 0...modTexts.length)
        {
            var txt = modTexts[i];
            if (FlxG.mouse.overlaps(txt))
            {
                anyHovered = true;
                txt.color = FlxColor.YELLOW;
                openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.BUTTON;
                
                if (currentHoveredIndex != i)
                {
                    currentHoveredIndex = i;
                    updatePreviewImage(modsList[i]);
                }
            }
            else
            {
                txt.color = FlxColor.WHITE;
            }
        }

        if (FlxG.mouse.overlaps(closeBoton))
        {
            openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.BUTTON;
            closeBoton.animation.play("active");
            if (FlxG.mouse.justPressed)
            {
                openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.ARROW;
                close();
            }
        }
        else
        {
            if (!anyHovered) openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.ARROW;
            closeBoton.animation.play("normal");
        }

        if (FlxG.keys.justPressed.ESCAPE)
        {
            openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.ARROW;
            close();
        }
    }
    #end
}