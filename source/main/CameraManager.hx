package main;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.addons.editors.tiled.TiledLayer;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.math.FlxRect;

class CameraManager
{
	public static function setupAutoscroll(state:ChapterState):Void
	{
		state.isAutoscrolling = false;
		state.autoscrollType = "none";
		state.scrollOffsetX = 0;
		state.scrollSpeed = 0;

		if (state.tiledData == null)
			return;

		for (layer in state.tiledData.layers)
		{
			if (layer.type == TiledLayerType.OBJECT)
			{
				var objLayer:TiledObjectLayer = cast layer;

				if (layer.name.toLowerCase() == "autoscroll")
				{
					if (objLayer.properties.contains("autoscrollType"))
					{
						state.autoscrollType = objLayer.properties.get("autoscrollType");
					}

					if (objLayer.properties.contains("speed"))
					{
						state.scrollSpeed = Std.parseFloat(objLayer.properties.get("speed"));
					}

					if (objLayer.properties.contains("offsetX"))
					{
						state.scrollOffsetX = Std.parseFloat(objLayer.properties.get("offsetX"));
					}

					if (state.autoscrollType == "scrollX" || state.autoscrollType == "scrollY")
					{
						state.isAutoscrolling = true;
					}
				}

				if (layer.name == "PlayerSpeed" && objLayer.properties.contains("value") && state.player != null)
				{
					var pSpeed = Std.parseFloat(objLayer.properties.get("value"));
					state.player.mapMaxSpeed = pSpeed;
					state.player.maxVelocity.x = pSpeed;
				}
			}
		}
	}

	public static function setupCamera(state:ChapterState):Void
	{
		state.cameraType = "normal";
		FlxG.camera.target = null;

		if (state.tiledData != null)
		{
			var camLayer = state.tiledData.getLayer("camera");
			if (camLayer != null && camLayer.properties.contains("cameraType"))
			{
				state.cameraType = camLayer.properties.get("cameraType");
			}
		}

		if (state.map != null)
		{
			switch (state.cameraType)
			{
				case "unlockX":
					trace("New Camera triggered: UnlockX");
					FlxG.camera.setScrollBoundsRect(state.map.x + 60, state.map.y + 65, state.map.width - 120, state.map.height + 65, false);

				case "unlockY":
					trace("New Camera triggered: UnlockY");
					FlxG.camera.setScrollBoundsRect(state.map.x + 60, state.map.y + 65, state.map.width - 120, state.map.height - 115, false);

				case "unlockXY":
					trace("New Camera triggered: UnlockXY");
					FlxG.camera.setScrollBoundsRect(state.map.x + 60, state.map.y + 65, state.map.width - 120, state.map.height - 115, false);

				case "debug":
					trace("New Camera triggered: debug");
					if (state.player != null)
						FlxG.camera.follow(state.player, FlxCameraFollowStyle.LOCKON);

				default:
					trace("New Camera triggered: Default");
					FlxG.camera.setScrollBoundsRect(state.map.x + 60, state.map.y + 65, state.map.width - 50, state.map.height + 65, false);
			}

			FlxG.worldBounds.set(state.map.x - 200, state.map.y - 200, state.map.width + 400, state.map.height + 400);
		}

		if (state.cameraTarget == null && state.player != null)
		{
			state.cameraTarget = new FlxObject(state.player.x, state.player.y, 1, 1);
			state.add(state.cameraTarget);
		}

		if (state.isAutoscrolling)
		{
			if (state.autoscrollType == "scrollX")
			{
				FlxG.camera.minScrollX = null;
				FlxG.camera.maxScrollX = null;

				if (state.map != null)
				{
					FlxG.camera.minScrollY = state.map.y;
					FlxG.camera.maxScrollY = state.map.y + state.map.height;
				}

				if (state.player != null && state.cameraTarget != null)
				{
					state.cameraTarget.setPosition(state.player.x, state.player.y);
					state.cameraTarget.velocity.x = state.scrollSpeed;
					state.cameraTarget.velocity.y = 0;
				}
			}
			else if (state.autoscrollType == "scrollY")
			{
				if (state.map != null)
				{
					FlxG.camera.minScrollX = null;
					FlxG.camera.maxScrollX = null;
					FlxG.camera.minScrollY = null;
					FlxG.camera.maxScrollY = state.map.y + state.map.height;
				}

				var startX = (state.map != null ? state.map.x + (state.map.width / 2) : (state.player != null ? state.player.x : 0)) + state.scrollOffsetX;
				var startY = state.map != null ? (state.map.y + state.map.height - (FlxG.height / 2)) : (state.player != null ? state.player.y : 0);

				if (state.cameraTarget != null)
				{
					state.cameraTarget.setPosition(startX, startY);
					state.cameraTarget.velocity.y = -state.scrollSpeed;
					state.cameraTarget.velocity.x = 0;
				}
			}

			if (state.cameraTarget != null)
			{
				FlxG.camera.focusOn(state.cameraTarget.getPosition());
				FlxG.camera.follow(state.cameraTarget, LOCKON, 1);
			}
		}
		else if (state.cameraType != "normal")
		{
			var cameraMarginX:Float = 0;
			var cameraMarginY:Float = 0;
			var cameraMarginW:Float = 0;
			var cameraMarginH:Float = 0;

			if (state.cameraType == "unlockX")
			{
				cameraMarginX = FlxG.width * 0.3;
				cameraMarginW = FlxG.width * 0.3;
				cameraMarginY = FlxG.height / 2;
				cameraMarginH = 0;
			}
			else if (state.cameraType == "unlockY")
			{
				cameraMarginX = FlxG.width / 2;
				cameraMarginW = 0;
				cameraMarginY = FlxG.height * 0.3;
				cameraMarginH = FlxG.height * 0.4;
			}
			else if (state.cameraType == "unlockXY")
			{
				cameraMarginX = FlxG.width * 0.3;
				cameraMarginW = FlxG.width * 0.4;
				cameraMarginY = FlxG.height * 0.3;
				cameraMarginH = FlxG.height * 0.4;
			}

			FlxG.camera.deadzone = FlxRect.get(cameraMarginX, cameraMarginY, cameraMarginW, cameraMarginH);
		}
		else
		{
			if (state.map != null)
			{
				FlxG.camera.scroll.set(-260, -265);
			}
		}
	}

	public static function update(state:ChapterState, elapsed:Float):Void
	{
		var player = state.player;
		var cameraTarget = state.cameraTarget;
		var map = state.map;

		if (state.isAutoscrolling && cameraTarget != null && player != null)
		{
			if (state.autoscrollType == "scrollX")
			{
				cameraTarget.y = player.y;
			}
			else if (state.autoscrollType == "scrollY" && map != null)
			{
				cameraTarget.x = (map.x + (map.width / 2)) + state.scrollOffsetX;
			}

			var limitOffset = 100;
			if (player.x + player.width < FlxG.camera.scroll.x - limitOffset || 
				player.x > FlxG.camera.scroll.x + FlxG.width + limitOffset ||
				player.y + player.height < FlxG.camera.scroll.y - limitOffset || 
				player.y > FlxG.camera.scroll.y + FlxG.height + limitOffset)
			{
				state.killPlayer();
			}
		}
		else if (!state.isAutoscrolling && cameraTarget != null && player != null)
		{
			#if !debug
			if (state.cameraType == "unlockX" && map != null)
			{
				cameraTarget.x = player.x;
				cameraTarget.y = map.y;
			}
			else if (state.cameraType == "unlockY" && map != null)
			{
				cameraTarget.x = map.x + (map.width / 2);
				var targetOffset:Float = (player.velocity.y > 50) ? 0 : -225;
				state.cameraOffsetY += (targetOffset - state.cameraOffsetY) * 5.0 * elapsed;
				cameraTarget.y = player.y + state.cameraOffsetY;
			}
			else if (state.cameraType == "unlockXY")
			{
				cameraTarget.x = player.x;
				cameraTarget.y = player.y;
			}
			#end
		}

		if (state.cameraType != "normal" && !state.isAutoscrolling && cameraTarget != null)
		{
			if (state.cameraSnapTimer >= 0)
			{
				if (state.cameraSnapTimer <= 0)
				{
					FlxG.camera.follow(cameraTarget, PLATFORMER, 0.1);
				}
				else
				{
					FlxG.camera.follow(cameraTarget, PLATFORMER, 1);
					state.cameraSnapTimer -= 1;
				}
			}
		}
	}

	public static function resetWarpTarget(state:ChapterState):Void
	{
		#if !debug
		if (state.cameraTarget != null && state.cameraType != "normal" && state.player != null)
		{
			if (state.cameraType == "unlockY")
				state.cameraTarget.x = FlxG.width / 2;
			else
				state.cameraTarget.x = state.player.x;

			if (state.cameraType == "unlockX")
				state.cameraTarget.y = FlxG.height / 2;
			else
				state.cameraTarget.y = state.player.y;
		}
		#end
	}
}

