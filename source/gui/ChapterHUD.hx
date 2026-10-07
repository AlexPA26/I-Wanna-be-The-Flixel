package gui;

import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;
import main.PlayerData;

class ChapterHUD extends FlxGroup
{
    public var timeElapsed:FlxText;
    public var playerDeaths:FlxText;
    public var currentChapter:FlxText;
    public var lastSave:FlxText;

    public function new()
    {
        super();
        setupHUD();
    }

    function setupHUD():Void
    {
        #if debug
        currentChapter = new FlxText(50, FlxG.height - 90, 0, "Chapter: ", 18);
        currentChapter.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        currentChapter.scrollFactor.set(0, 0);
        currentChapter.alpha = 0.5;
        add(currentChapter);

        lastSave = new FlxText(50, FlxG.height - 60, 0, "Last Save: ", 18);
        lastSave.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        lastSave.scrollFactor.set(0, 0);
        lastSave.alpha = 0.5;
        add(lastSave);
        #end

        #if mobile
        playerDeaths = new FlxText(FlxG.width - 260, 30, 0, "Total Deaths: ", 22);
        #else
        playerDeaths = new FlxText(FlxG.width - 260, FlxG.height - 80, 0, "Total Resets: ", 22);
        #end
        playerDeaths.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        playerDeaths.scrollFactor.set(0, 0);
        playerDeaths.alpha = 0.5;
        playerDeaths.visible = false;
        add(playerDeaths);

        timeElapsed = new FlxText(50, 20, 0, "Time: 00:00:00", 22);
        timeElapsed.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        timeElapsed.scrollFactor.set(0, 0);
        timeElapsed.visible = false;
        add(timeElapsed);
    }

    public function updateTimeAndDeaths(playerExists:Bool, isAlive:Bool, playerDeathsTrigger:Bool):Void
    {
        if (timeElapsed != null)
        {
            timeElapsed.text = "Time: " + PlayerData.formatTime();
        }

        if (PlayerData.currentChapter >= 1 && playerExists && isAlive && !playerDeathsTrigger)
        {
            playerDeaths.visible = true;
            playerDeaths.text = "Total Resets: " + PlayerData.totalDeaths;
        }
        else if (playerDeathsTrigger)
        {
            playerDeaths.visible = false;
        }
    }
}