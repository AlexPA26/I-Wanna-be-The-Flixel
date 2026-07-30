package main.bosses.ch1;

import flixel.FlxG;
import flixel.addons.effects.FlxTrail;
import flixel.FlxSprite;
import main.ChapterState;

class ReznorFlame extends FlxSprite
{
    public var trail:FlxTrail;
    var parentState:ChapterState;

    public function new(spawnX:Float, spawnY:Float, targetX:Float, targetY:Float, stateRef:ChapterState)
    {
        super(spawnX, spawnY);
        this.parentState = stateRef;

        loadGraphic(AssetPaths.reznor_flames__png, true, 64, 32);
        flipX = true;
        animation.add("burn", [0, 1], 12, true);
        animation.play("burn");

        var angle = Math.atan2(targetY - spawnY, targetX - spawnX);
        var speed = 600; 
        velocity.x = Math.cos(angle) * speed;
        velocity.y = Math.sin(angle) * speed;
        
        flipX = velocity.x < 0; 

        trail = new FlxTrail(this, null, 12, 2, 0.25, 0.05);
        parentState.eventEffectGroup.add(trail);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (!isOnScreen() || x < -500 || x > FlxG.worldBounds.width + 500 || y > FlxG.worldBounds.height + 500) 
        {
            this.active = false;
            this.destroy();
        }
    }

    override public function destroy()
    {
        if (trail != null)
        {
            if (parentState != null) parentState.eventEffectGroup.remove(trail, true);
            trail.destroy();
            trail = null;
        }
        super.destroy();
    }
}