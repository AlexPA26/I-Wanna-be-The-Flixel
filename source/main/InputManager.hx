package main;

import flixel.FlxG;
import flixel.input.gamepad.FlxGamepad;
import flixel.ui.FlxVirtualPad;

enum Action
{
    RESTART;
    SHOOT;
    PAUSE;
    FULLSCREEN;
    
    DEBUG_TOGGLE;
    DEBUG_KILL;
    DEBUG_INVINCIBLE;
    DEBUG_COIN_STATUS;
    COOP_TELEPORT;
    
    // Mobile Touch Overrides
    ANY_TOUCH;

    // Movement (for future implementation)
    LEFT;
    RIGHT;
    UP;
    DOWN;
    JUMP;

    // Jevil Boss Inputs

    JEVIL_SKIP_DIALOGUE;
    JEVIL_MENU_TOGGLE;
    JEVIL_MENU_CONFIRM;
    JEVIL_MENU_CANCEL;
    JEVIL_MENU_UP;
    JEVIL_MENU_DOWN;
}

class InputManager
{
    public static var virtualPad:FlxVirtualPad = null;

    public static function justPressed(action:Action):Bool
    {
        var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

        switch (action)
        {
            case RESTART:
                #if mobile
                return false;
                #else
                var padPress = (gamepad != null && (gamepad.justPressed.BACK));
                return FlxG.keys.justPressed.R || padPress;
                #end

            case SHOOT:
                #if mobile
                return virtualPad != null && virtualPad.buttonA.justPressed;
                #else
                var padPress = (gamepad != null && (gamepad.justPressed.RIGHT_TRIGGER || gamepad.justPressed.LEFT_TRIGGER));
                return FlxG.keys.justPressed.Z || padPress;
                #end

            case PAUSE:
                #if mobile
                return false;
                #else
                return FlxG.keys.justPressed.ESCAPE || (gamepad != null && gamepad.justPressed.START);
                #end

            case FULLSCREEN:
                #if mobile
                return false;
                #else
                return FlxG.keys.justPressed.F11 || (FlxG.keys.pressed.ALT && FlxG.keys.justPressed.ENTER);
                #end

            case ANY_TOUCH:
                #if mobile
                return FlxG.touches.justStarted().length > 0;
                #else
                return false;
                #end

            /* JEVIL CONTROLS */

            case JEVIL_SKIP_DIALOGUE:
                #if mobile
                var touchPress = FlxG.touches.justStarted().length > 0;
                var padPress = (virtualPad != null && virtualPad.buttonA.justPressed);
                return touchPress || padPress;
                #else
                var padPress = (gamepad != null && (gamepad.justPressed.A || gamepad.justPressed.B));
                return FlxG.keys.justPressed.Z || FlxG.keys.justPressed.ENTER || padPress;
                #end

            case JEVIL_MENU_TOGGLE:
                #if mobile return false; #else
                var padPress = (gamepad != null && gamepad.justPressed.LEFT_SHOULDER);
                return FlxG.keys.justPressed.TAB || padPress;
                #end

            case JEVIL_MENU_CONFIRM:
                #if mobile return false; #else
                var padPress = (gamepad != null && gamepad.justPressed.RIGHT_SHOULDER);
                return FlxG.keys.justPressed.Z || FlxG.keys.justPressed.ENTER || padPress;
                #end
                
            case JEVIL_MENU_CANCEL:
                #if mobile return false; #else
                var padPress = (gamepad != null && gamepad.justPressed.X);
                return FlxG.keys.justPressed.X || padPress;
                #end
                
            case JEVIL_MENU_UP:
                #if mobile return false; #else
                var padPress = (gamepad != null && (gamepad.justPressed.DPAD_UP || gamepad.justPressed.LEFT_STICK_DIGITAL_UP));
                return FlxG.keys.justPressed.ONE || padPress;
                #end

            case JEVIL_MENU_DOWN:
                #if mobile return false; #else
                var padPress = (gamepad != null && (gamepad.justPressed.DPAD_DOWN || gamepad.justPressed.LEFT_STICK_DIGITAL_DOWN));
                return FlxG.keys.justPressed.TWO || padPress;
                #end

            /* Debug and MISC lol */

            case DEBUG_TOGGLE:
                #if mobile return false; #else return FlxG.keys.justPressed.TAB; #end
            case DEBUG_KILL:
                #if mobile return false; #else return FlxG.keys.justPressed.K; #end
            case DEBUG_INVINCIBLE:
                #if mobile return false; #else return FlxG.keys.justPressed.I; #end
            case DEBUG_COIN_STATUS:
                #if mobile return false; #else return FlxG.keys.justPressed.P; #end
            case COOP_TELEPORT:
                #if mobile return false; #else return FlxG.keys.justPressed.F; #end
            
            default:
                return false;
        }
    }

    public static function pressed(action:Action):Bool
    {
        var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

        switch (action)
        {
            case LEFT:
                #if mobile
                return virtualPad != null && virtualPad.buttonLeft.pressed;
                #else
                var padPress = (gamepad != null && (gamepad.pressed.DPAD_LEFT || gamepad.analog.value.LEFT_STICK_X < -0.3));
                return FlxG.keys.pressed.LEFT || padPress;
                #end

            case RIGHT:
                #if mobile
                return virtualPad != null && virtualPad.buttonRight.pressed;
                #else
                var padPress = (gamepad != null && (gamepad.pressed.DPAD_RIGHT || gamepad.analog.value.LEFT_STICK_X > 0.3));
                return FlxG.keys.pressed.RIGHT || padPress;
                #end

            default:
                return false;
        }
    }
    

    public static function debugWarpPressed(numberKey:Int):Bool
    {
        #if !mobile
        return switch (numberKey) {
            case 1: FlxG.keys.justPressed.ONE;
            case 2: FlxG.keys.justPressed.TWO;
            case 3: FlxG.keys.justPressed.THREE;
            case 4: FlxG.keys.justPressed.FOUR;
            case 7: FlxG.keys.justPressed.SEVEN;
            case 8: FlxG.keys.justPressed.EIGHT;
            case 9: FlxG.keys.justPressed.NINE;
            case 0: FlxG.keys.justPressed.ZERO;
            default: false;
        }
        #else
        return false;
        #end
    }
}