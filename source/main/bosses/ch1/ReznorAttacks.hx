package main.bosses.ch1;

import flixel.util.FlxColor;
import flixel.util.FlxTimer;
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
        animation.add("burn", [0, 1], 12, true);
        animation.play("burn");
        flipX = true;

        var angleRad = Math.atan2(targetY - spawnY, targetX - spawnX);
        var speed = FlxG.random.int(650, 900);
        velocity.x = Math.cos(angleRad) * speed;
        velocity.y = Math.sin(angleRad) * speed;
        angle = angleRad * (180 / Math.PI); 

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

class ReznorFireball extends FlxSprite
{
    var parentState:ChapterState;

    public function new(spawnX:Float, spawnY:Float, targetX:Float, targetY:Float, stateRef:ChapterState)
    {
        super(spawnX, spawnY);
        this.parentState = stateRef;

        loadGraphic(AssetPaths.reznor_fireball__png, true, 16, 16);
        scale.set(2, 2);
        updateHitbox();
        animation.add("burn", [0, 1, 2, 3], 15, true);
        animation.play("burn");

        var angleRad = Math.atan2(targetY - spawnY, targetX - spawnX);
        var speed = 350;
        var explosionTimer = FlxG.random.float(2, 4);
        velocity.x = Math.cos(angleRad) * speed;
        velocity.y = Math.sin(angleRad) * speed;
        
        acceleration.y = 800;
        elasticity = 1.0;
        
        new FlxTimer().start(explosionTimer, function(_) 
        {
            explode();
        });
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (parentState != null)
        {
            FlxG.collide(this, parentState.map);
            FlxG.collide(this, parentState.slabs);
            FlxG.collide(this, parentState.solidBlock);
        }
    }

    function explode()
    {
        if (!alive || !exists) return;

        FlxG.sound.play(AssetPaths.reznor_fireball_off__ogg, 0.25, false);
        var particles = new flixel.effects.particles.FlxEmitter(this.x + (this.width / 2), this.y + (this.height / 2));
        particles.makeParticles(3, 3, FlxColor.WHITE, 15);
        particles.color.set(FlxColor.RED, FlxColor.ORANGE, FlxColor.YELLOW);
        particles.launchMode = CIRCLE;
        particles.speed.set(50, 150);
        particles.lifespan.set(0.2, 0.5);
        parentState.eventEffectGroup.add(particles);
        particles.start(true, 0, 15);
        
        new FlxTimer().start(1, function(_) 
        {
            if (parentState != null) parentState.eventEffectGroup.remove(particles, true);
            particles.destroy();
        });

        this.active = false;
        this.destroy();
    }
}