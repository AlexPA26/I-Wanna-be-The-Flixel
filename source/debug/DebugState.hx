package debug;

import flixel.FlxState;

class DebugState extends FlxState
{
    override public function create():Void
    {
        super.create();

        // add(new JevilCircusBG());
        add(new JevilBackground(1));
    }
}