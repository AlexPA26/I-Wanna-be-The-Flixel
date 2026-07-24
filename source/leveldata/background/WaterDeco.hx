package leveldata.background;

import flixel.addons.display.FlxBackdrop;
import flixel.FlxG;

class WaterDeco extends FlxBackdrop
{
    public function new(scrollSpeed:Float = -20)
    {
        super(AssetPaths.waterDeco__png, X, 0, 0);
        y = FlxG.height - 96;
        velocity.x = scrollSpeed;
        scrollFactor.set(0, 0);
        immovable = true;
    }
}