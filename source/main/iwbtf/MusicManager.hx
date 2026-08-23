package main.iwbtf;

import flixel.FlxG;
import main.mods.ModLoader;

class MusicManager
{
    public static var loopPoints:Map<String, Float> = null;

    public static function initLoopPoints():Void
    {
        if (loopPoints != null) return;

        loopPoints = new Map<String, Float>();
        var fileContent:String = openfl.Assets.getText("assets/data/music/loopPoints.txt");

        if (fileContent != null)
        {
            var lines:Array<String> = fileContent.split("\n");
            for (line in lines)
            {
                var parts:Array<String> = line.split(":");
                if (parts.length == 2)
                {
                    var songName:String = StringTools.trim(parts[0]);
                    var loopTime:Float = Std.parseFloat(StringTools.trim(parts[1]));
                    loopPoints.set(songName, loopTime);
                }
            }
        }
    }

    public static function updateMusic(state:main.ChapterState):Void
    {
        if (state.player != null && !state.player.alive) return;
        if (state.subState != null) return;

        var musicLayer = state.tiledData.getLayer("music");
        if (musicLayer == null) return;
        
        var songName:String = musicLayer.properties.get("songName");
        var musicPitch:Float = 1.0;
        if (musicLayer.properties.contains("pitch"))
        {
            musicPitch = Std.parseFloat(musicLayer.properties.get("pitch"));
        }

        var relativePath = "music/chapters/chapter" + PlayerData.currentChapter + "bgm/" + songName + ".ogg";
        var songPath = ModLoader.getAsset(relativePath);

        #if sys
        var isModded:Bool = ModLoader.overrides.exists(relativePath);
        #else
        var isModded:Bool = false;
        #end

        initLoopPoints();
        var loopStartMs:Float = 0;

        if (!isModded && loopPoints.exists(songName))
        {
            loopStartMs = loopPoints.get(songName) * 1000;
        }

        if (PlayerData.currentSong == songPath && FlxG.sound.music != null && FlxG.sound.music.playing)
        {
            if (PlayerData.isRespawning)
            {
                FlxG.sound.music.time = PlayerData.lastMusicTime;
                PlayerData.isRespawning = false;
            }
            return;
        }

        PlayerData.currentSong = songPath;

        #if sys
        if (ModLoader.overrides.exists(relativePath))
        {
            var customSound = openfl.media.Sound.fromFile(songPath);
            if (customSound != null)
            {
                FlxG.sound.playMusic(customSound, 1, true);
            }
            else
            {
                FlxG.sound.playMusic("assets/" + relativePath, 1, true);
            }
        }
        else
        {
            FlxG.sound.playMusic(songPath, 1, true);
            FlxG.sound.music.pitch = musicPitch;
        }
        #else
        FlxG.sound.playMusic(songPath, 1, true);
        #end

        if (FlxG.sound.music != null)
        {
            FlxG.sound.music.loopTime = loopStartMs;
        }

        if (PlayerData.isRespawning)
        {
            if (FlxG.sound.music != null)
                FlxG.sound.music.update(0);

            FlxG.sound.music.time = PlayerData.lastMusicTime;
            PlayerData.isRespawning = false;
        }
    }
}