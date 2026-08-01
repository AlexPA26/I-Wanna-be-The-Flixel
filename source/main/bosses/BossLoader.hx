package main.bosses;

import main.bosses.ch1.BossReznor.Reznor;
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
                var reznor = new Reznor(950, 400, state);
                state.currentBoss = reznor;
                state.add(reznor);
                state.add(reznor.flash);
                trace("BossLoader: Reznor Spawned");
                
            case "jevil":

                var coordsX = 900;
                var coordsY = 325;

                if (PlayerData.jevilDialogueRead) coordsX = 950;
                if (PlayerData.jevilDialogueRead) coordsY = 285;

                var jevil = new Jevil(coordsX, coordsY, state);
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