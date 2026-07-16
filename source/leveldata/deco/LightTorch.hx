package leveldata.deco;

import flixel.FlxSprite;
import openfl.display.BlendMode;

class LightTorch extends FlxSprite
{
    public function new(x:Float, y:Float, color)
    {
        super(x, y);
        loadGraphic(AssetPaths.light__png, true, 200, 200);
        animation.add("orange", [0], 0, false);
        animation.add("blue", [1], 0, false);
        animation.play(color);
        offset.set(-100, -100);
        this.blend = BlendMode.ADD;
        immovable = true;
    }

    override function update(elapsed:Float):Void
        {
            super.update(elapsed);
            alpha = 0.525 - Math.random() * 0.2;
    }

}