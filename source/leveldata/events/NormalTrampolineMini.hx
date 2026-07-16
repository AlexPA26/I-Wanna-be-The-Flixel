package leveldata.events;

import flixel.FlxSprite;

class NormalTrampolineMini extends FlxSprite
{
    public var launchDir:String;

    public function new(x:Float, y:Float, dir:String)
    {
        super(x, y);
        this.launchDir = dir;
        loadGraphic(AssetPaths.trampoline_mini__png, true, 50, 50);
        
        animation.add("idle_up", [0], 0, false);
        animation.add("jump_up", [2, 1, 0], 16, false);
        
        animation.add("idle_left", [3], 0, false);
        animation.add("jump_left", [5, 4, 3], 16, false);
        
        animation.add("idle_right", [6], 0, false);
        animation.add("jump_right", [8, 7, 6], 16, false);

        animation.play("idle_" + launchDir);

        immovable = true;
    }

public function launch():Void
{
    animation.play("jump_" + launchDir);
}
}