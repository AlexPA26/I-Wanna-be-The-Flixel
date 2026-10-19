package gui;

import flixel.FlxG;
import flixel.ui.FlxVirtualPad;

class VirtualPadHelper
{
	public static function layout(virtualPad:FlxVirtualPad, padScale:Float = 2.5, targetAlpha:Float = 0.5):Void
	{
		if (virtualPad == null)
			return;

		var hitboxPadding:Float = 40;
		var allButtons = [virtualPad.getButton(LEFT), virtualPad.getButton(RIGHT), virtualPad.getButton(A)];

		for (button in allButtons)
		{
			if (button == null)
				continue;

			button.scale.set(padScale, padScale);
			button.updateHitbox();
			button.width += hitboxPadding;
			button.height += hitboxPadding;

			button.offset.x -= hitboxPadding / 2;
			button.offset.y -= hitboxPadding / 2;

			button.scrollFactor.set(0, 0);
			button.alpha = targetAlpha;
		}

		var leftBtn = virtualPad.getButton(LEFT);
		var rightBtn = virtualPad.getButton(RIGHT);
		var aBtn = virtualPad.getButton(A);

		if (leftBtn != null)
		{
			leftBtn.x = 100;
			leftBtn.y = FlxG.height - leftBtn.height - 90;
		}

		if (rightBtn != null && leftBtn != null)
		{
			rightBtn.x = leftBtn.x + leftBtn.width + 40;
			rightBtn.y = leftBtn.y;
		}

		if (aBtn != null)
		{
			aBtn.x = FlxG.width - aBtn.width - 140;
			aBtn.y = FlxG.height - aBtn.height - 200;
		}
	}
}

