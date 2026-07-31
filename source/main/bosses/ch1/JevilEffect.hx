package main.bosses.ch1;

import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.FlxG;
import main.ChapterState;
import main.bosses.ch1.BossJevil.Jevil;

class JevilEffect extends FlxBasic
{
    static inline var ORBIT_RADIUS:Float = 75;

    var jevil:Jevil;
    var parentState:ChapterState;
    var ghost:FlxSprite;

    var orbitAngle:Float = 0;
    var direction:Int = 1;
    var directionFlipTimer:Float = 0;
    var pulseTimer:Float = 0; 

    var currentFlipInterval:Float = 0.5;
    var currentSpeed:Float = 160;

    public function new(jevil:Jevil, parentState:ChapterState)
    {
        super();
        this.jevil = jevil;
        this.parentState = parentState;

        currentFlipInterval = FlxG.random.float(0.35, 1.0);
        currentSpeed = FlxG.random.float(100, 300);

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
            ghost.active = false;

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

        // ONLY SHOW IF CRAZINESS IS ACTIVE
        var shouldShow:Bool = jevil.alpha >= 1 
            && jevil.visible 
            && !isTired
            && jevil.craziness // Check craziness here!
            && jevil.state != "waiting" 
            && jevil.state != "precutscene" 
            && jevil.state != "cutscene";

        if (!shouldShow)
        {
            ghost.visible = false;
            return;
        }

        // --- 1. DIRECTION FLIP & RANDOMIZATION ---
        directionFlipTimer += elapsed;
        if (directionFlipTimer >= currentFlipInterval)
        {
            directionFlipTimer = 0;
            direction *= -1;
            orbitAngle += 180;
            
            currentFlipInterval = FlxG.random.float(0.35, 1.0);
            currentSpeed = FlxG.random.float(250, 600); // Speed during craziness
        }

        // --- 2. ORBIT CALCULATIONS ---
        orbitAngle += currentSpeed * direction * elapsed;
        
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

        // --- 3. PULSE & FLICKER ALPHA ---
        pulseTimer += elapsed;
        var sineWave:Float = (Math.sin(pulseTimer * Math.PI * 2) + 1) / 2.0; 
        var pulsedBaseAlpha:Float = sineWave * 0.2; 

        var flickerNoise:Float = (Math.random() * 0.5) - 0.1; 
        
        var finalAlpha:Float = pulsedBaseAlpha + flickerNoise;

        if (finalAlpha < 0) finalAlpha = 0;
        if (finalAlpha > 0.425) finalAlpha = 0.425;

        ghost.color = jevil.color;
        ghost.alpha = finalAlpha;
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