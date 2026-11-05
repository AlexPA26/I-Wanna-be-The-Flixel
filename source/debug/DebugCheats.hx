package debug;

import flixel.FlxG;
import main.ChapterState;
import main.PlayerData;
import main.RoomLoader;

class DebugCheats
{
	public static function handleDebugKeys(state:ChapterState):Void
	{
		#if !mobile
		if (FlxG.keys.justPressed.TAB)
		{
			FlxG.debugger.drawDebug = !FlxG.debugger.drawDebug;
		}

		var player = state.player;
		if (FlxG.keys.justPressed.K && player != null && player.exists && player.alive && player.active && !state.specialState)
		{
			if (PlayerData.currentChapter != 0)
			{
				state.killPlayer();
			}
		}

		if (FlxG.keys.justPressed.I)
		{
			state.inmortal = !state.inmortal;
			trace("Immortality toggled: " + state.inmortal);
		}

		if (FlxG.keys.justPressed.P)
		{
			trace("--- COIN STATUS ---");
			trace("Total Coins: " + PlayerData.getCoinCount());
			trace("IDs in memory: " + PlayerData.collectedCoins);
		}

		if (!state.fightingBoss)
		{
			if (FlxG.keys.justPressed.ONE)
			{
				PlayerData.currentChapter = 1;
				RoomLoader.loadRoom(state, "map01");
			}
			else if (FlxG.keys.justPressed.TWO)
			{
				PlayerData.currentChapter = 1;
				RoomLoader.loadRoom(state, "map16");
			}
			else if (FlxG.keys.justPressed.THREE)
			{
				PlayerData.currentChapter = 1;
				RoomLoader.loadRoom(state, "map35");
			}
			else if (FlxG.keys.justPressed.FOUR)
			{
				PlayerData.currentChapter = 1;
				RoomLoader.loadRoom(state, "map28");
			}
			else if (FlxG.keys.justPressed.FIVE)
			{
				PlayerData.currentChapter = 1;
				RoomLoader.loadRoom(state, "map43");
			}
			else if (FlxG.keys.justPressed.SIX)
			{
				PlayerData.currentChapter = 1;
				RoomLoader.loadRoom(state, "map43");
			}
			else if (FlxG.keys.justPressed.SEVEN)
			{
				PlayerData.currentChapter = 1;
				RoomLoader.loadRoom(state, "map50");
			}
			else if (FlxG.keys.justPressed.EIGHT)
			{
				PlayerData.currentChapter = 1;
				RoomLoader.loadRoom(state, "map23");
			}
			else if (FlxG.keys.justPressed.NINE)
			{
				PlayerData.currentChapter = 1;
				RoomLoader.loadRoom(state, "boss-jevil01");
			}
			else if (FlxG.keys.justPressed.ZERO)
			{
				PlayerData.currentChapter = 1;
				RoomLoader.loadRoom(state, "testing");
			}
		}
		#end
	}
}

