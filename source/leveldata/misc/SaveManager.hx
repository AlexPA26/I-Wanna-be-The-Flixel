package leveldata.misc;

import main.PlayerData;

import haxe.Exception;
import flixel.util.FlxSave;

class SaveManager
{
    public static var save:FlxSave = new FlxSave();

    public static function saveGame():Void
    {
        trace("[SAVE] Game Saved on Map " + PlayerData.currentRoom);
        save.bind("IWBTF_Save1");
        save.data.totalSeconds = PlayerData.totalSeconds;
        save.data.chapterID = PlayerData.currentChapter;
        save.data.roomID = PlayerData.currentRoom;
        save.data.deaths = PlayerData.totalDeaths;
        save.data.spawnX = PlayerData.spawnX;
        save.data.spawnY = PlayerData.spawnY;
        save.data.skin = PlayerData.currentSkin;
        save.data.antialiasing = PlayerData.antialiasing;
        save.data.tutorialComplete = PlayerData.tutorialCompleted;
        save.data.vSync = PlayerData.vSync;
        save.data.showFPS = PlayerData.showFPS;

        /* Character Unlocks */
        save.data.reachedSewers = PlayerData.reachedSewers;

        if (PlayerData.collectedCoins != null)
        {
            save.data.collectedCoins = [for (coin in PlayerData.collectedCoins) coin];
        }
        save.flush();
    }

    public static function saveGameRestart():Void
    {
        trace("[SAVE] Game Saved on Map " + PlayerData.currentRoom);
        save.bind("IWBTF_Save1");
        save.data.totalSeconds = PlayerData.totalSeconds;
        save.data.chapterID = PlayerData.currentChapter;
        save.data.roomID = PlayerData.currentRoom;
        save.data.deaths = PlayerData.totalDeaths;
        save.data.spawnX = PlayerData.spawnX;
        save.data.spawnY = PlayerData.spawnY;
        save.data.skin = PlayerData.currentSkin;
        save.data.antialiasing = PlayerData.antialiasing;
        save.data.vSync = PlayerData.vSync;
        save.data.showFPS = PlayerData.showFPS;
        save.flush();
    }
    public static function loadGame():Bool
    {
        save.bind("IWBTF_Save1");
        
        if (save.data.roomID != null)
        {
            if (save.data.totalSeconds != null) PlayerData.totalSeconds = save.data.totalSeconds;
            PlayerData.currentChapter = save.data.chapterID;
            PlayerData.currentRoom = save.data.roomID;
            PlayerData.totalDeaths = save.data.deaths;

            PlayerData.spawnX = (save.data.spawnX != null && save.data.spawnX != 0) ? save.data.spawnX : 250;
            PlayerData.spawnY = (save.data.spawnY != null && save.data.spawnY != 0) ? save.data.spawnY : 450;

            if (save.data.tutorialCompleted != null)
            {
                PlayerData.tutorialCompleted = save.data.tutorialCompleted;
            }
            else if (save.data.tutorialComplete != null)
            {
                PlayerData.tutorialCompleted = save.data.tutorialComplete;
            }
            

            if (save.data.antialiasing != null) PlayerData.antialiasing = save.data.antialiasing;
            if (save.data.vSync != null) PlayerData.vSync = save.data.vSync;
            if (save.data.showFPS != null) PlayerData.showFPS = save.data.showFPS;

            /* Character Unlock */
            if (save.data.reachedSewers != null) PlayerData.reachedSewers = save.data.reachedSewers;

            if (save.data == null) 
            {
                trace("[SAVE] No data found on disk.");
                return false;
            }

            if (save.data.skin != null) 
            {
                PlayerData.currentSkin = save.data.skin;
                trace("[SKIN INFO] Skin changed to " + PlayerData.currentSkin);
            }

            if (save.data.collectedCoins != null)
            {
                var diskData:Array<Dynamic> = cast save.data.collectedCoins;
                PlayerData.collectedCoins = [for (id in diskData) Std.string(id)];
            }
            else
            {
                PlayerData.collectedCoins = [];
            }
            
            return true;
        }

        trace("[SAVE] No Save Data found. Creating fresh save defaults.");
        PlayerData.currentChapter = 0;
        PlayerData.currentRoom = "map01";
        PlayerData.tutorialCompleted = false;
        PlayerData.spawnX = 250;
        PlayerData.spawnY = 450;
        PlayerData.totalDeaths = 0;
        PlayerData.totalSeconds = 0;
        PlayerData.currentSkin = "thekid";
        return false;
    }



    public static function clearSaveData():Void
    {
        save.bind("IWBTF_Save1");
        save.erase();

        PlayerData.currentChapter = 0;
        PlayerData.currentRoom = "map01";
        PlayerData.tutorialCompleted = false;
        PlayerData.totalDeaths = 0;
        PlayerData.spawnX = 250;
        PlayerData.spawnY = 450;
        PlayerData.collectedCoins = [];
        PlayerData.totalSeconds = 0;
        PlayerData.currentSkin = "thekid";

        PlayerData.reachedSewers = false;
        saveGame(); 
    }
}