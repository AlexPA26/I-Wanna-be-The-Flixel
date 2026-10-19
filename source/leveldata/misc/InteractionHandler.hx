package leveldata.misc;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxDirectionFlags;
import flixel.util.FlxTimer;
import leveldata.blockdata.MovingBlock;
import leveldata.collectibles.RedCoin;
import leveldata.events.FlipSwitch;
import leveldata.events.NormalTrampoline;
import leveldata.events.NormalTrampolineMini;
import leveldata.events.SavePoint;
import leveldata.events.WarpTrigger;
import leveldata.hazards.FallingBlock;
import main.CameraManager;
import main.ChapterState;
import main.PlayerData;
import main.Player;
import main.RoomLoader;

class InteractionHandler
{
	public static function handleAllInteractions(state:ChapterState, elapsed:Float):Void
	{
		var player = state.player;
		if (player == null || !player.exists)
			return;

		// Map & static blocks collision
		if (state.map != null)
			FlxG.collide(player, state.map);
		if (state.slabs != null)
			FlxG.collide(player, state.slabs);
		if (state.solidBlock != null)
			FlxG.collide(player, state.solidBlock);
		if (state.invisBlock != null)
			FlxG.collide(player, state.invisBlock);

		// Triggers and collectibles
		if (state.warpsGroup != null)
			FlxG.overlap(player, state.warpsGroup, (p, w) -> handleWarp(state, cast w));
		if (state.savesGroup != null)
			FlxG.overlap(player, state.savesGroup, (p, s) -> handleSave(state, cast s));
		if (state.redCoinsGroup != null)
			FlxG.overlap(player, state.redCoinsGroup, (p, c) -> handleRedCoin(state, cast c));
		if (state.doubleJumpGroup != null)
			FlxG.overlap(player, state.doubleJumpGroup, (p, d) -> handleDoubleJump(player, cast d));
		if (state.portalGroup != null)
			FlxG.overlap(player, state.portalGroup, (p, pw) -> handleTutorialWarp(state, cast pw));
		if (state.invisPortalGroup != null)
			FlxG.overlap(player, state.invisPortalGroup, (p, ipw) -> handleInvisWarp(state, cast ipw));
		if (state.flipGroup != null)
			FlxG.overlap(player, state.flipGroup, (p, sw) -> handleFlipSwitch(player, cast sw));

		// Trampolines
		if (state.trampolines != null)
			FlxG.collide(player, state.trampolines, (p, t) -> handleTrampoline(player, cast t));
		if (state.trampolinesMini != null)
			FlxG.collide(player, state.trampolinesMini, (p, t) -> handleTrampolineMini(player, cast t));

		// Moving and falling platforms
		updatePlatforms(player, state.platforms, state.fallingBlock);

		if (state.platforms != null)
		{
			FlxG.collide(player, state.platforms);
			if (state.map != null)
			{
				FlxG.collide(state.platforms, state.map, (plat:MovingBlock, wall:FlxObject) ->
				{
					plat.stopMovement();
				});
			}
		}

		if (state.fallingBlock != null)
			FlxG.collide(player, state.fallingBlock);

		// Hazard overlaps
		checkHazards(state);

		// Fall out of bounds check
		if (state.map != null && (player.x > state.map.width + 100 || player.y > state.map.height + 100))
		{
			state.killPlayer();
		}
	}

	public static function handleWarp(state:ChapterState, w:WarpTrigger):Void
	{
		if (w == null)
			return;

		if (w.newChapter != null && w.newChapter != "")
		{
			PlayerData.currentChapter = Std.parseInt(w.newChapter);
		}

		RoomLoader.loadRoom(state, w.targetRoom);

		if (state.player != null && state.map != null)
		{
			switch (w.direction)
			{
				case "up":
					state.player.y = state.map.y + state.map.height - state.player.height - 60;
				case "down":
					state.player.y = state.map.y + 60;
				case "left":
					state.player.x = state.map.x + state.map.width - state.player.width - 60;
				case "right":
					state.player.x = state.map.x + 60;
			}

			var minX:Float = state.map.x + 20;
			var maxX:Float = state.map.x + state.map.width - state.player.width - 20;

			if (state.player.x < minX)
				state.player.x = minX;
			if (state.player.x > maxX)
				state.player.x = maxX;
		}

		CameraManager.resetWarpTarget(state);
		state.spawnTimer = 0.15;
	}

	public static function handleSave(state:ChapterState, saveObj:SavePoint):Void
	{
		if (saveObj != null && saveObj.alive)
		{
			if (PlayerData.currentRoom == state.currentRoomName)
			{
				saveObj.alive = false;
				saveObj.visible = false;
				saveObj.kill();
				return;
			}
			if (state.player != null)
			{
				PlayerData.spawnX = state.player.x;
				PlayerData.spawnY = state.player.y + 60;
			}
			PlayerData.currentRoom = state.currentRoomName;

			if (PlayerData.saveCooldown <= 0)
			{
				saveObj.pop(state.player);
				if (state.whiteFade != null)
					state.whiteFade.alpha = 0.5;
				FlxG.sound.play(AssetPaths.savedgame__ogg, 0.5, false);
				SaveManager.saveGame();
			}

			saveObj.alive = false;
			saveObj.visible = false;
			saveObj.kill();
		}
	}

	public static function handleRedCoin(state:ChapterState, redCoin:RedCoin):Void
	{
		if (redCoin == null || !redCoin.exists || !redCoin.alive)
			return;

		if (!PlayerData.isCoinCollected(redCoin.coinID))
		{
			trace("Pushing coin ID to memory: " + redCoin.coinID);
			PlayerData.collectedCoins.push(redCoin.coinID);
		}

		if (state.whiteFade != null)
			state.whiteFade.alpha = 0.5;
		redCoin.pop(state.player);
		trace("Collected coin with ID: " + redCoin.coinID);
		FlxG.sound.play(AssetPaths.coin__ogg, 0.5, false);
		redCoin.kill();
	}

	public static function handleDoubleJump(player:Player, doublejObj:DoubleJumpObj):Void
	{
		if (doublejObj != null && doublejObj.alive)
		{
			if (!player.canDoubleJump)
			{
				player.canDoubleJump = true;
			}
			doublejObj.kill();
		}
	}

	public static function handleFlipSwitch(player:Player, flipSwitchObj:FlipSwitch):Void
	{
		if (flipSwitchObj == null || !flipSwitchObj.alive)
			return;

		flipSwitchObj.kill();
		FlxG.sound.play(AssetPaths.flip__ogg);

		player.flipGravity();

		FlxTween.tween(FlxG.camera,
		{
			angle: player.isFlipped ? 180 : 0
		}, 0.5,
		{
			ease: FlxEase.sineInOut
		});
	}

	public static function handleTutorialWarp(state:ChapterState, portalLogic:TutorialWarp):Void
	{
		PlayerData.tutorialCompleted = true;
		PlayerData.currentRoom = "map01";
		PlayerData.currentChapter = 1;
		PlayerData.totalDeaths = 0;
		if (state.player != null)
			state.player.exists = false;

		if (state.whiteFade != null)
			state.whiteFade.alpha = 1;

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();
		FlxG.sound.play(AssetPaths.warp__ogg, 0.85, false);
		FlxG.camera.shake(0.01, 0.25);

		new FlxTimer().start(3, function(_)
		{
			if (state.blackFade != null)
			{
				FlxTween.tween(state.blackFade, {alpha: 1}, 3,
				{
					ease: FlxEase.quadOut,
					onComplete: function(_)
					{
						trace("Tutorial Complete!");
						SaveManager.saveGame();
						FlxG.switchState(animation.TutoralCutscene.new);
					}
				});
			}
		});
	}

	public static function handleInvisWarp(state:ChapterState, portalLogic:InvisWarp):Void
	{
		if (state.invisPortalGroup != null)
			state.invisPortalGroup.active = false;
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();
		FlxG.sound.play(AssetPaths.warp__ogg, 0.85, false);
		FlxG.sound.play(AssetPaths.jevil_hypnosis__ogg, 0.5, false);
		FlxG.camera.shake(0.01, 0.25);
		PlayerData.jevilDialogueRead = false;
		if (state.whiteFade != null)
			state.whiteFade.alpha = 1;

		RoomLoader.loadRoom(state, "boss-jevil01");

		var blur:openfl.filters.BlurFilter = new openfl.filters.BlurFilter(8, 8, 2);
		if (FlxG.camera.filters == null)
			FlxG.camera.filters = [];

		FlxG.camera.filters.push(blur);
		FlxTween.num(16, 0, 0.5, {ease: FlxEase.quadOut, onComplete: function(_)
		{
			if (FlxG.camera.filters != null)
			{
				FlxG.camera.filters.remove(blur);
				if (FlxG.camera.filters.length == 0)
					FlxG.camera.filters = null;
			}
		}},
		function(v:Float)
		{
			if (blur != null)
			{
				blur.blurX = v;
				blur.blurY = v;
			}
		});
	}

	public static function handleTrampoline(player:Player, tramp:NormalTrampoline):Void
	{
		if (player.touching == DOWN && tramp.touching == UP)
		{
			player.velocity.y = -1000;
			tramp.launch();
			FlxG.sound.play(AssetPaths.trampoline_bounce__ogg, 0.5, false);
		}
	}

	public static function handleTrampolineMini(p:Player, trampMini:NormalTrampolineMini):Void
	{
		if (trampMini.animation.curAnim != null && StringTools.startsWith(trampMini.animation.curAnim.name, "jump") && !trampMini.animation.finished)
		{
			return;
		}

		var hitFloor = p.touching.has(DOWN);
		var hitPlayerLeft = p.touching.has(LEFT);
		var hitPlayerRight = p.touching.has(RIGHT);

		switch (trampMini.launchDir)
		{
			case "up":
				if (hitFloor)
				{
					p.velocity.y = -730;
					p.canDoubleJump = true;
					trampMini.launch();
					FlxG.sound.play(AssetPaths.trampoline_bounce__ogg, 0.5);
				}

			case "left":
				if (hitPlayerLeft && !hitFloor)
				{
					p.maxVelocity.x = 800;
					p.velocity.x = 800;
					p.velocity.y = -600;
					p.canDoubleJump = true;
					trampMini.launch();
					FlxG.sound.play(AssetPaths.big_bounce__ogg, 0.5);
					FlxG.sound.play(AssetPaths.lateral_bounce__ogg, 0.5);
				}

			case "right":
				if (hitPlayerRight && !hitFloor)
				{
					p.maxVelocity.x = 800;
					p.velocity.x = -800;
					p.velocity.y = -600;
					p.canDoubleJump = true;
					trampMini.launch();
					FlxG.sound.play(AssetPaths.big_bounce__ogg, 0.5);
					FlxG.sound.play(AssetPaths.lateral_bounce__ogg, 0.5);
				}
		}
	}

	public static function updatePlatforms(player:Player, platforms:flixel.group.FlxGroup.FlxTypedGroup<MovingBlock>, fallingBlocks:flixel.group.FlxGroup.FlxTypedGroup<FallingBlock>):Void
	{
		if (platforms != null)
		{
			platforms.forEachAlive(function(plat:MovingBlock)
			{
				var deltaX = plat.x - plat.last.x;
				var deltaY = plat.y - plat.last.y;

				if (deltaX != 0 || deltaY != 0)
				{
					var playerBottom = player.y + player.height;
					var standingOnThis = player.x + player.width > plat.x &&
										 player.x < plat.x + plat.width &&
										 playerBottom >= plat.last.y - 4 &&
										 playerBottom <= plat.last.y + 8 &&
										 player.velocity.y >= 0;

					if (standingOnThis)
					{
						player.x += deltaX;
						player.y = plat.y - player.height;
						player.velocity.y = 0;
						player.isRidingPlatform = true;
						player.touching = FlxDirectionFlags.DOWN;
					}
				}
			});
		}

		if (fallingBlocks != null)
		{
			fallingBlocks.forEachAlive(function(plat:FallingBlock)
			{
				var deltaX = plat.x - plat.last.x;
				var deltaY = plat.y - plat.last.y;

				if (deltaX != 0 || deltaY != 0)
				{
					var playerBottom = player.y + player.height;
					var standingOnThis = player.x + player.width > plat.x &&
										 player.x < plat.x + plat.width &&
										 playerBottom >= plat.last.y - 4 &&
										 playerBottom <= plat.last.y + 8 &&
										 player.velocity.y >= 0;

					if (standingOnThis)
					{
						player.x += deltaX;
						if (plat.velocity.y <= 0)
						{
							player.y = plat.y - player.height;
							player.velocity.y = 0;
							player.isRidingPlatform = true;
							player.touching = FlxDirectionFlags.DOWN;
						}
					}
				}
			});
		}
	}

	public static function checkHazards(state:ChapterState):Void
	{
		var player = state.player;
		if (state.spawnTimer <= 0 && !state.inmortal && player != null && player.active && state.dangerObjects != null)
		{
			FlxG.overlap(player, state.dangerObjects, function(p:FlxObject, hazard:FlxObject)
			{
				if (FlxG.pixelPerfectOverlap(player, cast hazard))
				{
					state.killPlayer();
				}
			});
		}
	}
}

