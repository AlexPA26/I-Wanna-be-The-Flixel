package leveldata.blockdata;

import flixel.FlxSprite;
using flixel.util.FlxDirectionFlags;
using flixel.FlxG;

class MovingBlock extends FlxSprite
{
    var moveDir:String;
    var speed:Float;
    var activeMoving:Bool = false;

    public function new(X:Float, Y:Float, MoveDir:String, TileID:Int, speed:Int)
    {
        super(X, Y);
        loadGraphic(AssetPaths.ch1tiles__png, true, 50, 50);
        offset.set(0, 0);
        animation.frameIndex = TileID;
        
        this.moveDir = MoveDir;
        this.speed = speed;
        immovable = true;
    }

    public function stopMovement():Void
    {
        activeMoving = false;
        velocity.set(0, 0);
    }

    override public function update(elapsed:Float):Void
    {
        if (!activeMoving && touching.has(FlxDirectionFlags.UP))
        {
            FlxG.sound.play(AssetPaths.platform_activated__ogg, 0.5, false);
            activeMoving = true;
        }

        if (activeMoving)
        {
            switch (moveDir)
            {
                case "up":    velocity.y = -speed; 
                case "down":  velocity.y = speed;
                case "left":  velocity.x = -speed;
                case "right": velocity.x = speed;
            }
        }


        super.update(elapsed);

        if ((velocity.y < 0 && touching.has(UP)) || 
            (velocity.y > 0 && touching.has(DOWN)) || 
            (velocity.x < 0 && touching.has(LEFT)) || 
            (velocity.x > 0 && touching.has(RIGHT)))
        {
            stopMovement();
        }

        if (x < -500 || x > FlxG.worldBounds.width + 100 || y < -100 || y > FlxG.worldBounds.height + 100) { kill(); }

    
        touching = FlxDirectionFlags.NONE;
    }
}