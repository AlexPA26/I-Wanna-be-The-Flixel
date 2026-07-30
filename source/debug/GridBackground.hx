package debug;

import flixel.addons.display.FlxBackdrop;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;

class GridBackground extends FlxGroup
{
    var bgBattle:FlxBackdrop;
    var bgBattle2:FlxBackdrop;

    public function new()
    {
        super();

        bgBattle = new FlxBackdrop(AssetPaths.bgBattle__png, XY, 0, 0);
        bgBattle.scrollFactor.set(0.2, 0.2);
        bgBattle.velocity.set(50, 0);


        bgBattle2 = new FlxBackdrop(AssetPaths.bgBattle__png, XY, 0, 0);
        bgBattle2.scrollFactor.set(0.2, 0.2);
        bgBattle2.velocity.set(60, 30);

        add(bgBattle2);
        add(bgBattle);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        bgBattle.alpha = 0.2 - Math.random() * 0.2;
        bgBattle2.alpha = 0.1 - Math.random() * 0.2;
    }
}