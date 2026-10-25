package main.bosses;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import main.ChapterState;
import main.bosses.ch1.BossJevil.Jevil;
import main.bosses.ch1.BossReznor.Reznor;
import main.bosses.ch1.BossReznor.ReznorMinion;

class BossCombatManager
{
	public static function initBossHUD(state:ChapterState, bossInstance:Jevil):Void
	{
		state.jevil = bossInstance;

		state.bossHpBar = new FlxBar((FlxG.width - 400) / 4, 20, LEFT_TO_RIGHT, 800, 20, state.jevil, "hp", 0, 120);
		state.bossHpBar.createFilledBar(0xFF551111, 0xFFFFFFFF, true, 0xFF000000);
		state.bossHpBar.screenCenter();
		state.bossHpBar.y = 10;
		state.bossHpBar.scrollFactor.set(0, 0);
		state.bossHpBar.visible = true;
		if (state.player != null && state.player.alive && state.player.active)
		{
			state.add(state.bossHpBar);
		}

		state.tpBar = new FlxBar(70, (FlxG.height / 2) - 250, BOTTOM_TO_TOP, 30, 300, state, "currentTP", 0, state.maxTP);
		state.tpBar.createFilledBar(0xff8b0d00, 0xFFFFA500, false, 0xFF000000);
		state.tpBar.scrollFactor.set(0, 0);
		if (state.player != null && state.player.alive && state.player.active)
		{
			state.add(state.tpBar);
		}

		state.tpBarDeco = new FlxSprite();
		state.tpBarDeco.loadGraphic(AssetPaths.jevil_tpBar__png, false);
		state.tpBarDeco.x = 20;
		state.tpBarDeco.y = 110;
		state.tpBarDeco.scrollFactor.set(0, 0);
		if (state.player != null && state.player.alive && state.player.active)
		{
			state.add(state.tpBarDeco);
		}

		state.tpText = new FlxText(state.tpBar.x + state.tpBar.width - 86, state.tpBar.y + (state.tpBar.height / 2) - 46, 0, "0", 22);
		state.tpText.setFormat("assets/fonts/deltarune.otf", 28, FlxColor.WHITE, "center", FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
		state.tpText.scrollFactor.set(0, 0);
		if (state.player != null && state.player.alive && state.player.active)
		{
			state.add(state.tpText);
		}

		state.grazeHitbox = new FlxSprite();
		state.grazeHitbox.loadGraphic(AssetPaths.glaze_boss__png, false);
		state.grazeHitbox.alpha = 0;
		state.grazeHitbox.y -= 5;
		state.add(state.grazeHitbox);

		state.currentTP = 0;
		state.grazedObjects = [];
	}

	public static function update(state:ChapterState, elapsed:Float):Void
	{
		updateGraze(state, elapsed);
		updateBossContact(state);
		updateBossTrigger(state);
		updateBulletCollisions(state);
	}

	static function updateGraze(state:ChapterState, elapsed:Float):Void
	{
		var player = state.player;
		var grazeHitbox = state.grazeHitbox;

		if (grazeHitbox == null || player == null || !player.exists)
			return;

		grazeHitbox.x = player.x + (player.width / 2) - (grazeHitbox.width / 2);
		grazeHitbox.y = player.y + (player.height / 2) - (grazeHitbox.height / 2);

		if (grazeHitbox.alpha > 0)
		{
			grazeHitbox.alpha -= elapsed * 3;
			if (grazeHitbox.alpha < 0)
				grazeHitbox.alpha = 0;
		}

		if (state.grazedObjects != null)
		{
			var i:Int = state.grazedObjects.length;
			while (i-- > 0)
			{
				var obj = state.grazedObjects[i];
				if (obj == null || !obj.exists || !obj.alive)
				{
					state.grazedObjects.splice(i, 1);
				}
			}
		}

		if (state.fightingBoss && !state.inmortal && state.jevil != null)
		{
			if (state.jevil.state != "attackingCube" && state.jevil.state != "returningCube" && state.dangerObjects != null)
			{
				FlxG.overlap(grazeHitbox, state.dangerObjects, function(hitbox:FlxObject, hazard:FlxObject)
				{
					if (state.grazedObjects != null && !state.grazedObjects.contains(hazard))
					{
						state.grazedObjects.push(hazard);
						state.currentTP += state.jevil.tpIncrease;
						if (state.currentTP > state.maxTP)
							state.currentTP = state.maxTP;

						grazeHitbox.alpha = 0.4;
						FlxG.sound.play(AssetPaths.jevil_graze__ogg, 0.8, false);
					}
				});
			}
		}

		if (state.tpText != null && state.tpText.exists)
		{
			if (state.currentTP >= state.maxTP)
			{
				state.tpText.text = "MAX";
				state.tpText.color = FlxColor.YELLOW;
			}
			else
			{
				state.tpText.text = Std.string(Std.int(state.currentTP));
				state.tpText.color = FlxColor.WHITE;
			}
		}
	}

	static function updateBossContact(state:ChapterState):Void
	{
		var currentBoss = state.currentBoss;
		var player = state.player;

		if (currentBoss == null || !currentBoss.exists || !currentBoss.alive || !currentBoss.visible || currentBoss.alpha <= 0)
			return;

		if (state.inmortal || state.spawnTimer > 0 || player == null || !player.exists || !player.alive)
			return;

		if (Std.isOfType(currentBoss, Jevil))
		{
			var jevilBoss:Jevil = cast currentBoss;
			if (jevilBoss.state != "waiting" && 
				jevilBoss.state != "precutscene" && 
				jevilBoss.state != "cutscene" && 
				jevilBoss.state != "startCube" && 
				jevilBoss.state != "attackingCube" && 
				jevilBoss.state != "returningCube" &&
				jevilBoss.state != "ultimate_cutscene" &&
				jevilBoss.state != "ultimate_transition" &&
				jevilBoss.state != "ultimate_barrage" &&
				jevilBoss.state != "dead")
			{
				FlxG.overlap(player, currentBoss, function(p, b)
				{
					if (FlxG.pixelPerfectOverlap(player, jevilBoss))
					{
						state.killPlayer();
					}
				});
			}
		}
	}

	static function updateBossTrigger(state:ChapterState):Void
	{
		var currentBoss = state.currentBoss;
		var player = state.player;
		var map = state.map;

		if (currentBoss != null && player != null && map != null && Std.isOfType(currentBoss, Jevil))
		{
			var bossJevil:Jevil = cast currentBoss;
			if (bossJevil.state == "waiting" && player.x > map.x + (map.width / 3))
			{
				bossJevil.preCutscene();
			}
		}
	}

	static function updateBulletCollisions(state:ChapterState):Void
	{
		var currentBoss = state.currentBoss;
		var bullets = state.bullets;

		if (currentBoss == null || !currentBoss.exists || !currentBoss.alive || bullets == null)
			return;

		if (state.currentBossName == "reznor")
		{
			var reznorBoss:Reznor = cast currentBoss;
			if (reznorBoss.status != "waiting" && reznorBoss.status != "cutscene")
			{
				for (minion in reznorBoss.minions)
				{
					if (minion != null && minion.alive && minion.exists)
					{
						FlxG.overlap(bullets, minion, function(bullet, m)
						{
							var rm:ReznorMinion = cast m;
							rm.takeDamage(1);
							bullet.kill();
						});
					}
				}
			}
		}
		else
		{
			FlxG.overlap(bullets, currentBoss, function(bullet, boss)
			{
				if (Std.isOfType(boss, Jevil))
				{
					var jevilBoss:Jevil = cast boss;
					if (jevilBoss.isVulnerable)
					{
						var jCenterX = jevilBoss.x + (jevilBoss.width / 2);
						var jCenterY = jevilBoss.y + (jevilBoss.height / 2);

						var bCenterX = bullet.x + (bullet.width / 2);
						var bCenterY = bullet.y + (bullet.height / 2);

						var dx = bCenterX - jCenterX;
						var dy = bCenterY - jCenterY;
						var distance = Math.sqrt((dx * dx) + (dy * dy));

						if (distance < 50)
						{
							var isCrit = FlxG.random.int(1, 14) == 1;
							var damage = isCrit ? 2 : 1;
							jevilBoss.takeDamage(damage, false);
							jevilBoss.jevilWasHit = true;
							bullet.kill();
						}
					}
				}
				else
				{
					var invul:Bool = Reflect.field(boss, "isInvulnerable");
					if (!invul)
					{
						bullet.kill();
					}
				}
			});
		}
	}
}

