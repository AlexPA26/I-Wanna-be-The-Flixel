package main;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.particles.FlxEmitter;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxVirtualPad;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import main.mods.ModLoader;
import openfl.display.BitmapData;


class Player extends FlxSprite
{
    public var canJump:Bool = true;
    public var canDoubleJump:Bool = true;
    public var doubleJumpEffect:FlxEmitter;
    public var isRidingPlatform:Bool = false;
    public var isGrounded:Bool = false;

    var safeJump:Float = 0;
    var safeJumpMax:Float = 0.1;
    public var mapMaxSpeed:Float = 400;
    public var currentOffsetY:Float = 20;

    public var isFlipped:Bool = false;
    public var controlsReversed:Bool = false;
    var isFlipping:Bool;
    var flippingTimer:Float;
    static var baseOffsetY:Null<Float> = null;
    var tapTimer:Float = 0;
    var tapCount:Int = 0;
    var idleTimer:Float = 1;

    var animationJumpUp:Bool = false;
    var animationJumpDown:Bool = false;

    public var inputLeft:Bool = false;
    public var inputRight:Bool = false;
    public var inputJump:Bool = false;
    public var inputJumpReleased:Bool = false;

    public var pad:FlxVirtualPad;

    public static var isFacingRIGHT:Bool = true;
    public static var lastFacing:FlxDirectionFlags = RIGHT;

    public function new(x:Float, y:Float)
    {
        super(x, y);

        ModLoader.loadModGraphic(this, "images/skins/" + PlayerData.currentSkin + ".png", "skin_" + PlayerData.currentSkin, 50, 50);
        animation.add("idle", [0, 1, 2, 3], 11, true);
        animation.add("jumpUp", [6], 16, false);
        animation.add("jumpDown", [7], 1, false);
        animation.add("walking", [8, 9, 10, 11, 12, 13], 24, true);
        
        width = 20; 
        height = 30;
        offset.set(20, 20);

        setFacingFlip(LEFT, true, false);
        setFacingFlip(RIGHT, false, false);

        drag.x = 4000; 
        maxVelocity.set(mapMaxSpeed, 1000);
        acceleration.y = 2500;

        doubleJumpEffect = new FlxEmitter(0, 0, 50);
        doubleJumpEffect.loadParticles(AssetPaths.particle__png, 5);
        doubleJumpEffect.lifespan.set(0.4, 0.8);
        doubleJumpEffect.velocity.set(-100, -50, 100, 50);
        doubleJumpEffect.scale.set(1.2, 1.2, 1.2, 1.2);
        doubleJumpEffect.alpha.set(1, 1, 0, 0);
        doubleJumpEffect.launchMode = CIRCLE;

    }

public function flipGravity():Void
{
    isFlipped = !isFlipped;

    if (baseOffsetY == null)
    {
        baseOffsetY = offset.y;
    }

    isFlipping = true;
    flippingTimer = 0.35;

    #if !mobile
    FlxG.keys.enabled = false;
    #end
    velocity.y = 0;

    setFacingFlip(LEFT, true, isFlipped);
    setFacingFlip(RIGHT, false, isFlipped);

    flipY = isFlipped;

    var targetOffsetY:Float = isFlipped ? 0 : baseOffsetY; 

    FlxTween.tween(this.offset, { y: targetOffsetY }, 0.2, { ease: FlxEase.sineInOut });
}

    override public function update(elapsed:Float):Void
    {
        updateInputs();
        
        acceleration.x = 0;
        maxVelocity.x = mapMaxSpeed;

        var floorDir:FlxDirectionFlags = isFlipped ? UP : DOWN;
        var gravMult:Int = isFlipped ? -1 : 1;
        isGrounded = isTouching(floorDir) || isRidingPlatform;

        if (tapTimer > 0)
        {
            tapTimer -= elapsed;
            if (tapTimer <= 0) tapCount = 0;
        }

        if (isFlipping)
        {
            flippingTimer -= elapsed;
            velocity.y = 0;
            
            if (flippingTimer <= 0)
            {
                isFlipping = false;
                #if !mobile
                FlxG.keys.enabled = true;
                #end
            }
        }
        
        if (isGrounded)
        {
            safeJump = safeJumpMax;
            canDoubleJump = true;
            drag.x = 4000;
            animationJumpUp = false;
            animationJumpDown = false;
        }
        else
        {
            safeJump -= elapsed;
        }

        var jumpPressed = inputJump;
        var left = inputLeft;
        var right = inputRight;

        if (left) 
        { 
            acceleration.x = -1500; 
            facing = LEFT;
            offset.x = 10;
            isFacingRIGHT = false;
        }
        else if (right) 
        { 
            acceleration.x = 1500; 
            facing = RIGHT;
            offset.x = 20;
            isFacingRIGHT = true;
        }

         acceleration.y = 2000 * gravMult;
            
        if (left) { acceleration.x = -4000; facing = LEFT; }
        else if (right) { acceleration.x = 4000; facing = RIGHT; }

        if (jumpPressed && canJump)
        {
            if (safeJump > 0) 
            {
                velocity.y = -650 * gravMult; 
                safeJump = 0;
                FlxG.sound.play(AssetPaths.jump__ogg, 0.75);
                animationJumpUp = true;
                animationJumpDown = false;
                    
				leveldata.hazards.SwitchSpike.toggleAll();
            }

            else if (canDoubleJump) 
            {
                    doubleJumpEffect.setPosition(x + (width / 2), y + (isFlipped ? 0 : height));
                    doubleJumpEffect.start(true, 0, 10);
                    canDoubleJump = false;
                    velocity.y = -600 * gravMult;
                    FlxG.sound.play(AssetPaths.doublejump__ogg, 0.75);
                    animationJumpUp = true;
					animationJumpDown = false;
            }
        }
        

        if (maxVelocity.x > 400)
        {
            maxVelocity.x -= 600 * elapsed; 
            if (maxVelocity.x < 400) maxVelocity.x = 400;
        }

        if (isGrounded) 
        {
            maxVelocity.x = mapMaxSpeed;
            drag.x = 4000;
        }

        super.update(elapsed);

        if (idleTimer != 0)
        {
            idleTimer -= 0.05;
        }

        var isMovingUp = isFlipped ? (velocity.y > 0) : (velocity.y < 0);
        if (inputJumpReleased && isMovingUp)
        {
            velocity.y *= 0.8;
            animationJumpDown = true;
            animationJumpUp = false;
        }
        else if (!isGrounded && Math.abs(velocity.y) > 50) 
        {
            if (isMovingUp) animation.play("jumpUp");
            else animation.play("jumpDown");
        }
        else 
        {
            if (Math.abs(velocity.x) > 20) animation.play("walking");
            else animation.play("idle");
        }
        isRidingPlatform = false;
    }

    function updateInputs():Void
    {
        inputLeft = false;
        inputRight = false;
        inputJump = false;
        inputJumpReleased = false;
        var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

        #if !mobile
        inputLeft = FlxG.keys.anyPressed([LEFT, A]);
        inputRight = FlxG.keys.anyPressed([RIGHT, D]);
        inputJump = FlxG.keys.anyJustPressed([SPACE, UP, W]) || FlxG.mouse.justPressed;
        inputJumpReleased = FlxG.keys.anyJustReleased([SPACE, UP, W]) || FlxG.mouse.justReleased;
        #end

        if (gamepad != null)
        {
            if (gamepad.pressed.DPAD_LEFT || gamepad.analog.value.LEFT_STICK_X < -0.25) inputLeft = true;

            if (gamepad.pressed.DPAD_RIGHT || gamepad.analog.value.LEFT_STICK_X > 0.25) inputRight = true;

            if (gamepad.justPressed.A || gamepad.justPressed.B) inputJump = true;

            if (gamepad.justReleased.A || gamepad.justReleased.B) inputJumpReleased = true;

        }
        #if mobile
        if (pad != null)
        {
            inputLeft = pad.buttonLeft.pressed;
            inputRight = pad.buttonRight.pressed;
        }

        for (touch in FlxG.touches.list)
        {
            if (touch.justPressed)
            {
                var onPad = false;
                if (pad != null)
                {
                    if (pad.buttonLeft.overlapsPoint(touch.getScreenPosition()) || 
                        pad.buttonRight.overlapsPoint(touch.getScreenPosition()) || 
                        pad.buttonA.overlapsPoint(touch.getScreenPosition())) 
                        onPad = true;
                }

                if (!onPad)
                {
                    tapTimer = 0.125;
                    inputJump = true;
                    tapCount++;
                   
                }
            }
        }
        #end

        if (controlsReversed)
        {
            var temp = inputLeft;
            inputLeft = inputRight;
            inputRight = temp;
        }
    }
}