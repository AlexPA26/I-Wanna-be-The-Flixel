package main.bosses.ch1;

import flixel.FlxBasic;
import flixel.FlxSprite;
import main.ChapterState;
import main.bosses.ch1.BossJevil.Jevil;

class JevilEffect extends FlxBasic
{
    static inline var ORBIT_RADIUS:Float = 75;
    static inline var BASE_SPEED:Float = 160;
    static inline var CRAZY_SPEED:Float = 500;
    static inline var DIRECTION_FLIP_INTERVAL:Float = 2.0;
    static inline var GHOST_ALPHA:Float = 0.2;
    static inline var GHOST_ALPHA_CRAZINESS:Float = 0.4;

    var jevil:Jevil;
    var parentState:ChapterState;
    var ghost:FlxSprite;

    var orbitAngle:Float = 0;
    var direction:Int = 1;
    var directionFlipTimer:Float = 0;

    public function new(jevil:Jevil, parentState:ChapterState)
    {
        super();
        this.jevil = jevil;
        this.parentState = parentState;

        try
        {
            ghost = new FlxSprite();
            if (jevil != null)
            {
                ghost.frames = jevil.frames;
            }
            ghost.alpha = 0;
            ghost.visible = false;
            ghost.solid = false;
            ghost.moves = false;
            ghost.active = false; // driven manually below, doesn't need its own update logic

            if (parentState != null)
            {
                parentState.add(ghost);
            }
        }
        catch (e:Dynamic)
        {
            trace("[JevilEffect] Failed to set up ghost sprite: " + e);
            ghost = null;
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
            trace("[JevilEffect] tick() failed, hiding ghost for safety: " + e);
            if (ghost != null) ghost.visible = false;
        }
    }

    function tick(elapsed:Float):Void
    {
        if (ghost == null || jevil == null || !jevil.exists || parentState == null)
        {
            if (ghost != null) ghost.visible = false;
            return;
        }

        var isTired:Bool = jevil.animation != null
            && jevil.animation.curAnim != null
            && jevil.animation.curAnim.name == "tired";

        var shouldShow:Bool = jevil.alpha >= 1 && jevil.visible && !isTired
        && jevil.state != "waiting" && jevil.state != "precutscene" && jevil.state != "cutscene";

        if (!shouldShow)
        {
            ghost.visible = false;
            return;
        }

        var speed:Float = BASE_SPEED;
        var ghostAlpha:Float = GHOST_ALPHA;

        if (jevil.craziness)
        {

            speed = CRAZY_SPEED;


            directionFlipTimer += elapsed;
            if (directionFlipTimer >= DIRECTION_FLIP_INTERVAL)
            {
                directionFlipTimer -= DIRECTION_FLIP_INTERVAL;
                direction *= -1;
            }
        }
        else
        {
            direction = 1;
            directionFlipTimer = 0;
        }

        orbitAngle += speed * direction * elapsed;
        if (orbitAngle > 360) orbitAngle -= 360;
        if (orbitAngle < -360) orbitAngle += 360;

        var rad:Float = orbitAngle * Math.PI / 180;
        var offsetX:Float = Math.cos(rad) * ORBIT_RADIUS;
        var offsetY:Float = Math.sin(rad) * ORBIT_RADIUS;

        if (jevil.animation != null && ghost.animation != null)
        {
            ghost.animation.frameIndex = jevil.animation.frameIndex;
        }

        ghost.scale.set(jevil.scale.x, jevil.scale.y);
        ghost.flipX = jevil.flipX;
        ghost.flipY = jevil.flipY;
        ghost.updateHitbox();

        ghost.x = jevil.x + jevil.width / 2 - ghost.width / 2 + offsetX;
        ghost.y = jevil.y + jevil.height / 2 - ghost.height / 2 + offsetY;

        ghost.color = jevil.color;
        if (!jevil.craziness) ghost.alpha = GHOST_ALPHA;
        else { ghost.alpha = GHOST_ALPHA_CRAZINESS; }
        ghost.visible = true;
    }

    override public function destroy():Void
    {
        try
        {
            if (ghost != null)
            {
                ghost.kill();
                if (parentState != null)
                {
                    parentState.remove(ghost, true);
                }
                ghost.destroy();
            }
        }
        catch (e:Dynamic) {}

        ghost = null;
        jevil = null;
        parentState = null;

        super.destroy();
    }
}
