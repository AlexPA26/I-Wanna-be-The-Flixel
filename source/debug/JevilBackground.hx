package debug;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import flixel.FlxState;

class JevilBackground extends FlxGroup
{
    var scanline:FlxBackdrop;
    var scanline2:FlxBackdrop;
    var bg:FlxSprite;

    public function new(alpha)
    {
        super();

        bg = new FlxSprite();
        bg.makeGraphic(1280, 720, 0xFF62A1FF, false);
        bg.screenCenter();
        bg.alpha = alpha - 0.3;
        add(bg);

        scanline = new FlxBackdrop(AssetPaths.scanline__png, Y);
        scanline.scale.set(2, 2);
        add(scanline);

        scanline2 = new FlxBackdrop(AssetPaths.scanline__png, Y);
        scanline2.scale.set(2, 4);
        scanline2.alpha = 0.25;
        add(scanline2);
    }

    override public function update(elapsed:Float):Void
    {
        scanline.alpha = 0.1 - (Math.random() * 0.05);
        scanline2.alpha = 0.1 - (Math.random() * 0.1);

        scanline.y += 20 * elapsed;
        scanline2.y += 40 * elapsed;
    }

}