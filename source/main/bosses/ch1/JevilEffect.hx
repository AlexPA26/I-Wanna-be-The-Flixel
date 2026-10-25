package main.bosses.ch1;

import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import main.ChapterState;
import main.bosses.ch1.BossJevil.Jevil;

/**
 * Data structure managing individual illusion clones of Jevil.
 */
class JevilCloneData
{
    public var sprite:FlxSprite;

    // Anchor center relative to Jevil around which this clone orbits
    public var centerOffsetX:Float = 0;
    public var centerOffsetY:Float = 0;

    // Orbit parameters
    public var orbitRadiusX:Float = 25.0;
    public var orbitRadiusY:Float = 20.0;
    public var orbitAngle:Float = 0;
    public var orbitSpeed:Float = 12;
    public var orbitDirection:Int = 1;

    // Lifetime / teleport duration
    public var duration:Float = 0.65;
    public var timer:Float = 0;

    // Alpha pulsing parameters
    public var pulseTimer:Float = 0;
    public var pulseSpeed:Float = 7.0;

    public function new(sprite:FlxSprite)
    {
        this.sprite = sprite;
    }
}

class JevilEffect extends FlxBasic
{
    static inline var MAX_OFFSET_X:Float = 250.0;
    static inline var MAX_OFFSET_Y:Float = 200.0;
    static inline var MIN_CENTER_DIST:Float = 85.0;
    static inline var CLONE_COUNT:Int = 4;

    var jevil:Jevil;
    var parentState:ChapterState;
    var clones:Array<JevilCloneData>;
    var wasShowing:Bool = false;

    public function new(jevil:Jevil, parentState:ChapterState)
    {
        super();
        this.jevil = jevil;
        this.parentState = parentState;
        this.clones = [];

        try
        {
            initClones();
        }
        catch (e:Dynamic)
        {
            trace("[JevilEffect] Failed to initialize clones: " + e);
        }
    }

    function initClones():Void
    {
        for (i in 0...CLONE_COUNT)
        {
            var sprite = new FlxSprite();

            if (jevil != null && jevil.frames != null)
            {
                sprite.frames = jevil.frames;
            }
            else
            {
                sprite.frames = FlxAtlasFrames.fromSparrow(AssetPaths.jevil__png, AssetPaths.jevil__xml);
            }

            // Register animations
            sprite.animation.addByPrefix("dance", "jevil_dance_normal", 12, true);
            sprite.animation.addByPrefix("danceLowHP", "jevil_dance_", 16, true);
            sprite.animation.addByPrefix("idle", "jevil_main_", 8, true);
            sprite.animation.addByPrefix("laugh", "jevil_laugh", 12, true);

            var initialAnim = (jevil != null && jevil.craziness) ? "danceLowHP" : "dance";
            sprite.animation.play(initialAnim, true, false, FlxG.random.int(0, 10));

            if (jevil != null)
            {
                sprite.scale.set(jevil.scale.x, jevil.scale.y);
                sprite.flipX = jevil.flipX;
                sprite.flipY = jevil.flipY;
            }
            else
            {
                sprite.scale.set(2.5, 2.5);
            }

            sprite.updateHitbox();
            sprite.angle = 0; // Strictly no tilting!
            sprite.solid = false;
            sprite.moves = false;
            sprite.visible = false;
            sprite.alpha = 0;

            var data = new JevilCloneData(sprite);
            data.timer = (i / CLONE_COUNT) * 0.6; // Stagger initial timers
            data.orbitAngle = FlxG.random.float(0, Math.PI * 2);
            data.pulseTimer = FlxG.random.float(0, Math.PI * 2);
            data.pulseSpeed = FlxG.random.float(6.0, 10.0);

            teleportClone(data);
            clones.push(data);

            if (parentState != null)
            {
                var jevilIdx:Int = parentState.members.indexOf(jevil);
                if (jevilIdx != -1)
                {
                    parentState.insert(jevilIdx, sprite);
                }
                else
                {
                    parentState.add(sprite);
                }
            }
        }
    }

    function teleportClone(data:JevilCloneData):Void
    {
        // Randomized duration so clones don't teleport in sync
        data.duration = FlxG.random.float(0.6, 1.3);
        data.timer = 0;
        data.pulseTimer = FlxG.random.float(0, Math.PI * 2);
        data.pulseSpeed = FlxG.random.float(6.0, 10.0);

        // Orbit configuration
        data.orbitRadiusX = FlxG.random.float(20.0, 38.0);
        data.orbitRadiusY = FlxG.random.float(15.0, 28.0);
        data.orbitAngle = FlxG.random.float(0, Math.PI * 2);
        data.orbitSpeed = FlxG.random.float(6.0, 15.5);
        data.orbitDirection = FlxG.random.bool() ? 1 : -1;

        var maxCenterRangeX = MAX_OFFSET_X - data.orbitRadiusX;
        var maxCenterRangeY = MAX_OFFSET_Y - data.orbitRadiusY;

        var ox:Float = 0;
        var oy:Float = 0;
        var attempts:Int = 0;
        do
        {
            ox = FlxG.random.float(-maxCenterRangeX, maxCenterRangeX);
            oy = FlxG.random.float(-maxCenterRangeY, maxCenterRangeY);
            attempts++;
        }
        while ((ox * ox + oy * oy < MIN_CENTER_DIST * MIN_CENTER_DIST) && attempts < 25);

        if (ox * ox + oy * oy < MIN_CENTER_DIST * MIN_CENTER_DIST)
        {
            var signX:Float = FlxG.random.bool() ? 1.0 : -1.0;
            ox = signX * FlxG.random.float(MIN_CENTER_DIST, maxCenterRangeX);
        }

        data.centerOffsetX = ox;
        data.centerOffsetY = oy;

        if (data.sprite != null)
        {
            data.sprite.angle = 0; // Strictly no tilting!
        }
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        try
        {
            tick(elapsed);
        }
        catch (e:Dynamic)
        {
            trace("[JevilEffect] tick() failed, hiding clones for safety: " + e);
            hideAllClones();
        }
    }

    function hideAllClones():Void
    {
        if (clones == null) return;
        for (data in clones)
        {
            if (data.sprite != null)
            {
                data.sprite.visible = false;
                data.sprite.alpha = 0;
            }
        }
    }

    function tick(elapsed:Float):Void
    {
        if (clones == null || jevil == null || !jevil.exists || parentState == null)
        {
            hideAllClones();
            wasShowing = false;
            return;
        }

        // Tired animation check
        var isTired:Bool = jevil.animation != null
            && jevil.animation.curAnim != null
            && jevil.animation.curAnim.name == "tired";

        // Cube state checks
        var isCubeState:Bool = jevil.state == "returningCube"
            || jevil.state == "startCube"
            || jevil.state == "attackingCube";

        // Non-battle state checks
        var isNonBattleState:Bool = jevil.state == "waiting"
            || jevil.state == "precutscene"
            || jevil.state == "cutscene"
            || jevil.state == "dead";

        // Clones appear only when craziness is set to true (after returning from the Ultimate attack)
        var shouldShow:Bool = this.visible
            && jevil.visible
            && jevil.alpha > 0
            && jevil.craziness
            && !isTired
            && !isCubeState
            && !isNonBattleState;

        if (!shouldShow)
        {
            hideAllClones();
            wasShowing = false;
            return;
        }

        // When switching back to visible, re-teleport clones immediately
        if (!wasShowing)
        {
            wasShowing = true;
            for (i in 0...clones.length)
            {
                var data = clones[i];
                data.timer = (i / clones.length) * 0.4;
                teleportClone(data);
            }
        }

        // Determine matching dance animation
        var targetAnim:String = (jevil.craziness) ? "danceLowHP" : "dance";
        if (jevil.animation != null && jevil.animation.curAnim != null)
        {
            var curName = jevil.animation.curAnim.name;
            if (curName == "dance" || curName == "danceLowHP" || curName == "idle" || curName == "laugh")
            {
                targetAnim = curName;
            }
        }

        for (data in clones)
        {
            var sprite = data.sprite;
            if (sprite == null) continue;

            data.timer += elapsed;
            if (data.timer >= data.duration)
            {
                teleportClone(data);
            }

            // Sync animation with Jevil's dance without interrupting playback
            if (sprite.animation != null)
            {
                if (sprite.animation.curAnim == null || sprite.animation.curAnim.name != targetAnim)
                {
                    sprite.animation.play(targetAnim, false, false, FlxG.random.int(0, 10));
                }
            }

            // Match scale, flip and ensure strictly no tilting
            sprite.scale.set(jevil.scale.x, jevil.scale.y);
            sprite.flipX = jevil.flipX;
            sprite.flipY = jevil.flipY;
            sprite.updateHitbox();
            sprite.angle = 0; // Strictly no tilting!

            // Orbit around nearby center point
            data.orbitAngle += data.orbitSpeed * data.orbitDirection * elapsed;
            var rawX:Float = data.centerOffsetX + Math.cos(data.orbitAngle) * data.orbitRadiusX;
            var rawY:Float = data.centerOffsetY + Math.sin(data.orbitAngle) * data.orbitRadiusY;

            // Enforce limits: maximum X 150 and Y 100 of original Jevil
            var boundedX:Float = FlxMath.bound(rawX, -MAX_OFFSET_X, MAX_OFFSET_X);
            var boundedY:Float = FlxMath.bound(rawY, -MAX_OFFSET_Y, MAX_OFFSET_Y);

            // Avoid collapsing directly on Jevil's center
            var distSq:Float = boundedX * boundedX + boundedY * boundedY;
            if (distSq < MIN_CENTER_DIST * MIN_CENTER_DIST)
            {
                var dist:Float = Math.sqrt(distSq);
                if (dist < 0.001) { boundedX = MIN_CENTER_DIST; dist = MIN_CENTER_DIST; }
                boundedX = (boundedX / dist) * MIN_CENTER_DIST;
                boundedY = (boundedY / dist) * MIN_CENTER_DIST;
            }

            sprite.x = jevil.x + boundedX;
            sprite.y = jevil.y + boundedY;

            // Pulsing alpha
            data.pulseTimer += elapsed * data.pulseSpeed;
            var sineWave:Float = (Math.sin(data.pulseTimer) + 1.0) * 0.5;
            var pulsedBaseAlpha:Float = 0.35 + sineWave * 0.35; // 0.35 to 0.70
            var flickerNoise:Float = (Math.random() * 0.06) - 0.03;
            var finalAlpha:Float = FlxMath.bound(pulsedBaseAlpha + flickerNoise, 0.25, 0.75);

            sprite.color = jevil.color;
            sprite.alpha = finalAlpha * jevil.alpha;
            sprite.visible = true;
        }
    }

    override public function destroy():Void
    {
        if (clones != null)
        {
            for (data in clones)
            {
                if (data != null && data.sprite != null)
                {
                    try
                    {
                        data.sprite.kill();
                        if (parentState != null)
                        {
                            parentState.remove(data.sprite, true);
                        }
                        data.sprite.destroy();
                    }
                    catch (e:Dynamic) {}
                    data.sprite = null;
                }
            }
            clones = null;
        }

        jevil = null;
        parentState = null;

        super.destroy();
    }
}
