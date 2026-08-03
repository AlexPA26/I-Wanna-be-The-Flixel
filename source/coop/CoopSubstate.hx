package coop;

import coop.LocalCoopSubstate.LocalCoopSubState;
import coop.ServerCoopSubstate.ServerCoopSubState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ui.FlxButton;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class CoopSubState extends FlxSubState
{
    #if !mobile
    var assetsGroup:FlxGroup;
    var bgOption:FlxSprite;
    var title:FlxText;
    var closeBoton:FlxSprite;

    var btnLocal:FlxButton;
    var btnServer:FlxButton;

    var localTween:FlxTween;
    var serverTween:FlxTween;

    override public function create()
    {
        openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.ARROW;

        super.create();
        assetsGroup = new FlxGroup();

        var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0.6;
        assetsGroup.add(bg);

        bgOption = new FlxSprite();
        bgOption.loadGraphic(AssetPaths.OptionBG__png, false);
        bgOption.alpha = 0.85;
        bgOption.screenCenter();
        assetsGroup.add(bgOption);

        title = new FlxText(0, 80, FlxG.width, "Coop Mode");
        title.setFormat(null, 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        assetsGroup.add(title);

        closeBoton = new FlxSprite();
        closeBoton.loadGraphic(AssetPaths.menuClose__png, true, 63, 63);
        closeBoton.animation.add("normal", [0], 1, false);
        closeBoton.animation.add("active", [1], 1, false);
        closeBoton.screenCenter();
        closeBoton.y -= 265;
        closeBoton.x += 520;
        assetsGroup.add(closeBoton);

        btnLocal = new FlxButton(FlxG.width / 2 - 260, FlxG.height / 2 - 30, "Local", function()
        {
            FlxG.sound.play(AssetPaths.trigger__ogg, 0.4);
            openSubState(new LocalCoopSubState());
        });
        setupFancyButton(btnLocal);
        assetsGroup.add(btnLocal);

        btnServer = new FlxButton(FlxG.width / 2 + 40, FlxG.height / 2 - 30, "Server", function()
        {
            FlxG.sound.play(AssetPaths.trigger__ogg, 0.4);
            openSubState(new ServerCoopSubState());
        });
        setupFancyButton(btnServer);
        assetsGroup.add(btnServer);

        add(assetsGroup);
    }

    function setupFancyButton(btn:FlxButton):Void
    {
        btn.loadGraphic(AssetPaths.buttonTitle__png, false, 220, 60);
        btn.label.setFormat(null, 26, FlxColor.WHITE, CENTER);
        btn.label.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        
        // Push the label string vertically downwards inside the standard text block bounds
        for (offset in btn.labelOffsets)
        { 
            offset.y += 12; 
        }
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (FlxG.mouse.overlaps(btnLocal))
        {
            if (localTween == null || !localTween.active)
            {
                if (localTween != null) localTween.cancel();
                localTween = FlxTween.tween(btnLocal.scale, {x: 1.12, y: 1.12}, 0.15, {ease: FlxEase.sineOut});
                btnLocal.label.color = FlxColor.YELLOW;
            }
        }
        else
        {
            if (btnLocal.scale.x > 1.0 && (localTween == null || !localTween.active))
            {
                if (localTween != null) localTween.cancel();
                localTween = FlxTween.tween(btnLocal.scale, {x: 1.0, y: 1.0}, 0.12, {ease: FlxEase.sineIn});
                btnLocal.label.color = FlxColor.WHITE;
            }
        }

        if (FlxG.mouse.overlaps(btnServer))
        {
            if (serverTween == null || !serverTween.active)
            {
                if (serverTween != null) serverTween.cancel();
                serverTween = FlxTween.tween(btnServer.scale, {x: 1.12, y: 1.12}, 0.15, {ease: FlxEase.sineOut});
                btnServer.label.color = FlxColor.YELLOW;
            }
        }
        else
        {
            if (btnServer.scale.x > 1.0 && (serverTween == null || !serverTween.active))
            {
                if (serverTween != null) serverTween.cancel();
                serverTween = FlxTween.tween(btnServer.scale, {x: 1.0, y: 1.0}, 0.12, {ease: FlxEase.sineIn});
                btnServer.label.color = FlxColor.WHITE;
            }
        }

        var isOverlappingAnyButton = FlxG.mouse.overlaps(btnLocal) || FlxG.mouse.overlaps(btnServer) || FlxG.mouse.overlaps(closeBoton);

        if (FlxG.mouse.overlaps(closeBoton))
        {
            closeBoton.animation.play("active");
            if (FlxG.mouse.justPressed)
            {
                openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.ARROW;
                close();
                return;
            }
        }
        else
        {
            closeBoton.animation.play("normal");
        }

        if (isOverlappingAnyButton)
        {
            openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.BUTTON;
        }
        else
        {
            openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.ARROW;
        }

        if (FlxG.keys.justPressed.ESCAPE)
        {
            openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.ARROW;
            close();
        }
    }
    #end
}
