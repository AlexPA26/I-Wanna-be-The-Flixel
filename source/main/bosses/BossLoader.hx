package main.bosses;

import flixel.FlxG;
import main.ChapterState;
import main.bosses.ch1.BossJevil;

class BossLoader
{

    public static function spawnBoss(state:ChapterState, bossName:String):Void
    {
        if (state != null && state.currentBoss != null && state.currentBoss.exists && state.currentBoss.alive)
        {
            trace("BossLoader GUARD: Blocked an accidental duplicate spawn request for: " + bossName);
            return;
        }
        
        switch (bossName.toLowerCase())
        {
            case "reznor":
                trace("BossLoader: Reznor Spawned");
                
            case "jevil":
                var jevil = new Jevil(590, 200, state);
                state.currentBoss = jevil;
                state.add(jevil);
                state.add(jevil.shield);
                state.add(jevil.flash);
                
                trace("BossLoader: Jevil Spawned");

            case "":
                trace("BossLoader: No boss specified");
            default:
                trace("BossLoader: Unknown boss name: " + bossName);
        }
    }
}