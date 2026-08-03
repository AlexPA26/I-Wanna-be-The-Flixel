package leveldata.misc;

import flixel.util.FlxColor;
import flixel.effects.particles.FlxEmitter;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;

class InvisWarp extends FlxSprite
{
    public function new(width:Int, height:Int)
    {
        super();

        makeGraphic(width, height, FlxColor.TRANSPARENT, false);

        origin.set(width / 2, height / 2);
    }
}