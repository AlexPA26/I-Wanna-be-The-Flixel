package leveldata.blockdata;

import flixel.FlxSprite;

class InvisibleBlock extends FlxSprite
{
    public function new(X:Float, Y:Float, TileID:Int)
    {
        super(X, Y);
        loadGraphic(AssetPaths.ch1tiles__png, true, 50, 50);
        animation.frameIndex = TileID;
        immovable = true;
        alpha = 0; 
    }
}
