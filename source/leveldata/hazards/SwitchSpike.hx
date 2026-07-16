package leveldata.hazards;

import flixel.util.FlxTimer;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class SwitchSpike extends FlxSprite
{
    public static var allSpikes:Array<SwitchSpike> = [];
    public static var spikesCurrentlyShifted:Bool = false;

    public var homeX:Float;
    public var homeY:Float;
    public var shiftedX:Float;
    public var shiftedY:Float;
    public var invertToggle:Bool = false;

    var activeTween:FlxTween;
    var autoSpike:Bool;
    static var speed:Float;
    static var autoShifted = false;
    static var autoTimer:FlxTimer;

    public function new(X:Float, Y:Float, LocalID:Int, status:String = "disabled", movement:Int, auto:Bool, autoSpeed:Float)
    {
        super(X, Y);
        loadGraphic(AssetPaths.spikes__png, true, 50, 50);
        animation.frameIndex = LocalID;

        width = movement;
        autoSpike = auto;

        if (autoSpike && autoTimer == null)
        {
            SwitchSpike.speed = autoSpeed;
        }

        height = movement;
        offset.set(0, 0);

        homeX = x;
        homeY = y;
        shiftedX = homeX;
        shiftedY = homeY;

        switch (LocalID)
        {
            case 0, 4: shiftedY += movement; // Down
            case 1, 5: shiftedX -= movement; // Left
            case 2, 6: shiftedY -= movement; // Up
            case 3, 7: shiftedX += movement; // Right
        }

        immovable = true;

        if (status == "active")
        {
            invertToggle = true; 
            x = shiftedX;
            y = shiftedY;
        }

        if (allSpikes.indexOf(this) == -1)
        {
            allSpikes.push(this);
        }

        if (autoSpike)
        {
            startAuto();
        }
    }

    public function toggle(globalShifted:Bool):Void
    {
        var shouldBeRetracted = invertToggle ? !globalShifted : globalShifted;
        var startX = x;
        var startY = y;
        var destX = shouldBeRetracted ? shiftedX : homeX;
        var destY = shouldBeRetracted ? shiftedY : homeY;

        if (activeTween != null) activeTween.cancel();

        activeTween = FlxTween.num(0.0, 1.0, 0.15, {ease: FlxEase.linear}, function(v:Float)
        {
            x = startX + (destX - startX) * v;
            y = startY + (destY - startY) * v;
        });
    }

    public static function toggleAll():Void
    {
        spikesCurrentlyShifted = !spikesCurrentlyShifted;
        for (spike in allSpikes)
        {
            if (spike != null && spike.exists && spike.alive && !spike.autoSpike)
                    spike.toggle(spikesCurrentlyShifted);
        }
    }

    public static function startAuto():Void
    {
        if (Math.isNaN(speed) || speed <= 0)
        {
            speed = 1.5;
        }
        
        if (autoTimer != null) return;

        autoTimer = new FlxTimer().start(speed, function(t)
        {
            autoShifted = !autoShifted;

            for (spike in allSpikes)
            {
                if (spike.autoSpike)
                    spike.toggle(autoShifted);
            }

            t.reset(speed);
        });
    }

    public static function clear():Void
    {
        if (autoTimer != null)
        {
            autoTimer.cancel();
            autoTimer = null;
        }
        allSpikes = [];
        spikesCurrentlyShifted = false;
        autoShifted = false;
    }

    override public function destroy():Void
    {
        if (activeTween != null) activeTween.cancel();
        allSpikes.remove(this);
        super.destroy();
    }
}