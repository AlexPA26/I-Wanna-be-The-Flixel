package main;

class PlayerData
{
    public static var tutorialCompleted:Bool = false;
    public static var currentChapter:Int;
    public static var lastSaveRoom:String;
    public static var currentRoom:String = "";
    public static var currentSong:String = "";
    public static var totalSeconds:Float = 0;
    public static var collectedCoins:Array<String> = []; 
    public static var currentSkin:String = "thekid";
    public static var antialiasing:Bool = false;
    public static var vSync:Bool = false;
    public static var showFPS:Bool = true;

    public static var spawnX:Float = 250;
    public static var spawnY:Float = 700;
    public static var deathX:Float;
    public static var deathY:Float;
    public static var lastVelX:Float = 0;
    public static var lastVelY:Float = 0;
    public static var totalDeaths:Int;
    public static var lastMusicTime:Float = 0;
    public static var isRespawning:Bool = false;
    public static var saveCooldown:Float = 0;

    /* Cool Fades */

    public static var whiteFadeTrigger:Bool = false;
    public static var blackFadeTrigger:Bool = false;

    /* Character Unlocks */
    public static var reachedSewers:Bool = false;
    public static var reachedMorning:Bool = false;

    /* Boss Specifics */

    public static var jevilDialogueRead:Bool = false;

    /* Options */

    public static var enhancedVisuals:Bool = true;


    public static function isCoinCollected(id:String):Bool
    {
        return collectedCoins.indexOf(id) != -1;
    }

    public static function getCoinCount():Int
    {
        return collectedCoins.length;
    }

    public static function formatTime():String
    {
        var seconds:Int = Math.floor(totalSeconds);
        var h:Int = Math.floor(seconds / 3600);
        var m:Int = Math.floor((seconds % 3600) / 60);
        var s:Int = Math.floor(seconds % 60);

        var hh = (h < 10) ? "0" + h : "" + h;
        var mm = (m < 10) ? "0" + m : "" + m;
        var ss = (s < 10) ? "0" + s : "" + s;

        return hh + ":" + mm + ":" + ss;
    }

}