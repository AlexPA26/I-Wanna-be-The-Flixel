package leveldata.misc;

import flixel.FlxObject;
import flixel.FlxG;
import flixel.util.FlxDirectionFlags;

class PlatformRider
{
    /**
     * Call this once per platform per frame, AFTER you've already repositioned
     * the platform for this frame (teleported it, or let velocity/super.update()
     * move it — doesn't matter which).
     *
     * @param rider     The player (or whatever should be carried).
     * @param platform  The platform, already moved to its new position this frame.
     * @param oldX      The platform's x BEFORE this frame's movement.
     * @param oldY      The platform's y BEFORE this frame's movement.
     */
    public static function moveAndCarry(rider:FlxObject, platform:FlxObject, oldX:Float, oldY:Float):Void
    {
        var deltaX = platform.x - oldX;
        var deltaY = platform.y - oldY;

        rider.touching = FlxDirectionFlags.NONE;

        FlxG.collide(rider, platform);

        if (rider.isTouching(FlxDirectionFlags.FLOOR))
        {
            rider.x += deltaX;
            rider.y += deltaY;
        }
    }
}
