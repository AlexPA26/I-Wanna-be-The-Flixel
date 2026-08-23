package main.bosses.ch1;

import flixel.effects.particles.FlxEmitter;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class JevilClone extends flixel.FlxSprite
{
    var parentState:main.ChapterState;

    public function new(x:Float, y:Float, parentState:main.ChapterState, facingLeft:Bool)
    {
        super(x, y);
        this.parentState = parentState;

        frames = flixel.graphics.frames.FlxAtlasFrames.fromSparrow(AssetPaths.jevil__png, AssetPaths.jevil__xml);
        animation.addByPrefix("teleport", "jevil_teleport_n", 4, false);
        animation.play("teleport", true, false);
        
        flipX = facingLeft;

        scale.set(5.5, 0.15);
        updateHitbox();
        particleJevilClone();

        FlxTween.tween(scale, { x: 2.5, y: 2.5 }, 0.45, { ease: FlxEase.backOut });
    }

    private function particleJevilClone():Void
    {
        var particle = new FlxEmitter(x + (width / 2), y + (height / 2));
        particle.makeParticles(4, 4, FlxColor.WHITE, 50);
        particle.color.set(FlxColor.BLUE, FlxColor.PURPLE, FlxColor.WHITE);
        particle.launchMode = CIRCLE;
        particle.speed.set(150, 350);
        particle.lifespan.set(0.25, 0.5);
        parentState.add(particle);
        particle.start(true, 0, 50);

        new FlxTimer().start(0.5, function(_)
        {
            if (parentState != null) parentState.remove(particle);
            if (particle != null) particle.destroy();
        });
    }

    public function squishOutAndDestroy():Void
    {
        FlxTween.cancelTweensOf(scale);

        FlxTween.tween(scale, { x: 5.5, y: 0.25 }, 0.22,
        {
            ease: FlxEase.backIn,
            onComplete: function(_)
            {
                if (parentState != null) parentState.remove(this, true);
                destroy();
            }
        });

        FlxTween.tween(this, { alpha: 0 }, 0.35, { ease: FlxEase.quadOut });
    }
}