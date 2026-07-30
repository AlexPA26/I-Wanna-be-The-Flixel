package main;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import main.mods.ModLoader;
import main.Multiplayer;
import main.Multiplayer.CoopMode;
import main.ChapterState;

class RemotePlayer extends FlxSprite {
	public var skinName:String = "";
	public var username:String = "";
	public var usernameText:FlxText;
	public var timeSincePacket:Float = 0;

	// Target position for LERP (used when using UDP)
	var netX:Float = 0;
	var netY:Float = 0;
	var hasReceivedPacket:Bool = false;

	static inline var LERP_SPEED:Float = 12.0;
	static inline var SNAP_DISTANCE:Float = 150.0;

	public function new(x:Float, y:Float, username:String) {
		super(x, y);
		this.username = username;
		loadSkin("thekid");
		netX = x;
		netY = y;

		usernameText = new FlxText(0, 0, 150, username);
		usernameText.setFormat(null, 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		usernameText.visible = false;
	}

	public function loadSkin(skin:String):Void {
		if (skinName == skin)
			return;
		skinName = skin;
		ModLoader.loadModGraphic(this, "images/skins/" + skin + ".png", "skin_" + skin, 50, 50);
		animation.add("idle", [0, 1, 2, 3], 11, true);
		animation.add("jumpUp", [6], 16, false);
		animation.add("jumpDown", [7], 1, false);
		animation.add("walking", [8, 9, 10, 11, 12, 13], 24, true);

		width = 20;
		height = 30;
		offset.set(20, 20);

		setFacingFlip(LEFT, true, false);
		setFacingFlip(RIGHT, false, false);
	}

	/**
	 * Restored original direct position update algorithm from main repository
	 */
	public function applyNetworkPacket(xVal:Float, yVal:Float, flipVal:Bool, facingRightVal:Bool, animVal:String, roomVal:String):Void {
		this.flipY = flipVal;
		this.offset.y = flipVal ? 0 : 20;
		this.facing = facingRightVal ? RIGHT : LEFT;
		this.offset.x = facingRightVal ? 20 : 10;

		setFacingFlip(LEFT, true, flipVal);
		setFacingFlip(RIGHT, false, flipVal);

		if (animVal != null && animVal != "") {
			animation.play(animVal);
		}

		timeSincePacket = 0;

		// Handle room visibility
		var currentRoomMatch = true;
		if (Std.isOfType(FlxG.state, ChapterState)) {
			var state:ChapterState = cast FlxG.state;
			var currentRoomName = state.currentRoomName;
			if (roomVal == null || roomVal == "" || roomVal == currentRoomName) {
				this.exists = true;
				this.visible = true;
			} else {
				this.exists = false;
				this.visible = false;
				currentRoomMatch = false;
				if (usernameText != null) {
					usernameText.visible = false; // Hide username immediately when exists is set to false
				}
			}
		}

		if (currentRoomMatch) {
			if (Multiplayer.usingTCP) {
				// Snap directly for TCP connections
				this.x = xVal;
				this.y = yVal;
			} else {
				// Smooth LERP target setup for UDP
				netX = xVal;
				netY = yVal;
				if (!hasReceivedPacket) {
					this.x = xVal;
					this.y = yVal;
					hasReceivedPacket = true;
				} else {
					var dx = netX - this.x;
					var dy = netY - this.y;
					var dist = Math.sqrt(dx * dx + dy * dy);
					if (dist > SNAP_DISTANCE) {
						this.x = netX;
						this.y = netY;
					}
				}
			}
		}
	}

	override public function kill():Void {
		super.kill();
		if (usernameText != null) {
			usernameText.visible = false;
		}
	}

	override public function update(elapsed:Float):Void {
		timeSincePacket += elapsed;

		if (!Multiplayer.usingTCP && hasReceivedPacket && this.exists) {
			// Smooth interpolation (only for UDP)
			this.x += (netX - this.x) * LERP_SPEED * elapsed;
			this.y += (netY - this.y) * LERP_SPEED * elapsed;
		}

		super.update(elapsed);

		if (usernameText != null) {
			usernameText.x = this.x + (this.width / 2) - (usernameText.width / 2);
			usernameText.y = this.y - 20;
			usernameText.visible = (Multiplayer.activeMode == Server) && this.visible && this.exists;
		}
	}

	override public function destroy():Void {
		if (usernameText != null) {
			usernameText.destroy();
			usernameText = null;
		}
		super.destroy();
	}
}
