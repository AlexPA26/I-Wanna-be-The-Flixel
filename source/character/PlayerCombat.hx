package character;

import flixel.FlxG;
import flixel.FlxSprite;
import main.ChapterState;
import main.Player;

class PlayerCombat
{
	public static function shoot(state:ChapterState):Void
	{
		var player = state.player;
		if (player == null || !player.active || player.alpha == 0 || !player.visible)
			return;

		var bullet = new FlxSprite();
		bullet.loadGraphic(AssetPaths.bullet__png, false);
		state.add(bullet);

		if (!Player.isFacingRIGHT)
		{
			bullet.velocity.x = -800;
			bullet.x = player.x - 20;
			bullet.y = player.y + 4;
		}
		else
		{
			bullet.velocity.x = 800;
			bullet.x = player.x + 30;
			bullet.y = player.y + 4;
		}

		if (state.bullets != null)
		{
			state.bullets.add(bullet);
		}

		FlxG.sound.play(AssetPaths.playershoot__ogg, 1, false);
	}

	public static function updateBullets(state:ChapterState):Void
	{
		var bullets = state.bullets;
		if (bullets == null)
			return;

		bullets.forEachAlive(function(bullet)
		{
			if (!bullet.isOnScreen())
			{
				bullet.kill();
			}
		});

		if (state.map != null)
		{
			FlxG.collide(bullets, state.map, function(bullet, wall)
			{
				bullet.kill();
			});
		}
	}
}

