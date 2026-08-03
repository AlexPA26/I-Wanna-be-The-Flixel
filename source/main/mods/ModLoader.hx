package main.mods;

import haxe.ds.StringMap;

#if sys
import sys.FileSystem;
import haxe.io.Path;
#end

class ModLoader
{
    public static var overrides:StringMap<String> = new StringMap();
    
    public static function init()
    {

        overrides.clear();
        #if !html5
        var modsPath = Path.normalize(Sys.getCwd() + "../../../mods");
        trace("Default folder: " + Sys.getCwd());
        trace("Mods folder exists?: " + FileSystem.exists(modsPath));
        trace("Mods folder Path: " + modsPath);

        if (!FileSystem.exists(modsPath))
        {
            return;
        }
            
        trace("Scanning mods...");

        for (mod in FileSystem.readDirectory(modsPath))
        {
            if (mod.charAt(0) == ".") continue;
            
            trace("Found mod: " + mod);

            var root = modsPath + "/" + mod + "/assets";
            trace("Root: " + root);
            trace("Root exists: " + FileSystem.exists(root));

            if (FileSystem.exists(root))
            {
                scanFolder(root, root);
            }
                
        }
        #end
    }

    static function scanFolder(folder:String, root:String)
    {
        #if sys
        for (file in FileSystem.readDirectory(folder))
        {
            var full = folder + "/" + file;

            if (FileSystem.isDirectory(full))
            {
                scanFolder(full, root);
            }
            else
            {
                var relative = full.substr(root.length + 1);
                trace("Registering: " + relative + " -> " + full);

                overrides.set(relative, full);

                trace("Registered override: " + relative);
            }
        }
        #end
    }

    public static function getAsset(path:String):String
    {
        if (overrides.exists(path))
        {
            return overrides.get(path);
        }
            
        return "assets/" + path;
    }

    public static function loadModGraphic(sprite:flixel.FlxSprite, relativePath:String, cacheKey:String, frameWidth:Int = 50, frameHeight:Int = 50):Void
    {
        #if sys
        if (overrides.exists(relativePath))
        {
            var modPath = overrides.get(relativePath);
            var bmp = openfl.display.BitmapData.fromFile(modPath);
            if (bmp != null)
            {
                var graphic = flixel.graphics.FlxGraphic.fromBitmapData(bmp, false, cacheKey, false);
                sprite.loadGraphic(graphic, true, frameWidth, frameHeight);
                return;
            }
        }
        #end
        sprite.loadGraphic("assets/" + relativePath, true, frameWidth, frameHeight);
    }

    public static function playModMusic(relativePath:String, volume:Float = 1.0, looped:Bool = true):Void
    {
        #if sys
        if (overrides.exists(relativePath))
        {
            var modPath = overrides.get(relativePath);
            var sound = openfl.media.Sound.fromFile(modPath);
            if (sound != null)
            {
                flixel.FlxG.sound.playMusic(sound, volume, looped);
                return;
            }
        }
        #end
        
        flixel.FlxG.sound.playMusic("assets/" + relativePath, volume, looped);
    }
}