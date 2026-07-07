package main.bosses.ch1;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.math.FlxVelocity;

class JevilBullet extends FlxSprite
{
    public function new(x:Float, y:Float)
    {
        super(x, y);
        loadGraphic(AssetPaths.jevil_bullets__png, true, 20, 20);
        immovable = true;
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        if (!isOnScreen()) kill();
    }
}

class JevilScythe extends JevilBullet
{
    public function new(x:Float, y:Float)
    {
        super(x, y);
        loadGraphic(AssetPaths.jevil_scythe__png);
        velocity.y = 900;
        angularVelocity = 500;
    }
}