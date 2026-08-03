package gui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.ui.MouseCursor;
import main.ChapterState;
import main.PlayerData;

class StageSelectSubState extends FlxSubState
{
    #if sys
    var title:FlxText;
    var bgOption:FlxSprite;
    var closeBoton = new FlxSprite();
    var chapterGroup:FlxTypedGroup<FlxButton>;
    var stageGroup:FlxTypedGroup<FlxButton>;
    var finalGroup:FlxTypedGroup<FlxSprite>;
    var previewThumbnail:FlxSprite;
    var previewBorder:FlxSprite;
    var selectedChapter:Int = 0;
    var selectedMapID:Int = 0;
    var isInvincible:Bool = false;
    var invincCheck:FlxButton;
    var activeTweens:Map<FlxButton, FlxTween> = new Map();
    var activeLabelTweens:Map<FlxText, FlxTween> = new Map();
    
    var teleportBtn:FlxButton;

    public function new()
    {
        super(0xCC000000);
    }

    override public function create():Void
    {
        openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.ARROW;

        super.create();

        bgOption = new FlxSprite();
        bgOption.loadGraphic(AssetPaths.OptionBG__png, false);
        bgOption.screenCenter();
        bgOption.alpha = 0.85;
        add(bgOption);

        title = new FlxText(0, 75, FlxG.width, "Stage Select");
        FlxTween.tween(title, {y: title.y - 3}, 0.8, {type: PINGPONG, ease: FlxEase.sineInOut});
        title.setFormat(null, 64, FlxColor.WHITE, CENTER);
        add(title);

        previewThumbnail = new FlxSprite(FlxG.width - 500, 200);
        previewThumbnail.makeGraphic(300, 180, FlxColor.TRANSPARENT);
        previewThumbnail.visible = false;
        add(previewThumbnail);

        chapterGroup = new FlxTypedGroup<FlxButton>();
        stageGroup = new FlxTypedGroup<FlxButton>();
        finalGroup = new FlxTypedGroup<FlxSprite>();

        add(chapterGroup);
        add(stageGroup);
        add(finalGroup);

        createChapterMenu();

        closeBoton.loadGraphic(AssetPaths.menuClose__png, true, 63, 63);
		closeBoton.animation.add("normal", [0], 1, false);
		closeBoton.animation.add("active", [1], 1, false);
		closeBoton.animation.play("normal");
        closeBoton.screenCenter();
        closeBoton.y -= 265;
        closeBoton.x += 520;
        add(closeBoton);
    }

    function createChapterMenu()
    {
        clearGroup(chapterGroup);
        // var chapters = ["Chapter 1", "Chapter 2", "Chapter 3", "Chapter 4", "Chapter 5"];
        var chapters = ["Chapter 1"];
        for (i in 0...chapters.length)
        {
            var btn = new FlxButton(150, 175 + (i * 100), chapters[i], function()
            {
                selectChapter(i + 1);
            });
            setupButtonStyle(btn);
            chapterGroup.add(btn);
        }
    }

    function selectChapter(id:Int)
    {
        selectedChapter = id;
        clearGroup(stageGroup);
        clearGroup(finalGroup);
        hidePreview();
        
        var stages:Array<{name:String, map:Int}> = [];

        if (id == 1)
        {
            stages =
            [
                {name: "Outside", map: 1},
                {name: "Castle", map: 10},
                {name: "Miniboss", map: 24},
                {name: "Sewers", map: 25},
                {name: "Boss", map: 40}
            ];
        }
        else if (id == 2)
        {
            stages =
            [
                {name: "Phase 1", map: 1},
                {name: "Phase 2", map: 10},
                {name: "Phase 3", map: 24},
                {name: "Phase 4", map: 25},
                {name: "Phase 5", map: 40}
            ];
        }

        else if (id == 3)
        {
            stages =
            [
                {name: "Phase 1", map: 1},
                {name: "Phase 2", map: 10},
                {name: "Phase 3", map: 24},
                {name: "Phase 4", map: 25},
                {name: "Phase 5", map: 40}
            ];
        }

        else if (id == 4)
        {
            stages =
            [
                {name: "Phase 1", map: 1},
                {name: "Phase 2", map: 10},
                {name: "Phase 3", map: 24},
                {name: "Phase 4", map: 25},
                {name: "Phase 5", map: 40}
            ];
        }

        else if (id == 5)
        {
            stages =
            [
                {name: "Phase 1", map: 1},
                {name: "Phase 2", map: 10},
                {name: "Phase 3", map: 24},
                {name: "Phase 4", map: 25},
                {name: "Phase 5", map: 40}
            ];
        }

        for (i in 0...stages.length)
        {
            var s = stages[i];
            var btn = new FlxButton(450, 175 + (i * 100), s.name, function()
            {
                selectStage(s.map);
            });
            setupButtonStyle(btn);

            // HOVER LOGIC FOR THUMBNAILS
            btn.onOver.callback = function()
            {
                openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.BUTTON;
                FlxG.sound.play(AssetPaths.trigger__ogg, 0.1, false);
                showPreview(s.name);
            };
            btn.onOut.callback = function()
            {
                openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.ARROW;
                hidePreview();
            };

            stageGroup.add(btn);
        }
    }

    function showPreview(stageName:String)
    {
        var assetPath:String = "";

        switch (stageName)
        {
            case "Outside": assetPath = AssetPaths.thumbnail_rain__png;
            case "Castle": assetPath = AssetPaths.thumbnail_castle__png;
            case "Sewers": assetPath = AssetPaths.thumbnail_sewers__png;
            default: assetPath = AssetPaths.thumbnail_default__png; 
        }

        if (assetPath != "")
        {
            previewThumbnail.loadGraphic(assetPath);
            previewThumbnail.updateHitbox();
            previewThumbnail.visible = true;
            
            // Add a little pop effect
            previewThumbnail.scale.set(0.8, 0.8);
            FlxTween.tween(previewThumbnail.scale, {x: 1, y: 1}, 0.1, {ease: FlxEase.backOut});
        }
    }

    function hidePreview()
    {
        previewThumbnail.visible = false;
    }

    function selectStage(mapID:Int)
    {
        selectedMapID = mapID;
        clearGroup(finalGroup);

        invincCheck = new FlxButton(150, 500, "Invincible: NO", function()
        {
            isInvincible = !isInvincible;
            invincCheck.label.text = "Invincible: " + (isInvincible ? "YES" : "NO");
            invincCheck.color = isInvincible ? FlxColor.GREEN : FlxColor.WHITE;
        });
        setupButtonStyle(invincCheck);
        finalGroup.add(invincCheck);

        teleportBtn = new FlxButton(150, 560, "Telepprt!", clickTeleport);
        setupButtonStyle(teleportBtn);
        teleportBtn.color = FlxColor.CYAN;
        finalGroup.add(teleportBtn);
    }

    function clickTeleport()
    {
        PlayerData.currentChapter = selectedChapter;
        var mapString:String = (selectedMapID < 10) ? "0" + selectedMapID : "" + selectedMapID;
        PlayerData.currentRoom = "map" + mapString;
        PlayerData.spawnX = 450;
        PlayerData.spawnY = 300;
        FlxG.camera.filters = [];

        for (cam in FlxG.cameras.list)
        {
            if (cam != FlxG.camera)
            {
                FlxG.cameras.remove(cam);
            }
        }
        if (FlxG.sound.music != null) { FlxG.sound.music.stop(); }
        FlxG.switchState(ChapterState.new);
    }

    function setupButtonStyle(btn:FlxButton)
    {
        btn.loadGraphic(AssetPaths.buttonTitle__png, false, 250, 60); 
        btn.label.setFormat(null, 24, FlxColor.WHITE, CENTER);
        btn.label.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);

        for (offset in btn.labelOffsets)
        {
            offset.y += 10;
        }

        btn.onOver.callback = function()
        {
            openfl.ui.Mouse.cursor = MouseCursor.BUTTON;

            FlxTween.tween(btn.label.scale, {x: 1.1, y: 1.1}, 0.05, {ease: FlxEase.quadOut});
            FlxTween.tween(btn.scale, {x: 1.1, y: 1.1}, 0.05, {ease: FlxEase.quadOut});

            var btnTwn = FlxTween.angle(btn, -5, 5, 0.6, {type: PINGPONG, ease: FlxEase.sineInOut});
            var txtTwn = FlxTween.angle(btn.label, -5, 5, 0.6, {type: PINGPONG, ease: FlxEase.sineInOut});

            activeTweens.set(btn, btnTwn);
            activeLabelTweens.set(btn.label, txtTwn);
            FlxG.sound.play(AssetPaths.trigger__ogg, 0.1, false);
        };

        btn.onOut.callback = function()
        {
            openfl.ui.Mouse.cursor = MouseCursor.ARROW;

            FlxTween.tween(btn.label.scale, {x: 1.0, y: 1.0}, 0.05, {ease: FlxEase.quadIn});
            FlxTween.tween(btn.scale, {x: 1.0, y: 1.0}, 0.05, {ease: FlxEase.quadIn});

            if (activeTweens.exists(btn))
            {
                activeTweens.get(btn).cancel();
                activeTweens.remove(btn);
            }

            if (activeLabelTweens.exists(btn.label))
            {
                activeLabelTweens.get(btn.label).cancel();
                activeLabelTweens.remove(btn.label);
            }

            FlxTween.tween(btn, {angle: 0}, 0.1, {ease: FlxEase.quadOut});
            FlxTween.tween(btn.label, {angle: 0}, 0.1, {ease: FlxEase.quadOut});
            
        };
        
    }

    function clearGroup(group:FlxTypedGroup<Dynamic>)
    {
        if (group != null)
        {
            group.forEach(function(item:Dynamic)
            {
                if (item != null)
                {
                    item.destroy();
                }
            });
            group.clear();
        }
    }

    #if !mobile
    function closeBotonMenu():Void
    {
        if (FlxG.mouse.overlaps(closeBoton))
        {
            openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.BUTTON;
            closeBoton.animation.play("active");
        }

        else
        {
            openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.ARROW;
            closeBoton.animation.play("normal");
        }

        if (FlxG.mouse.overlaps(closeBoton) && FlxG.mouse.justPressed || FlxG.keys.justPressed.ESCAPE)
        {   
            openfl.ui.Mouse.show();
            FlxG.camera.filters = [];
            close();
        }
        
            

    }
    #end
    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        #if !mobile
        if (FlxG.keys.justPressed.ESCAPE)
        {
            openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.ARROW;
            close();
        }
        closeBotonMenu();
        #end

        
    }

    override public function add(Object:flixel.FlxBasic):flixel.FlxBasic
    {
        var result = super.add(Object);
        
        if (this.cameras != null)
        {
            if (Std.isOfType(Object, flixel.FlxSprite))
            {
                var sprite:flixel.FlxSprite = cast Object;
                sprite.cameras = this.cameras;
            }

            else if (Std.isOfType(Object, flixel.group.FlxGroup))
            {
                var grp:flixel.group.FlxGroup = cast Object;
                grp.cameras = this.cameras;
            }
        }
        return result;
    }
    #end
}