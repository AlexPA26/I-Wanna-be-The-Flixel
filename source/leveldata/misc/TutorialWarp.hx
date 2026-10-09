package leveldata.misc;

import flixel.util.FlxColor;
import flixel.effects.particles.FlxEmitter;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;

class TutorialWarp extends FlxSprite
{
	var onTweenComplete(default, null):Null<TweenCallback>;
    public var particles:FlxEmitter;

    public function new(x:Float, y:Float)
    {
        super(x, y);
        scale.set(1.25, 1.25);
        updateHitbox();
        loadGraphic(AssetPaths.portal__png, false, 128, 128);
        FlxTween.angle(this, 0, 360, 4.0, { type: LOOPING } );

        particles = new FlxEmitter(x, y, 10);
        particles.makeParticles(4, 4, FlxColor.WHITE, 10);
        particles.color.set(0xFFBEF5FF, 0xFFB7FFE7, 0xFFFFFBC4, 0xFFFFB7B7);
        particles.lifespan.set(0.4, 0.8);
        particles.velocity.set(100, 70, 0, 0);
        particles.scale.set(1.2, 1.2, 1.2, 1.2);
        particles.alpha.set(1, 1, 0, 0);
        particles.launchMode = CIRCLE;
        particles.setPosition(x, y);
        particles.start(false, 0, 20);


    }

    
}