package main.bosses.ch1;

import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.effects.particles.FlxEmitter;
import flixel.math.FlxPoint;
import flixel.addons.effects.FlxTrail;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.math.FlxVelocity;
import flixel.math.FlxAngle;
import main.bosses.ch1.BossJevil;

class IntroScythe extends FlxSprite
{
    public var trail:FlxTrail;
    var jevil:Jevil;
    var stateRef:ChapterState;

    public function new(x:Float, y:Float, state:ChapterState, speed:Int)
    {
        super(x, y);
        this.stateRef = state;
        loadGraphic(AssetPaths.jevil_scythe__png, false);
        scale.set(2, 2);
        updateHitbox();
        velocity.y = speed;
        angularVelocity = 600;

        trail = new FlxTrail(this, null, 20, 2, 0.5, 0.05);
        stateRef.add(trail);
        
    }

    override function destroy()
    {
        if (trail != null)
        {
            if (stateRef != null)
            {
                stateRef.remove(trail);
            }
            trail.destroy();
            trail = null;
        }

        super.destroy();
    }
}

class JevilBullet extends FlxSprite
{
    public var trail:FlxTrail;
    var stateRef:main.ChapterState;
    
    public function new(x:Float, y:Float, type:String, ?angleOverride:Float, state:ChapterState)
    {
        stateRef = state;

        super(x + 25, y + 50);
        loadGraphic(AssetPaths.spades__png, true, 34, 34);
        animation.add("spade", [0, 1], 6, true);
        animation.add("club", [2, 3], 6, true);
        animation.add("clubIdle", [2], 1, false);
        scale.set(1.15, 1.15);

        trail = new FlxTrail(this, null, 20, 2, 0.10, 0.05);
        stateRef.add(trail);

        var randomSprite = FlxG.random.int(0, 1);
        if (randomSprite == 0) animation.play("spade");
        else animation.play("club");
        
        if (type == "spade") animation.frameIndex = 1;
        else animation.frameIndex = 0;

        var speed:Float = (type == "spade") ? 350 : 400;

        if (angleOverride != null)
        {
            velocity.set
            (
                Math.cos(angleOverride * Math.PI / 180) * speed,
                Math.sin(angleOverride * Math.PI / 180) * speed
            );
        }
        else
        {
            if (stateRef != null && stateRef.player != null)
            {
                flixel.math.FlxVelocity.moveTowardsObject(this, stateRef.player, speed);
            }
        }

    }

    override public function update(elapsed:Float)
    {
        if (velocity.x != 0 || velocity.y != 0)
        {
            angle = Math.atan2(velocity.y, velocity.x) * 180 / Math.PI;
        }

        super.update(elapsed);
        if (!isOnScreen() && alpha >= 1)
        {
            destroy();
        }
    }

    override public function destroy()
    {
        if (trail != null)
        {
            if (stateRef != null)
            {
                stateRef.remove(trail);
            }
            trail.destroy();
            trail = null;
        }
        
        super.destroy();
    }

}

class JevilBombs extends FlxSprite
{
    public var trail:FlxTrail;
    var stateRef:main.ChapterState;

    public function new(x:Float, y:Float, type:String, state:main.ChapterState, ?angleOverride:Float)
    {
        super(x, y);
        this.stateRef = state;
        var randomBomb = FlxG.random.int(0, 3);
        loadGraphic(AssetPaths.bombs__png, true, 23, 23);
        animation.add("clubs", [0, 1], 6, true);
        animation.add("diamond", [2, 3], 6, true);
        animation.add("hearts", [4, 5], 6, true);
        animation.add("spade", [6, 7], 6, true);
        animation.play("clubs");
        scale.set(2, 2);

        switch (randomBomb)
        {
            case 0: animation.play("clubs");
            case 1: animation.play("diamond");
            case 2: animation.play("hearts");
            case 3: animation.play("spade");
        }
        
        trail = new FlxTrail(this, null, 20, 2, 0.10, 0.05);
        stateRef.add(trail);

        if (type == "spade") animation.frameIndex = 1;
        else animation.frameIndex = 0;

        var speed:Float = (type == "spade") ? 600 : 400;

        if (angleOverride != null)
        {
            velocity.set
            (
                Math.cos(angleOverride * Math.PI / 180) * speed,
                Math.sin(angleOverride * Math.PI / 180) * speed
            );
        }
        else
        {
            if (stateRef != null && stateRef.player != null)
            {
                flixel.math.FlxVelocity.moveTowardsObject(this, stateRef.player, speed);
            }
        }
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (!isOnScreen())
        {
            destroy();
            return;
        }

        var bombCount = 0;

        for (obj in stateRef.dangerObjects.members)
        {
            if (obj != null
                && obj.exists
                && Std.isOfType(obj, JevilBombs))
            {
                bombCount++;
            }
        }
    }

    override public function destroy()
    {
        if (trail != null)
        {
            if (stateRef != null)
            {
                stateRef.remove(trail);
            }
            trail.destroy();
            trail = null;
        }

        super.destroy();
    }
}

class JevilDiamondScythe extends FlxSprite
{
    var playerRef:flixel.FlxSprite;
    var stateRef:main.ChapterState;
    var trail:FlxTrail;
    var scaleScythe:Float;

    public function new(x:Float, y:Float, state:main.ChapterState)
    {

        scaleScythe = 1.5;
        super(x, y);
        this.playerRef = state.player;
        this.stateRef = state;
        loadGraphic(AssetPaths.jevil_scythe__png, false);
        this.scale.set(scaleScythe, scaleScythe);
        updateHitbox();

        angularVelocity = 800;
        FlxTween.tween(this, {alpha: 1}, 0.5);
        trail = new FlxTrail(this, null, 12, 2, 0.25, 0.05);
        stateRef.add(trail);
        
        new flixel.util.FlxTimer().start(0.75, function(tmr:flixel.util.FlxTimer)
        {

            if (!this.exists || playerRef == null || !playerRef.exists || !playerRef.alive) 
            {
                return; 
            }

            flixel.math.FlxVelocity.moveTowardsObject(this, playerRef, 750);
            FlxG.sound.play(AssetPaths.dash__ogg, 0.25, false);
        });

    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (!isOnScreen() && alpha >= 1)
        {
            stateRef.remove(trail);
            trail.destroy();
            destroy();
        }
    }

    override public function destroy()
    {
        if (trail != null)
        {
            if (stateRef != null)
            {
                stateRef.remove(trail);
            }
            trail.destroy();
        }
        super.destroy();
    }
}

class JevilJewel extends FlxSprite
{
    var trail:FlxTrail;
    var stateRef:main.ChapterState;

    public function new(x:Float, y:Float, state:main.ChapterState)
    {
        super(x, y);

        this.stateRef = state;
        this.alpha = 0;
        var randomVolume = FlxG.random.float(0.25, 0.5);
        loadGraphic(AssetPaths.jewel__png, true, 19, 33);
        animation.add("idle", [0], 1, false);
        animation.play("idle");

        var particle = new flixel.effects.particles.FlxEmitter(x + 8, y + 18, 8);
        particle.makeParticles(3, 3, FlxColor.WHITE, 12);
        particle.color.set(FlxColor.WHITE);
        particle.launchMode = CIRCLE;
        particle.drag.set(100, 100);
        particle.speed.set(50, 100);
        particle.angularVelocity.set(-300, 300);
        particle.lifespan.set(0.3, 0.5);
        stateRef.add(particle);
        particle.start(true, 0, 12);

        new flixel.util.FlxTimer().start(1, function(_)
        {
            if (stateRef != null) 
            {
                stateRef.remove(particle);
                }
                    if (particle != null) 
                {
                particle.destroy();
            }
        });

        updateHitbox();

        FlxTween.tween(this, {alpha: 1}, 0.25, { ease: FlxEase.backIn });
        FlxG.sound.play(AssetPaths.beep__ogg, randomVolume, false);

        velocity.set(0, 0);
        acceleration.set(0, 0);

        trail = new FlxTrail(this, null, 20, 2, 0.25, 0.05);
        stateRef.add(trail);

        new flixel.util.FlxTimer().start(1, function(tmr:flixel.util.FlxTimer)
        {
            if (!this.exists || !this.alive) 
            {
                tmr.cancel();
                return;
            }

            acceleration.y = -1400;
        });
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (y < -100) 
        {
            destroyJewel();
        }

    }

    private function destroyJewel():Void
    {
        if (trail != null)
        {
            var mainState = cast(FlxG.state, main.ChapterState);
            if (mainState != null)
            {
                mainState.remove(trail);
            }
            trail.destroy();
            trail = null;
        }
        destroy();
    }
    
    override public function destroy()
    {
        if (trail != null)
        {
            if (stateRef != null)
            {
                stateRef.remove(trail);
            }
            trail.destroy();
            trail = null;
        }

        super.destroy();
    }
}

class JevilCircleSpade extends flixel.FlxSprite
{
    public var isFollowing:Bool = true;
    public var angleRad:Float = 0;
    public var radius:Float = 200;
    var stateRef:ChapterState;
    var playerRef:flixel.FlxSprite;
    var trail:FlxTrail;

    public function new(angleRad:Float, radius:Float, player:flixel.FlxSprite, state:ChapterState)
    {
        FlxTween.cancelTweensOf(this);
        super(0, 0);
        this.angleRad = angleRad;
        this.stateRef = state;
        this.radius = radius;
        this.playerRef = player;

        loadGraphic(AssetPaths.spades__png, true, 34, 34);
        animation.add("spade", [2], 1, false);
        animation.play("spade");
        this.scale.set(1.25, 1.25);
        updateHitbox();
        trail = new FlxTrail(this, null, 12, 2, 0.25, 0.05);
        stateRef.add(trail);
        updatePosition();
    }

    private function updatePosition():Void
    {
        if (playerRef == null) return;
        
        var centerX:Float = playerRef.x + (playerRef.width / 2);
        var centerY:Float = playerRef.y + (playerRef.height / 2);

        x = centerX + Math.cos(angleRad) * radius - (width / 2);
        y = centerY + Math.sin(angleRad) * radius - (height / 2);

        angle = (angleRad * 180 / Math.PI) + 180;
    }

    override public function update(elapsed:Float)
    {
        if (isFollowing)
        {
            updatePosition();
            super.update(elapsed);
        }
        else
        {
            super.update(elapsed);
            if (velocity.x != 0 || velocity.y != 0)
            {
                angle = Math.atan2(velocity.y, velocity.x) * 180 / Math.PI;
            }
        }

        if (!isOnScreen() && !isFollowing)
        {
            destroy();
        }
    }

    override function destroy()
    {
        if (trail != null)
        {
            if (stateRef != null)
            {
                stateRef.remove(trail);
            }
            trail.destroy();
            trail = null;
        }

        super.destroy();
    }

    public function launch(targetX:Float, targetY:Float, speed:Float):Void
    {
        isFollowing = false;
        flixel.math.FlxVelocity.moveTowardsPoint(this, flixel.math.FlxPoint.get(targetX - (width / 2), targetY - (height / 2)), speed);
    }
}

class JevilBombardingBomb extends flixel.FlxSprite
{
    var stateRef:main.ChapterState;
    var lifetime:Float;
    var spawnXPos:Float;

    public function new(x:Float, y:Float, state:main.ChapterState)
    {
        super(x, y);
        this.stateRef = state;
        this.spawnXPos = x;

        loadGraphic(AssetPaths.bombs__png, true, 23, 23);
        animation.add("club", [0, 1], 6, true);
        animation.add("diamond", [2, 3], 6, true);
        animation.add("heart", [4, 5], 6, true);
        animation.add("spade", [6, 7], 6, true);
        scale.set(3, 3);

        var randomAnim = FlxG.random.int(0, 3);
        switch (randomAnim)
        {
            case 0: animation.play("club");
            case 1: animation.play("diamond");
            case 2: animation.play("heart");
            case 3: animation.play("spade");
        }

        velocity.y = 600;
        angularVelocity = FlxG.random.float(120, 200);

        lifetime = FlxG.random.float(0.3, 1);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        lifetime -= elapsed;
        if (lifetime <= 0)
        {
            explode();
        }
    }

    function explode()
    {
        if (!this.exists) return;
        if (stateRef == null || stateRef.dangerObjects == null) return;
        FlxG.camera.shake(0.01, 0.15);

        var particle = new FlxEmitter(x + (width / 2), y + (height / 2), 25);
        particle.makeParticles(5, 5, flixel.util.FlxColor.WHITE, 50);
        particle.launchMode = CIRCLE;
        particle.speed.set(150, 350);
        particle.lifespan.set(0.5, 1.5);
        stateRef.add(particle);
        particle.start(true, 0, 50);

        FlxG.sound.play(AssetPaths.jevil_bomb__ogg, 1, false);

        var baseAngle:Float = (spawnXPos <= 200) ? 0 : 180;

        var slantUp:Float = baseAngle + FlxG.random.float(-45, -10);
        var straight:Float = baseAngle;
        var slantDown:Float = baseAngle + FlxG.random.float(10, 45);

        var anglesToFire:Array<Float> = [slantUp, straight, slantDown];

        for (angleDeg in anglesToFire)
        {
            var shard = new JevilBombShard(x + (width / 2), y + (height / 2), angleDeg, stateRef);
            stateRef.dangerObjects.add(shard);
        }

        destroy();
    }
}

class JevilBombShard extends flixel.FlxSprite
{

    var trail:FlxTrail;
    var stateRef:main.ChapterState;

    public function new(x:Float, y:Float, angleDeg:Float, state:ChapterState)
    {
        super(x, y);

        this.stateRef = state;
        loadGraphic(AssetPaths.spades__png, true, 34, 34);
        animation.add("club", [0, 1], 6, true);
        animation.add("spade", [2, 3], 6, true);

        var randomType = FlxG.random.int(0, 1);
        if (randomType == 0) animation.play("club");
        else animation.play("spade");

        scale.set(1.5, 1.5);
        updateHitbox();

        trail = new FlxTrail(this, null, 12, 2, 0.25, 0.05);
        stateRef.add(trail);

        var speed:Float = 550;
        var rad:Float = angleDeg * Math.PI / 180;
        velocity.set(Math.cos(rad) * speed, Math.sin(rad) * speed);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (velocity.x != 0 || velocity.y != 0)
        {
            angle = Math.atan2(velocity.y, velocity.x) * 180 / Math.PI;
        }

        if (!isOnScreen())
        {
            destroy();
        }
    }

    override public function destroy()
    {
        if (trail != null)
        {
            stateRef.remove(trail);
            trail.destroy();
            trail = null;
        }
        super.destroy();
    }
}

class JevilUltimateScythe extends flixel.FlxSprite
{
    var stateRef:main.ChapterState;
    var trail:flixel.addons.effects.FlxTrail;
    static var explosionSoundCooldown:Float = 0;

    public function new(x:Float, y:Float, state:main.ChapterState)
    {
        super(x, -150);
        this.stateRef = state;

        loadGraphic(AssetPaths.jevil_scythe__png, false);
        scale.set(2.5, 2.5);
        updateHitbox();

        velocity.y = 950;
        angularVelocity = 750;

        trail = new flixel.addons.effects.FlxTrail(this, null, 15, 2, 0.4, 0.05);
        stateRef.add(trail);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (y > flixel.FlxG.height)
        {
            explode();
        }

        if (explosionSoundCooldown > 0)
        {
            explosionSoundCooldown -= elapsed;
        }


    }

    function explode()
    {
        if (!this.exists) return;

        if (explosionSoundCooldown <= 0)
        {
            FlxG.sound.play(AssetPaths.scythe_explosion__ogg, 0.8);
            explosionSoundCooldown = 0.02;
        }

        var slash = new FlxSprite(x + width / 2 - 100, 0);
        slash.makeGraphic(200, FlxG.height, FlxColor.WHITE);
        slash.origin.set(100, 0);
        FlxG.camera.shake(0.01, 0.05);
        stateRef.add(slash);

        FlxTween.tween(slash, {alpha: 0}, 1);

        FlxTween.tween(slash.scale, {x: 0}, 1,
        {
            ease: FlxEase.quadOut,
            onComplete: function(_)
            {
                if (slash != null && slash.exists) 
                {
                    slash.kill();
                }
            }
        });

        var emitter = new flixel.effects.particles.FlxEmitter(x + (width / 2), y, 20);
        emitter.makeParticles(3, 3, flixel.util.FlxColor.WHITE, 50);
        emitter.launchMode = CIRCLE;
        emitter.speed.set(100, 400);
        emitter.lifespan.set(0.5, 1.2);
        emitter.drag.set(100, 100);
        emitter.angularVelocity.set(-300, 300);
        stateRef.add(emitter);
        emitter.start(true, 0, 50);

        if (trail != null)
        {
            stateRef.remove(trail);
            trail.destroy();
            trail = null;
        }
        destroy();
    }

    override public function destroy()
    {
        if (trail != null)
        {
            if (stateRef != null)
                stateRef.remove(trail, true);

            trail.destroy();
            trail = null;
        }

        super.destroy();
    }
}

class JevilHeartBomb extends flixel.FlxSprite
{
    static inline var ORBIT_SPEED:Float = 120;

    var centerX:Float;
    var centerY:Float;
    var orbitRadius:Float;
    var orbitAngle:Float;
    var travelSpeed:Float;
    var direction:Int;

    public function new(centerX:Float, centerY:Float, angleOffset:Float, orbitRadius:Float, travelSpeed:Float, direction:Int)
    {
        super();

        this.centerX = centerX;
        this.centerY = centerY;
        this.orbitRadius = orbitRadius;
        this.orbitAngle = angleOffset;
        this.travelSpeed = travelSpeed;
        this.direction = direction;

        loadGraphic(AssetPaths.jevilHeart__png, false);
        scale.set(1.5, 1.5);
        updateHitbox();

        placeAtOrbitPosition();
    }

    override public function update(elapsed:Float)
    {
        centerX += direction * travelSpeed * elapsed;
        orbitAngle += ORBIT_SPEED * elapsed;

        placeAtOrbitPosition();

        super.update(elapsed);

        if (!isOnScreen())
        {
            destroy();
        }
    }

    function placeAtOrbitPosition():Void
    {
        var rad:Float = orbitAngle * Math.PI / 180;
        x = centerX + Math.cos(rad) * orbitRadius - width / 2;
        y = centerY + Math.sin(rad) * orbitRadius - height / 2;
    }
}
