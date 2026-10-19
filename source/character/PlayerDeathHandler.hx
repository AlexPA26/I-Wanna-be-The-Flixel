package character;

import flixel.FlxG;
import flixel.effects.particles.FlxEmitter;
import flixel.util.FlxColor;
import gui.DeathState;
import main.ChapterState;
import main.PlayerData;

class PlayerDeathHandler
{
	public static function killPlayer(state:ChapterState):Void
	{
		var player = state.player;
		if (player == null)
			return;

		if (PlayerData.currentChapter == 0)
		{
			if (state.coopManager != null)
				state.coopManager.sendDeathPacket(state);

			player.x = 250;
			player.y = 450;
			player.velocity.set(0, 0);
			FlxG.sound.play(AssetPaths.warp__ogg, 0.75, false);
			FlxG.camera.shake(0.01, 0.2);
			if (state.whiteFade != null)
				state.whiteFade.alpha = 0.65;
			if (FlxG.sound.music != null)
				FlxG.sound.music.pitch = 1.0;

			return;
		}

		if (player.exists && player.alive)
		{
			if (FlxG.sound.music != null)
			{
				PlayerData.lastMusicTime = FlxG.sound.music.time;
				FlxG.sound.music.stop();
			}

			PlayerData.isRespawning = true;
			PlayerData.saveCooldown = 1.0;

			PlayerData.deathX = player.x;
			PlayerData.deathY = player.y;

			if (state.playerGlow != null)
				state.playerGlow.visible = false;

			player.kill();

			if (state.playerTrail != null)
			{
				state.playerTrail.kill();
			}

			state.persistentUpdate = true;
			PlayerData.totalDeaths -= 1;

			spawnBlood(state);

			var isJevilRoom = (state.currentBossName == "jevil");
			if (isJevilRoom)
			{
				if (state.jevil != null && state.jevil.ultimateManager != null)
				{
					state.jevil.ultimateManager.cancelBarrage();
				}

				state.openSubState(new KrisDeathState());
				return;
			}

			state.openSubState(new DeathState());
		}
	}

	public static function spawnBlood(state:ChapterState, ?x:Float, ?y:Float):Void
	{
		var spawnX = (x != null) ? x : PlayerData.deathX;
		var spawnY = (y != null) ? y : PlayerData.deathY;

		var blood = new FlxEmitter(spawnX, spawnY, 250);
		blood.makeParticles(3, 3, FlxColor.RED, 250);
		blood.launchMode = CIRCLE;
		blood.speed.set(300, 700);
		blood.acceleration.set(0, 1200);
		blood.lifespan.set(2, 4);
		blood.alpha.set(1, 1, 0, 0);
		blood.scale.set(0.5, 0.5, 1.5, 1.5);

		state.add(blood);
		blood.start(true, 0, 250);
	}
}

