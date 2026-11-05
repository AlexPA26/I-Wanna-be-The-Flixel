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
		var allButtons = [virtualPad.getButton(A)];

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

		var stick = virtualPad.stick;
		var aBtn = virtualPad.getButton(A);

		if (stick != null)
		{
			stick.x = 100;
			stick.y = FlxG.height - stick.height - 90;
			stick.scrollFactor.set(0, 0);
			stick.base.alpha = targetAlpha;
			stick.thumb.alpha = targetAlpha;
		}

		if (aBtn != null)
		{
			aBtn.x = FlxG.width - aBtn.width - 140;
			aBtn.y = FlxG.height - aBtn.height - 200;
		}
	}
}
