package main;

import shaders.ShaderLoader;
import main.bosses.BossLoader;
import flixel.FlxG;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.effects.particles.FlxEmitter;
import flixel.tile.FlxTilemap;
import leveldata.background.BackgroundManager;
import leveldata.events.EventLoader;
import leveldata.events.ObjectLoader;
import leveldata.events.SavePoint;
import main.ChapterState;
import main.PlayerData;

class RoomLoader
{
	public static function loadRoom(state:ChapterState, roomName:String):Void
	{
		flixel.tweens.FlxTween.globalManager.forEach(function(twn) twn.cancel());

		if (state.roomAcid != null)
		{
			state.remove(state.roomAcid);
			state.roomAcid.destroy();
			state.roomAcid = null;
		}
		#if !mobile
		var chartPath = "assets/data/chapters/chapter" + PlayerData.currentChapter + "/ch" + PlayerData.currentChapter + "-" + roomName + ".tmx";
		#else
		var chartPath = "assets/data/chapters_mobile/chapter" + PlayerData.currentChapter + "/ch" + PlayerData.currentChapter + "-" + roomName + "-mobile" + ".tmx";
		#end

		state.currentRoomName = roomName;

		if (roomName == "map25" && PlayerData.currentChapter == 1)
		{
			if (!PlayerData.reachedSewers)
			{
				PlayerData.reachedSewers = true;
				trace("Sewers reached! New Skin Unlocked.");
			}
		}

		if (roomName == "map43" && PlayerData.currentChapter == 1)
		{
			if (!PlayerData.reachedMorning)
			{
				PlayerData.reachedMorning = true;
				trace("Castle Morning reached! New Skin Unlocked.");
			}
		}

		// ##########################

		if (chartPath != null) state.tiledData = new TiledMap(chartPath);

		if (state.map != null)
		{
			state.remove(state.map);
			state.map.destroy();
		}
		if (state.mapDeco != null)
		{
			state.remove(state.mapDeco);
			state.mapDeco.destroy();
		}
		if (state.mapDeco2 != null)
		{
			state.remove(state.mapDeco2);
			state.mapDeco2.destroy();
		}

		var mainLayer:TiledTileLayer = cast state.tiledData.getLayer("tiles-main");
		state.map = new FlxTilemap();
		state.map.loadMapFromArray(mainLayer.tileArray, state.tiledData.width, state.tiledData.height, state.mainTilesPath, 50, 50, OFF, 1);
		state.map.x = -60;
		state.map.y = -65;
		FlxG.worldBounds.set(state.map.x, state.map.y, state.map.width, state.map.height);
		state.add(state.map);

		var decoLayer = state.tiledData.getLayer("tiles-deco");
		if (decoLayer != null)
		{
			state.mapDeco = new FlxTilemap();
			state.mapDeco.loadMapFromArray(cast(decoLayer, TiledTileLayer).tileArray, state.tiledData.width, state.tiledData.height, state.mainTilesPath, 50, 50, OFF, 1);
			state.mapDeco.x = -60;
			state.mapDeco.y = -65;
			state.add(state.mapDeco);
		}

		var decoLayer2 = state.tiledData.getLayer("tiles-deco2");
		if (decoLayer2 != null)
			{
			state.mapDeco2 = new FlxTilemap();
			state.mapDeco2.loadMapFromArray(cast(decoLayer2, TiledTileLayer).tileArray, state.tiledData.width, state.tiledData.height, state.mainTilesPath, 50, 50, OFF, 1);
			state.mapDeco2.x = -60;
			state.mapDeco2.y = -65;
			state.add(state.mapDeco2);
		}

		trace("Teleported to: " + chartPath);

		FlxG.bitmap.clearUnused();
		state.redCoinsGroup.clear();
		state.redCoinParticlesGroup.clear();
		state.dangerObjects.clear();
		state.doubleJumpGroup.clear();
		state.flipGroup.clear();
		state.portalGroup.clear();
		state.invisPortalGroup.clear();
		state.warpsGroup.clear();
		state.platforms.clear();
		state.trampolines.clear();
		state.trampolinesMini.clear();
		state.lightsGroup.clear();
		state.fallingBlock.clear();
		state.solidBlock.clear();
		state.invisBlock.clear();
		state.slabs.clear();
		state.popups.clear();
		state.saveParticlesGroup.clear();
		state.redCoinParticlesGroup.clear();
		state.hud.clear();
		state.eventEffectGroup.clear();

		if (state.currentBoss != null && state.currentBossName != "jevil")
		{
			state.remove(state.currentBoss, true);
			state.currentBoss.destroy();
		}
		state.currentBoss = null;

		leveldata.hazards.SwitchSpike.clear();

		if (state.roomImages != null)
		{
			state.roomImages.forEach(function(img:flixel.FlxSprite) 
			{
				if (img != null) 
				{
					flixel.tweens.FlxTween.cancelTweensOf(img);
					img.destroy();
				}
			});
			state.roomImages.clear();
		}
		
		if (state.saveParticlesGroup != null)
		{
			state.saveParticlesGroup.forEachExists(function(p:FlxEmitter)
			{
				p.active = false;
				p.visible = false;
				p.exists = false;
			});
			state.saveParticlesGroup.clear();
		}

		if (state.redCoinParticlesGroup != null)
		{
			state.redCoinParticlesGroup.forEachExists(function(p:FlxEmitter)
			{
				p.active = false;
				p.visible = false;
				p.exists = false;
			});
			state.redCoinParticlesGroup.clear();
		}

		if (state.redCoinsGroup != null)
		{
			state.redCoinsGroup.forEach(function(c:leveldata.collectibles.RedCoin)
			{
				c.destroy();
			});
			state.redCoinsGroup.clear();
		}

		if (state.savesGroup != null)
		{
			state.savesGroup.forEachExists(function(s:SavePoint)
			{
				s.exists = false;
			});
			state.savesGroup.clear();
		}

		state.bullets.forEachAlive((bullet) -> { bullet.kill(); });

		ObjectLoader.loadEverything(state.tiledData, state, state.map.x, state.map.y);
		ShaderLoader.loadShaders(state.tiledData, state);
		EventLoader.loadEvents(state.tiledData, state);
		state.add(state.redCoinsGroup);
		state.add(state.redCoinParticlesGroup);
		state.add(state.slabs);
		state.add(state.playerTrail);

		var bossLayer = state.tiledData.getLayer("boss");
		if (bossLayer != null)
		{
			if (bossLayer.properties.contains("bossName"))
			{
				var name = bossLayer.properties.get("bossName");
				BossLoader.spawnBoss(state, name);
			}
		}


		state.add(state.roomImages);
		state.add(state.player);

		for (rPlayer in state.coopManager.remotePlayers)
		{
			if (rPlayer != null)
			{
				state.remove(rPlayer);
				state.add(rPlayer);
				if (rPlayer.usernameText != null)
				{
					state.remove(rPlayer.usernameText);
					state.add(rPlayer.usernameText);
				}
			}
		}

		state.add(state.dangerObjects);
		state.add(state.player.doubleJumpEffect);
		state.add(state.doubleJumpGroup);
		state.add(state.saveParticlesGroup);
		state.add(state.savesGroup);
		state.add(state.popups);
		state.add(state.warpsGroup);
		state.add(state.platforms);
		state.add(state.solidBlock);
		state.add(state.invisBlock);
		state.add(state.fallingBlock);
		state.add(state.flipGroup);
		state.add(state.portalGroup);
		state.add(state.invisPortalGroup);
		state.add(state.trampolines);
		state.add(state.trampolinesMini);
		state.add(state.playerGlow);
		state.add(state.eventEffectGroup);
		state.add(state.hud);
		state.cameraSnapTimer = 1;

		state.savesGroup.forEach(function(save:SavePoint)
		{
			state.saveParticlesGroup.add(save.particle);
		});

		BackgroundManager.updateAllEffects(state, state.tiledData);

		/**Remote player logic (re-add after BG effects so they stay on top)**/
		for (rPlayer in state.coopManager.remotePlayers)
		{
			if (rPlayer != null) {
				state.remove(rPlayer);
				state.add(rPlayer);
				if (rPlayer.usernameText != null) {
					state.remove(rPlayer.usernameText);
					state.add(rPlayer.usernameText);
				}
			}
		}

		state.add(state.lightsGroup);
		state.hudGroup.add(state.chapterHUD.currentChapter);
		state.hudGroup.add(state.chapterHUD.lastSave);
		state.hudGroup.add(state.chapterHUD.playerDeaths);
		state.autoScroll();
		state.cameraScroll();
		main.iwbtf.MusicManager.updateMusic(state);
		state.add(state.blackFade);
		state.add(state.whiteFade);

		#if !debug
			PlayerData.saveCooldown = 0.1;
			state.spawnTimer = 0.1;
		#else
			PlayerData.saveCooldown = 9999;
			state.spawnTimer = 0.1;
		#end

		state.hudGroup.clear();
		state.hudGroup.add(state.virtualPad);
		state.hudGroup.add(state.chapterHUD.currentChapter);
		state.hudGroup.add(state.chapterHUD.lastSave);
		state.hudGroup.add(state.chapterHUD.playerDeaths);
		state.add(state.hudGroup);
		state.layoutVirtualPad();
		state.virtualPad.active = false;
		state.virtualPad.visible = false;

		#if mobile
		state.virtualPad.visible = true;
		state.virtualPad.active = true;
		state.player.pad = state.virtualPad;
		// state.player.pad.alpha = state.padAlpha;
		#end

		if (state.chapterHUD.currentChapter != null)
		{
			state.chapterHUD.currentChapter.text = "Chapter: " + PlayerData.currentChapter;
		}
			

		#if mobile
		{
			// if (playerDeaths != null) playerDeaths.text = "Total Deaths: " + PlayerData.totalDeaths;
		}
		#else

		if (state.chapterHUD.playerDeaths != null)
		{
			state.chapterHUD.playerDeaths.text = "Total Resets: " + PlayerData.totalDeaths;
		}
			
		#end

		if (state.chapterHUD.lastSave != null)
		{
			state.chapterHUD.lastSave.text = "Last Save: " + PlayerData.currentRoom;
		}
			
	}
}
