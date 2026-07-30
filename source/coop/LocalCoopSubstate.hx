package coop;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ui.FlxButton;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.addons.ui.FlxInputText;
import flixel.util.FlxSave;
import leveldata.misc.SaveManager;
import main.ChapterState;
import main.PlayerData;
import main.Multiplayer;
import main.Multiplayer.CoopMode;

class LocalCoopSubState extends FlxSubState 
{
    var assetsGroup:FlxGroup;
    var bgOption:FlxSprite;
    var title:FlxText;
    var closeBoton:FlxSprite;

    var labelIP:FlxText;
    var labelPort:FlxText;
    
    var inputIP:FlxInputText;
    var inputPort:FlxInputText;
    
    var btnConnect:FlxButton;
    var connectTween:FlxTween;

    var warningText:FlxText;

    var oldMuteKeys:Array<flixel.input.keyboard.FlxKey>;
    var oldVolumeUpKeys:Array<flixel.input.keyboard.FlxKey>;
    var oldVolumeDownKeys:Array<flixel.input.keyboard.FlxKey>;

    public static var targetIP(get, set):String;
    static inline function get_targetIP():String return Multiplayer.targetIP;
    static inline function set_targetIP(v:String):String return Multiplayer.targetIP = v;

    public static var targetPort(get, set):Int;
    static inline function get_targetPort():Int return Multiplayer.targetPort;
    static inline function set_targetPort(v:Int):Int return Multiplayer.targetPort = v;

    public static var isMultiplayerActive(get, set):Bool;
    static inline function get_isMultiplayerActive():Bool return Multiplayer.activeMode == Local;
    static inline function set_isMultiplayerActive(v:Bool):Bool {
        Multiplayer.activeMode = v ? Local : None;
        return v;
    }

    override public function create() 
    {
        openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.ARROW;

        oldMuteKeys = FlxG.sound.muteKeys;
        oldVolumeUpKeys = FlxG.sound.volumeUpKeys;
        oldVolumeDownKeys = FlxG.sound.volumeDownKeys;

        FlxG.sound.muteKeys = null;
        FlxG.sound.volumeUpKeys = null;
        FlxG.sound.volumeDownKeys = null;

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

        title = new FlxText(0, 80, FlxG.width, "Local Coop");
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

        var centerY = FlxG.height / 2;
        var centerX = FlxG.width / 2;

        var savedIP = "192.168.1.100";
        var savedPort = "22336";
        var save = new FlxSave();
        if (save.bind("IWBTF_CoopSettings")) {
            if (save.data.localIP != null) savedIP = save.data.localIP;
            if (save.data.localPort != null) savedPort = save.data.localPort;
        }

        labelIP = new FlxText(centerX - 240, centerY - 65, 220, "Hostname/IP");
        labelIP.setFormat(null, 22, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        assetsGroup.add(labelIP);

        inputIP = new FlxInputText(centerX - 240, centerY - 25, 220, savedIP, 20, FlxColor.BLACK, FlxColor.WHITE);
        inputIP.filterMode = FlxInputText.NO_FILTER;
        assetsGroup.add(inputIP);

        labelPort = new FlxText(centerX + 20, centerY - 65, 220, "Port");
        labelPort.setFormat(null, 22, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        assetsGroup.add(labelPort);

        inputPort = new FlxInputText(centerX + 20, centerY - 25, 220, savedPort, 20, FlxColor.BLACK, FlxColor.WHITE);
        inputPort.filterMode = FlxInputText.ONLY_NUMERIC;
        assetsGroup.add(inputPort);

        warningText = new FlxText(centerX - 240, centerY + 25, 480, "localhost not permitted");
        warningText.setFormat(null, 18, FlxColor.RED, CENTER, OUTLINE, FlxColor.BLACK);
        warningText.visible = false;
        assetsGroup.add(warningText);

        btnConnect = new FlxButton(centerX - 110, centerY + 80, "Connect!", clickConnect);
        setupFancyButton(btnConnect);
        btnConnect.color = FlxColor.GREEN;
        assetsGroup.add(btnConnect);

        add(assetsGroup);
    }

    function setupFancyButton(btn:FlxButton):Void
    {
        btn.loadGraphic(AssetPaths.buttonTitle__png, false, 220, 60);
        btn.label.setFormat(null, 26, FlxColor.WHITE, CENTER);
        btn.label.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        
        for (offset in btn.labelOffsets)
        { 
            offset.y += 12; 
        }
    }

    function clickConnect():Void
    {
        var ip = StringTools.trim(inputIP.text).toLowerCase();
        if (ip == "localhost" || ip == "127.0.0.1")
        {
            FlxG.camera.shake(0.01, 0.05);
            FlxG.sound.play(AssetPaths.error__ogg, 1, false);
            return;
        }

        targetIP = inputIP.text;
        var parsedPort:Null<Int> = Std.parseInt(inputPort.text);
        targetPort = (parsedPort != null) ? parsedPort : 22336;
        isMultiplayerActive = true;

        var save = new FlxSave();
        if (save.bind("IWBTF_CoopSettings")) {
            save.data.localIP = inputIP.text;
            save.data.localPort = inputPort.text;
            save.flush();
        }

        trace("Connecting Socket Interface parameters -> IP Target: " + targetIP + " | Port: " + targetPort);

        if (SaveManager.loadGame())
        {
            if (FlxG.sound.music != null) { FlxG.sound.music.stop(); }
            trace("IP INTRODUCED: " + inputIP.text);
            trace("PORT INTRODUCED: " + inputPort.text);
            FlxG.switchState(ChapterState.new);
        }
        else if (PlayerData.currentRoom != "map01" && PlayerData.currentChapter != 1)
        {
            FlxG.camera.shake(0.01, 0.05);
            FlxG.sound.play(AssetPaths.error__ogg, 1, false);
        }
    }

    override public function update(elapsed:Float) 
    {
        super.update(elapsed);

        var ip = StringTools.trim(inputIP.text).toLowerCase();
        var isLocalhost = (ip == "localhost" || ip == "127.0.0.1");
        warningText.visible = isLocalhost;

        if (FlxG.mouse.overlaps(btnConnect))
        {
            if (connectTween == null || !connectTween.active)
            {
                if (connectTween != null) connectTween.cancel();
                connectTween = FlxTween.tween(btnConnect.scale, {x: 1.12, y: 1.12}, 0.15, {ease: FlxEase.sineOut});
                btnConnect.label.color = FlxColor.YELLOW;
            }
        }
        else
        {
            if (btnConnect.scale.x > 1.0 && (connectTween == null || !connectTween.active))
            {
                if (connectTween != null) connectTween.cancel();
                connectTween = FlxTween.tween(btnConnect.scale, {x: 1.0, y: 1.0}, 0.12, {ease: FlxEase.sineIn});
                btnConnect.label.color = FlxColor.WHITE;
            }
        }

        var isOverlappingAnyButton = FlxG.mouse.overlaps(btnConnect) || FlxG.mouse.overlaps(closeBoton);

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
            if (!FlxG.mouse.overlaps(inputIP) && !FlxG.mouse.overlaps(inputPort))
            {
                openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.ARROW;
            }
        }

        if (FlxG.keys.justPressed.ESCAPE) 
        {
            openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.ARROW;
            close();
        }
    }

    override public function destroy()
    {
        FlxG.sound.muteKeys = oldMuteKeys;
        FlxG.sound.volumeUpKeys = oldVolumeUpKeys;
        FlxG.sound.volumeDownKeys = oldVolumeDownKeys;

        super.destroy();
    }
}