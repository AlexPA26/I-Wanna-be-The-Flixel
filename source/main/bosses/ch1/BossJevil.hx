package main.bosses.ch1;

import flixel.math.FlxRandom;
import leveldata.hazards.SolidBlock;
import leveldata.hazards.SmallSpike;
import leveldata.blockdata.NormalSlab;
import leveldata.events.NormalTrampolineMini;
import flixel.group.FlxGroup.FlxTypedGroup;
import leveldata.events.NormalTrampoline;
import leveldata.hazards.NormalSpike;
import flixel.effects.FlxFlicker;
import flixel.addons.effects.FlxTrail;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import main.ChapterState;
import main.bosses.ch1.JevilProjectiles;

class Jevil extends FlxSprite
{
    public var hp:Float = 120;
    public var state:String = "waiting";
    public var trail:FlxTrail;
    public var isVulnerable:Bool = false;
    public var canBeHit:Bool = false;
    public var ultimateTriggered:Bool = false;
    public var ultimateUsed:Bool = false;
    var cubeTriggered:Bool = false;
    public var fightingBoss:Bool = false;
    var scytheTimeAccumulator:Float = 0;
    
    public var blackFade:FlxSprite;
    var whiteFade = new FlxSprite();
    var player:Player;
    public static var playerSkin:String;
    public var playerHUD:FlxSprite;
    var originalSkin:String;
    public var craziness:Bool = false;
    var soul:FlxSprite;
    public var flash:FlxSprite;
    public var ultimateManager:main.bosses.ch1.JevilUltimateState;
    public var shield:FlxSprite;
    var trailEffect:main.bosses.ch1.JevilEffect;
    var jailObjects:flixel.group.FlxGroup;
    var battleMusicStarted:Bool = false;
    var jailManager:main.bosses.ch1.JevilJailManager;

    var spadeComboCount:Int = 0;
    var lastAttackWasLeft:Bool = false;
    var targetSpadeCombos:Int = 0;

    var fanComboCount:Int = 0;
    var targetFanCombos:Int = 0;

    var circleSpades:Array<main.bosses.ch1.JevilProjectiles.JevilCircleSpade> = [];
    var parentState:ChapterState;
    var teleportCount:Int = 0;

    var currentPhaseID:Int = -1;
    var patternStep:Int = 0;
    var phase01Attacks:Array<Void->Void>;
    var phase02Attacks:Array<Void->Void>;
    var phase03Attacks:Array<Void->Void>;

    public function new(x:Float, y:Float, stateRef:ChapterState)
    {
        super(x, y);
        this.parentState = stateRef;
        this.ultimateManager = new JevilUltimateState(this);
        this.jailManager = new main.bosses.ch1.JevilJailManager(parentState);
        this.visible = false;

        frames = FlxAtlasFrames.fromSparrow(AssetPaths.jevil__png, AssetPaths.jevil__xml);
        
        animation.addByPrefix("dance", "jevil_dance_normal", 12, true);
        animation.addByPrefix("danceLowHP", "jevil_dance_", 16, true);
        animation.addByPrefix("idle", "jevil_main_", 8, true);
        animation.addByPrefix("laugh", "jevil_laugh", 12, true);
        animation.addByPrefix("teleport", "jevil_teleport_n", 6, false);
        animation.addByPrefix("teleportReverse", "jevil_teleport_r", 6, false);
        animation.addByPrefix("tired", "jevil_tired", 1, false);
        animation.play("idle");
        scale.set(2.5, 2.5);
        updateHitbox();
        immovable = true;

        shield = new FlxSprite();
        shield.loadGraphic(AssetPaths.shield__png, false);
        shield.scale.set(0.75, 0.75);
        shield.alpha = 0;
        shield.blend = ADD;
        shield.visible = false;
        shield.antialiasing = true;

        soul = new FlxSprite();
        soul.loadGraphic(AssetPaths.soul__png, true, 20, 16);
        soul.animation.add("idle", [0], 0, false);
        soul.animation.play("idle");
        soul.alpha = 0;
        soul.scale.set(1.5, 1.5);
        parentState.add(soul);

        flash = new FlxSprite();
        flash.makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE, true);
        flash.alpha = 0;

        blackFade = new FlxSprite();
        blackFade.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK, true);
        blackFade.alpha = 0;
        parentState.add(blackFade);

        playerHUD = new FlxSprite();
        playerHUD.loadGraphic(AssetPaths.hudJevil__png, false);
        playerHUD.screenCenter();
        playerHUD.scale.set(2 / 3, 2 / 3);
        playerHUD.alpha = 0;
        parentState.add(playerHUD);

        playerSkin = PlayerData.currentSkin;

        FlxTween.tween(this, {y: y - 10}, 0.75, {type: PINGPONG, ease: FlxEase.sineInOut});

        trailEffect = new main.bosses.ch1.JevilEffect(this, parentState);
        if (parentState != null) parentState.add(trailEffect);

        // phase01Attacks = [attackScythe];

        phase01Attacks =
        [
            attackBullets, attackSpades, attackFan, attackFan, attackHearts, attackBullets, attackFan, attackSpades
        ];

        phase02Attacks =
        [
            attackFan, attackScythe, attackJail, attackBullets, attackCircle, attackHearts, attackScythe,
            attackBombarding, attackScythe, attackJail, attackBullets, attackCircle
        ];


        phase03Attacks =
        [
            attackBombarding, attackScythe, attackCube, attackBullets, attackJail, attackHearts,
            attackBombarding, attackCircle, attackHearts, attackScythe, attackBullets, attackBombarding, attackJail,
            attackFan, attackCircle, attackBombarding, attackHearts, attackJail
        ];

    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (this.shield != null && this.shield.exists && this.alpha == 1 && this.visible == true && this.active == true)
        {
            this.shield.alpha = 1 - Math.random() * 0.25;
        }

        soul.x = parentState.player.x;
        soul.y = parentState.player.y;

        if (flash.alpha > 0)
        {
            flash.alpha -= elapsed;
        }

        if (state == "startCube" || state == "attackingCube" || state == "returningCube") { parentState.inmortal = true; }
        else { parentState.inmortal = false; }

        if (FlxG.keys.justPressed.U)
        {
            ultimateTriggered = true;
            startUltimateAttack();
            return;
        }

        if (FlxG.keys.justPressed.J)
        {
            attackCube();
            return;
        }

        if (FlxG.keys.justPressed.I)
        {
            parentState.spawnTimer = 9999;
        }

        if (FlxG.keys.justPressed.R)
        {
            if (FlxG.sound.music != null) { FlxG.sound.music.stop(); }
            PlayerData.currentSkin = playerSkin;
        }

        if (FlxG.keys.justPressed.ENTER) { hp -= 10; }

        if (FlxG.keys.justPressed.C)
        {
            trace("------------------------------");
            trace("Current Phase: " + state);
            trace("Current Jevil animation: " + animation.curAnim.name);
            trace("Current Health: " + this.hp);
            trace("Current Player Skin: " + PlayerData.currentSkin);
            trace("Player Inmortal?: " + parentState.inmortal);
            trace("Craziness? " + craziness);
            trace("Jevil POS: X-" + this.x + " || Y-" + this.y);
            trace("Jevil Direction: " + this.flipX);
            trace("------------------------------");
        }

        if (craziness && animation.curAnim != null && animation.curAnim.name == "dance")
        {
            animation.play("danceLowHP");
        }

        if (shield != null)
        {
            shield.x = this.x - 50;
            shield.y = this.y - 50;

            if (ultimateTriggered || state == "ultimate_barrage" || state == "ultimate_transition" ||
                state == "ultimate_cutscene" || state == "attackingCube")
            {
                shield.alpha = 0;
            }

            if (state == "returningCube" && this.shield.alpha != 1)
            {
                FlxTween.tween(this.shield, {alpha: 1}, 1);
            }
        }

        if (state == "ultimate_transition")
        {
            parentState = cast FlxG.state;
            state = "ultimate_barrage";

            new FlxTimer().start(0.1, function(_)
            {
                if (parentState.player != null)
                {
                    parentState.player.active = true;
                    parentState.player.exists = true;
                    parentState.player.alive = true;
                    parentState.player.velocity.set(0, 0);
                    
                    this.alpha = 0;
                    this.animation.play("tired"); 

                }
            });

            parentState.player.visible = false;
            ultimateManager.executeBarrage(parentState);
        }

        if (state == "ultimate_start")
        {            
            ultimateManager.scytheIntro(parentState);
            state = "ultimate_charging";
            ultimateManager.initBarrage(parentState);

            new FlxTimer().start(0.25, function(_)
            {
                FlxTween.tween(this, {alpha: 0}, 1);
            });

            new FlxTimer().start(0.75, function(_)
            {
                FlxTween.tween(parentState.player, {alpha: 0}, 1);
            });

            new FlxTimer().start(1.5, function(_)
            {
                FlxTween.tween(parentState.player, {x: 625, y: 605}, 0.5, { });
                FlxTween.tween(soul, {alpha: 1}, 0.5);
            });
        }

        if (state == "ultimate_return_transition")
        {
            soul.visible = false;
            parentState.player.alpha = 1;
            parentState = cast FlxG.state;
            state = "cooldown";
            ultimateTriggered = false;
            craziness = true;

            this.alpha = 1;
            this.animation.play("danceLowHP");
            this.canBeHit = true;
            this.isVulnerable = true;
            parentState.currentBoss = this;

            if (shield != null) 
            {
                shield.visible = false; 
            }

            new FlxTimer().start(2, function(_)
            {
                if (parentState.player != null)
                {
                    parentState.player.active = true;
                }

                teleport(null);
            });
        }
    }

    public function preCutscene()
    {
        state = "precutscene";
        
        parentState.player.active = false; 
        parentState.player.velocity.set(0, 0);
        parentState.player.acceleration.x = 0;
        fightingBoss = true;

        this.visible = true;
        this.animation.play("teleport", true, false);
        this.scale.set(0.2, 2.5);

        if (FlxG.sound.music != null) { FlxG.sound.music.stop(); }
        FlxG.sound.play(AssetPaths.jevil_teleport__ogg, 1, false);

        var particle = new flixel.effects.particles.FlxEmitter(x + (width / 2), y + (height / 2), 25);
        particle.makeParticles(4, 4, FlxColor.WHITE, 35);
        particle.color.set(FlxColor.BLUE, FlxColor.PURPLE, FlxColor.WHITE);
        particle.launchMode = CIRCLE;
        particle.speed.set(150, 350);
        particle.lifespan.set(0.25, 0.5);
        parentState.add(particle);
        particle.start(true, 0, 35);

        
        FlxTween.tween(scale, { x: 2.5, y: 2.5 }, 0.25,
        {
            onComplete: function(_)
            {
                updateHitbox();
            }

        });

        new FlxTimer().start(0, function(t:FlxTimer)
        {
            createProps();
        });
        
    
    }
    
    public function createProps()
    {
        var propQueue:Array<Void->Void> = [];

        queueProp(propQueue, 820, 535, function() { parentState.trampolinesMini.add(new NormalTrampolineMini(820, 535, "up")); });
        queueProp(propQueue, 570, 385, function() { parentState.slabs.add(new NormalSlab(570, 385, 71)); });
        queueProp(propQueue, 595, 406, function() { parentState.dangerObjects.add(new SmallSpike(595, 406, 2)); });
        queueProp(propQueue, 570, 406, function() { parentState.dangerObjects.add(new SmallSpike(570, 406, 2)); });
        

        queueProp(propQueue, 820, 535, function() { parentState.trampolinesMini.add(new NormalTrampolineMini(820, 535, "up")); });

        queueProp(propQueue, 620, 385, function() { parentState.slabs.add(new NormalSlab(620, 385, 71)); });
        queueProp(propQueue, 620, 406, function() { parentState.dangerObjects.add(new SmallSpike(620, 406, 2)); });
        queueProp(propQueue, 645, 406, function() { parentState.dangerObjects.add(new SmallSpike(645, 406, 2)); });

        queueProp(propQueue, 620, 385, function() { parentState.slabs.add(new NormalSlab(570, 385, 71)); });
        queueProp(propQueue, 595, 406, function() { parentState.dangerObjects.add(new SmallSpike(595, 406, 2)); });
        queueProp(propQueue, 570, 406, function() { parentState.dangerObjects.add(new SmallSpike(570, 406, 2)); });

        queueProp(propQueue, 670, 385, function() { parentState.slabs.add(new NormalSlab(670, 385, 71)); });
        queueProp(propQueue, 670, 406, function() { parentState.dangerObjects.add(new SmallSpike(670, 406, 2)); });
        queueProp(propQueue, 695, 406, function() { parentState.dangerObjects.add(new SmallSpike(695, 406, 2)); });

        queueProp(propQueue, 320, 354, function() { parentState.slabs.add(new NormalSlab(320, 354, 71)); });
        queueProp(propQueue, 345, 375, function() { parentState.dangerObjects.add(new SmallSpike(345, 375, 2)); });
        queueProp(propQueue, 320, 375, function() { parentState.dangerObjects.add(new SmallSpike(320, 375, 2)); });

        queueProp(propQueue, 270, 354, function() { parentState.slabs.add(new NormalSlab(270, 354, 71)); });
        queueProp(propQueue, 295, 375, function() { parentState.dangerObjects.add(new SmallSpike(295, 375, 2)); });
        queueProp(propQueue, 270, 375, function() { parentState.dangerObjects.add(new SmallSpike(270, 375, 2)); });

        queueProp(propQueue, 220, 354, function() { parentState.slabs.add(new NormalSlab(220, 354, 71)); });
        queueProp(propQueue, 245, 375, function() { parentState.dangerObjects.add(new SmallSpike(245, 375, 2)); });
        queueProp(propQueue, 220, 375, function() { parentState.dangerObjects.add(new SmallSpike(220, 375, 2)); });

        queueProp(propQueue, 170, 354, function() { parentState.slabs.add(new NormalSlab(170, 354, 71)); });
        queueProp(propQueue, 195, 375, function() { parentState.dangerObjects.add(new SmallSpike(195, 375, 2)); });
        queueProp(propQueue, 170, 375, function() { parentState.dangerObjects.add(new SmallSpike(170, 375, 2)); });

        queueProp(propQueue, 270, 200, function() { parentState.slabs.add(new NormalSlab(270, 200, 71)); });
        queueProp(propQueue, 220, 200, function() { parentState.slabs.add(new NormalSlab(220, 200, 71)); });

        queueProp(propQueue, 920, 354, function() { parentState.slabs.add(new NormalSlab(920, 354, 71)); });
        queueProp(propQueue, 945, 375, function() { parentState.dangerObjects.add(new SmallSpike(945, 375, 2)); });
        queueProp(propQueue, 920, 375, function() { parentState.dangerObjects.add(new SmallSpike(920, 375, 2)); });

        queueProp(propQueue, 970, 354, function() { parentState.slabs.add(new NormalSlab(970, 354, 71)); });
        queueProp(propQueue, 970, 375, function() { parentState.dangerObjects.add(new SmallSpike(970, 375, 2)); });
        queueProp(propQueue, 995, 375, function() { parentState.dangerObjects.add(new SmallSpike(995, 375, 2)); });

        queueProp(propQueue, 1020, 354, function() { parentState.slabs.add(new NormalSlab(1020, 354, 71)); });
        queueProp(propQueue, 1020, 375, function() { parentState.dangerObjects.add(new SmallSpike(1020, 375, 2)); });
        queueProp(propQueue, 1045, 375, function() { parentState.dangerObjects.add(new SmallSpike(1045, 375, 2)); });

        queueProp(propQueue, 1070, 354, function() { parentState.slabs.add(new NormalSlab(1070, 354, 71)); });
        queueProp(propQueue, 1070, 375, function() { parentState.dangerObjects.add(new SmallSpike(1070, 375, 2)); });
        queueProp(propQueue, 1095, 375, function() { parentState.dangerObjects.add(new SmallSpike(1095, 375, 2)); });

        queueProp(propQueue, 970, 200, function() { parentState.slabs.add(new NormalSlab(970, 200, 71)); });
        queueProp(propQueue, 1020, 200, function() { parentState.slabs.add(new NormalSlab(1020, 200, 71)); });

        queueProp(propQueue, 0, -16, function() { parentState.solidBlock.add(new SolidBlock(0, -16, 59)); });
        queueProp(propQueue, 0, 34, function() { parentState.solidBlock.add(new SolidBlock(0, 34, 59)); });
        queueProp(propQueue, 0, 84, function() { parentState.solidBlock.add(new SolidBlock(0, 84, 59)); });
        queueProp(propQueue, 0, 134, function() { parentState.solidBlock.add(new SolidBlock(0, 134, 59)); });
        queueProp(propQueue, 0, 184, function() { parentState.solidBlock.add(new SolidBlock(0, 184, 59)); });
        queueProp(propQueue, 0, 234, function() { parentState.solidBlock.add(new SolidBlock(0, 234, 59)); });
        queueProp(propQueue, 0, 284, function() { parentState.solidBlock.add(new SolidBlock(0, 284, 59)); });
        queueProp(propQueue, 0, 334, function() { parentState.solidBlock.add(new SolidBlock(0, 334, 59)); });
        queueProp(propQueue, 0, 384, function() { parentState.solidBlock.add(new SolidBlock(0, 384, 59)); });
        queueProp(propQueue, 0, 434, function() { parentState.solidBlock.add(new SolidBlock(0, 434, 59)); });
        queueProp(propQueue, 0, 484, function() { parentState.solidBlock.add(new SolidBlock(0, 484, 59)); });
        queueProp(propQueue, 0, 534, function() { parentState.solidBlock.add(new SolidBlock(0, 534, 59)); });

        queueProp(propQueue, 1250, -16, function() { parentState.solidBlock.add(new SolidBlock(1250, -16, 60)); });
        queueProp(propQueue, 1250, 34, function() { parentState.solidBlock.add(new SolidBlock(1250, 34, 60)); });
        queueProp(propQueue, 1250, 84, function() { parentState.solidBlock.add(new SolidBlock(1250, 84, 60)); });
        queueProp(propQueue, 1250, 134, function() { parentState.solidBlock.add(new SolidBlock(1250, 134, 60)); });
        queueProp(propQueue, 1250, 184, function() { parentState.solidBlock.add(new SolidBlock(1250, 184, 60)); });
        queueProp(propQueue, 1250, 234, function() { parentState.solidBlock.add(new SolidBlock(1250, 234, 60)); });
        queueProp(propQueue, 1250, 284, function() { parentState.solidBlock.add(new SolidBlock(1250, 284, 60)); });
        queueProp(propQueue, 1250, 334, function() { parentState.solidBlock.add(new SolidBlock(1250, 334, 60)); });
        queueProp(propQueue, 1250, 384, function() { parentState.solidBlock.add(new SolidBlock(1250, 384, 60)); });
        queueProp(propQueue, 1250, 434, function() { parentState.solidBlock.add(new SolidBlock(1250, 434, 60)); });
        queueProp(propQueue, 1250, 484, function() { parentState.solidBlock.add(new SolidBlock(1250, 484, 60)); });
        queueProp(propQueue, 1250, 534, function() { parentState.solidBlock.add(new SolidBlock(1250, 534, 60)); });

        queueProp(propQueue, 50, -16, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, -16, 1, "active", 25, true, 0.5)); });
        queueProp(propQueue, 50, 34, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 34, 1, "disabled", 25, true, 0.5)); });
        queueProp(propQueue, 50, 84, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 84, 1, "active", 25, true, 0.5)); });
        queueProp(propQueue, 50, 134, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 134, 1, "disabled", 25, true, 0.5)); });
        queueProp(propQueue, 50, 184, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 184, 1, "active", 25, true, 0.5)); });
        queueProp(propQueue, 50, 234, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 234, 1, "disabled", 25, true, 0.5)); });
        queueProp(propQueue, 50, 284, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 284, 1, "active", 25, true, 0.5)); });
        queueProp(propQueue, 50, 334, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 334, 1, "disabled", 25, true, 0.5)); });
        queueProp(propQueue, 50, 384, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 384, 1, "active", 25, true, 0.5)); });
        queueProp(propQueue, 50, 434, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 434, 1, "disabled", 25, true, 0.5)); });
        queueProp(propQueue, 50, 484, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 484, 1, "active", 25, true, 0.5)); });
        queueProp(propQueue, 50, 534, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 534, 1, "disabled", 25, true, 0.5)); });

        queueProp(propQueue, 1200, -16, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, -16, 3, "active", 25, true, 0.5)); });
        queueProp(propQueue, 1200, 34, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 34, 3, "disabled", 25, true, 0.5)); });
        queueProp(propQueue, 1200, 84, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 84, 3, "active", 25, true, 0.5)); });
        queueProp(propQueue, 1200, 134, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 134, 3, "disabled", 25, true, 0.5)); });
        queueProp(propQueue, 1200, 184, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 184, 3, "active", 25, true, 0.5)); });
        queueProp(propQueue, 1200, 234, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 234, 3, "disabled", 25, true, 0.5)); });
        queueProp(propQueue, 1200, 284, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 284, 3, "active", 25, true, 0.5)); });
        queueProp(propQueue, 1200, 334, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 334, 3, "disabled", 25, true, 0.5)); });
        queueProp(propQueue, 1200, 384, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 384, 3, "active", 25, true, 0.5)); });
        queueProp(propQueue, 1200, 434, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 434, 3, "disabled", 25, true, 0.5)); });
        queueProp(propQueue, 1200, 484, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 484, 3, "active", 25, true, 0.5)); });
        queueProp(propQueue, 1200, 534, function() { parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 534, 3, "disabled", 25, true, 0.5)); });

        runPropQueue(propQueue, 3, function()
        {
            startCutscene();
        });
    }

    public function createPropsUlt()
    {

        parentState.trampolinesMini.add(new NormalTrampolineMini(820, 535, "up"));

        parentState.slabs.add(new NormalSlab(620, 385, 71));
        parentState.dangerObjects.add(new SmallSpike(620, 406, 2));
        parentState.dangerObjects.add(new SmallSpike(645, 406, 2));

        parentState.slabs.add(new NormalSlab(570, 385, 71));
        parentState.dangerObjects.add(new SmallSpike(595, 406, 2));
        parentState.dangerObjects.add(new SmallSpike(570, 406, 2));

        parentState.slabs.add(new NormalSlab(670, 385, 71));
        parentState.dangerObjects.add(new SmallSpike(670, 406, 2));
        parentState.dangerObjects.add(new SmallSpike(695, 406, 2));

        parentState.slabs.add(new NormalSlab(320, 354, 71));
        parentState.dangerObjects.add(new SmallSpike(345, 375, 2));
        parentState.dangerObjects.add(new SmallSpike(320, 375, 2));

        parentState.slabs.add(new NormalSlab(270, 354, 71));
        parentState.dangerObjects.add(new SmallSpike(295, 375, 2));
        parentState.dangerObjects.add(new SmallSpike(270, 375, 2));

        parentState.slabs.add(new NormalSlab(220, 354, 71));
        parentState.dangerObjects.add(new SmallSpike(245, 375, 2));
        parentState.dangerObjects.add(new SmallSpike(220, 375, 2));

        parentState.slabs.add(new NormalSlab(170, 354, 71));
        parentState.dangerObjects.add(new SmallSpike(195, 375, 2));
        parentState.dangerObjects.add(new SmallSpike(170, 375, 2));

        parentState.slabs.add(new NormalSlab(270, 200, 71));
        parentState.slabs.add(new NormalSlab(220, 200, 71));

        parentState.slabs.add(new NormalSlab(920, 354, 71));
        parentState.dangerObjects.add(new SmallSpike(945, 375, 2));
        parentState.dangerObjects.add(new SmallSpike(920, 375, 2));

        parentState.slabs.add(new NormalSlab(970, 354, 71));
        parentState.dangerObjects.add(new SmallSpike(970, 375, 2));
        parentState.dangerObjects.add(new SmallSpike(995, 375, 2));

        parentState.slabs.add(new NormalSlab(1020, 354, 71));
        parentState.dangerObjects.add(new SmallSpike(1020, 375, 2));
        parentState.dangerObjects.add(new SmallSpike(1045, 375, 2));

        parentState.slabs.add(new NormalSlab(1070, 354, 71));
        parentState.dangerObjects.add(new SmallSpike(1070, 375, 2));
        parentState.dangerObjects.add(new SmallSpike(1095, 375, 2));

        parentState.slabs.add(new NormalSlab(970, 200, 71));
        parentState.slabs.add(new NormalSlab(1020, 200, 71));

        parentState.solidBlock.add(new SolidBlock(0, -16, 59));
        parentState.solidBlock.add(new SolidBlock(0, 34, 59));
        parentState.solidBlock.add(new SolidBlock(0, 84, 59));
        parentState.solidBlock.add(new SolidBlock(0, 134, 59));
        parentState.solidBlock.add(new SolidBlock(0, 184, 59));
        parentState.solidBlock.add(new SolidBlock(0, 234, 59)); 
        parentState.solidBlock.add(new SolidBlock(0, 284, 59));
        parentState.solidBlock.add(new SolidBlock(0, 334, 59));
        parentState.solidBlock.add(new SolidBlock(0, 384, 59)); 
        parentState.solidBlock.add(new SolidBlock(0, 434, 59));
        parentState.solidBlock.add(new SolidBlock(0, 484, 59)); 
        parentState.solidBlock.add(new SolidBlock(0, 534, 59));

        parentState.solidBlock.add(new SolidBlock(1250, -16, 60));
        parentState.solidBlock.add(new SolidBlock(1250, 34, 60));
        parentState.solidBlock.add(new SolidBlock(1250, 84, 60));
        parentState.solidBlock.add(new SolidBlock(1250, 134, 60));
        parentState.solidBlock.add(new SolidBlock(1250, 184, 60));
        parentState.solidBlock.add(new SolidBlock(1250, 234, 60)); 
        parentState.solidBlock.add(new SolidBlock(1250, 284, 60));
        parentState.solidBlock.add(new SolidBlock(1250, 334, 60)); 
        parentState.solidBlock.add(new SolidBlock(1250, 384, 60));
        parentState.solidBlock.add(new SolidBlock(1250, 434, 60));
        parentState.solidBlock.add(new SolidBlock(1250, 484, 60));
        parentState.solidBlock.add(new SolidBlock(1250, 534, 60));

        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, -16, 1, "active", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 34, 1, "disabled", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 84, 1, "active", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 134, 1, "disabled", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 184, 1, "active", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 234, 1, "disabled", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 284, 1, "active", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 334, 1, "disabled", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 384, 1, "active", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 434, 1, "disabled", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 484, 1, "active", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(50, 534, 1, "disabled", 25, true, 0.5));

        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, -16, 3, "active", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 34, 3, "disabled", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 84, 3, "active", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 134, 3, "disabled", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 184, 3, "active", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 234, 3, "disabled", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 284, 3, "active", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 334, 3, "disabled", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 384, 3, "active", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 434, 3, "disabled", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 484, 3, "active", 25, true, 0.5));
        parentState.dangerObjects.add(new leveldata.hazards.SwitchSpike(1200, 534, 3, "disabled", 25, true, 0.5));

    }

    function queueProp(queue:Array<Void->Void>, x:Float, y:Float, create:Void->Void):Void
    {
        queue.push(function()
        {
            create();
            spawnPropEffect(x, y);
        });
    }

    function runPropQueue(queue:Array<Void->Void>, index:Int, onComplete:Void->Void):Void
    {
        if (index >= queue.length)
        {
            onComplete();
            return;
        }

        queue[index]();

        new FlxTimer().start(0.01, function(_)
        {
            runPropQueue(queue, index + 1, onComplete);
        });

    }

    function spawnPropEffect(x:Float, y:Float):Void
    {
        var particle = new flixel.effects.particles.FlxEmitter(x + 5, y + 5, 8);
        particle.makeParticles(3, 3, FlxColor.WHITE, 12);
        particle.color.set(FlxColor.WHITE);
        particle.launchMode = CIRCLE;
        particle.drag.set(100, 100);
        particle.speed.set(50, 100);
        particle.angularVelocity.set(-300, 300);
        particle.lifespan.set(0.3, 0.5);
        parentState.add(particle);
        particle.start(true, 0, 12);
    }
    
    public function startCutscene()
    {
        state = "cutscene";
        parentState.currentBossName = "jevil";

        animation.play("laugh");
        FlxG.sound.play(AssetPaths.jevil_laugh01__ogg);
        this.shield.visible = true;
        FlxTween.tween(shield, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});

        new FlxTimer().start(1.0, function(_)
        {
            if (parentState.player != null && parentState.player.exists && parentState.player.alive)
            {
                var scythe = new IntroScythe(parentState.player.x -50, parentState.map.y - 100, parentState);
                FlxG.sound.play(AssetPaths.scythe_intro__ogg, 1, false);
                parentState.dangerObjects.add(scythe);
                parentState.player.active = true;
            }


            new FlxTimer().start(1.0, function(_)
            {
                state = "phase1";
                isVulnerable = false;
                if (!battleMusicStarted)
                {
                    battleMusicStarted = true;
                    if (parentState.player != null && parentState.player.exists && parentState.player.alive)
                    {
                        flash.alpha = 0.35;
                        FlxG.sound.play(AssetPaths.start_fight01__ogg, 0.75, false);
                        FlxG.sound.playMusic(AssetPaths.jevil_fight__ogg, 0.75, true);
                    }
                }
                parentState.initBossHUD(this);
                startAttack();
            });
        });

        new FlxTimer().start(1.0, function(_)
        {
            FlxTween.tween(this, {x: 590, y: 100}, 0.5,
            {
                ease: FlxEase.sineIn,
                onComplete: function(_)
                {
                    FlxTween.cancelTweensOf(this);
                }
            
            });

        });
    }

    function startAttack()
    {
        if (ultimateTriggered || state == "ultimate_barrage"|| state == "ultimate_cutscene" || state == "ultimate_transition" || state == "startCube") return;
        if (hp <= 0) { return; }

        if (parentState.player == null || !parentState.player.exists || !parentState.player.alive)
        {
            return;
        }

        FlxTween.cancelTweensOf(this);
        var phaseID = getPhaseID();
        var sequence = getSequenceForPhase(phaseID);

        if (phaseID != currentPhaseID)
        {
            currentPhaseID = phaseID;
            patternStep = 0;
        }

        var nextAttack = sequence[patternStep % sequence.length];
        patternStep++;
        nextAttack();

    }

    function getPhaseID():Int
    {
        if (hp >= 90) return 1;
        if (hp >= 50 && hp < 90) return 2;
        if (hp >= 0 && hp < 50) return 3;
        return 1;
    }

    function getSequenceForPhase(phaseID:Int):Array<Void->Void>
    {
        return switch (phaseID)
        {
            case 1: phase01Attacks;
            case 2: phase02Attacks;
            case 3: phase03Attacks;
            default: phase01Attacks;
        }
    }   

    public function takeDamage(damageAmount:Int)
    {
        var dmgTextWidth:Int = 24;
        var dmgTextX:Float = this.x + (this.width + 5 - dmgTextWidth) / 2;
        var dmgTextY:Float = this.y - 22;
        var dmgText:flixel.text.FlxText = new flixel.text.FlxText(dmgTextX, dmgTextY, dmgTextWidth, "1", 16);
        dmgText.setFormat("assets/fonts/deltarune.otf", 24, FlxColor.WHITE, "center", flixel.text.FlxText.FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        if (parentState != null) parentState.add(dmgText);

        flixel.tweens.FlxTween.tween(dmgText, { y: dmgTextY - 10 }, 0.18, { ease: flixel.tweens.FlxEase.quadOut, onComplete: function(t)
        {
            flixel.tweens.FlxTween.tween(dmgText, { y: dmgTextY - 6 }, 0.12, { ease: flixel.tweens.FlxEase.quadIn });
        }});

        new flixel.util.FlxTimer().start(0.75, function(_)
        {
            if (dmgText != null)
            {
                dmgText.kill();
                dmgText.destroy();
            }
        });


        if (!isVulnerable || !canBeHit || hp <= 0)
        {
            return;
        }

        hp -= damageAmount;

        if (!ultimateTriggered && hp == 50)
        {
            ultimateTriggered = true;
            startUltimateAttack();
            return;
        }

        FlxG.sound.play(AssetPaths.jevil_hit__ogg, 1, false);
        trace("[ HP Remaioning: " + hp + " ]");

        canBeHit = false;
        new FlxTimer().start(0.1, function(_)
        {
            canBeHit = true;
        });

        if (this.alpha == 1)
        {
            FlxFlicker.flicker(this, 0.25, 0.05, true);
        }

        if (hp <= 0)
        {
            state = "dead"; 
           jevilDeath();
        }
    }

    function attackBullets()
    {
        if (shield.alpha != 0 || shield.visible == false)
        {
            shield.visible = true;
            FlxTween.tween(this.shield, {alpha: 1}, 1);
        }
        animation.play("teleport");
        new FlxTimer().start(1.75, function(_)
        {
            animation.stop();
            animation.play("dance");
        });

        FlxG.sound.play(AssetPaths.jevil_random_talk01__ogg, 0.75, false);
        this.x = 590;
        this.y = 100;
        var bulletCount:Int = 10;
        var interval:Float = 0.2;

        if (hp <= 50) {bulletCount = 15; interval = 0.15; }

        for (i in 0...bulletCount)
        {
            new FlxTimer().start(i * interval, function(_)
            {
                FlxG.sound.play(AssetPaths.playershoot__ogg, 1, false);
                var angle = flixel.math.FlxAngle.angleBetween(this, parentState.player, true);
                angle += FlxG.random.float(-15, 15);
                var b = new JevilBullet(x, y, "circle", angle, parentState);
                parentState.dangerObjects.add(b);
            });
        }
        new FlxTimer().start(2.5, teleport);
    }

    function attackFan()
    {
        if (fanComboCount == 0)
        {
            targetFanCombos = FlxG.random.int(2, 4);
        }

        if (parentState != null && parentState.player != null && parentState.player.exists)
        {
            if (parentState.player.x > FlxG.width / 2)
            {
                animation.play("teleportReverse", true, false);
            }
            else
            {
                animation.play("teleport", true, false);
            }
        }
        else
        {
            animation.play("teleport", true, false);
        }

        new FlxTimer().start(0.5, function(_)
        {
            animation.stop();
            animation.play("dance");
        });

        FlxG.sound.play(AssetPaths.jevil_laugh03__ogg, 0.75, false);
        FlxG.sound.play(AssetPaths.scythe_explosion__ogg, 0.65, false);
        this.flash.alpha = 0.2;

        var interval:Float;
        if (hp >= 50) { interval = 1.5; }
        else { interval = 1.25; }

        var offsets:Array<Float> = [-250, -125, 0, 125, 250];

        for (i in 0... 5)
        {
            var randomSpeed = FlxG.random.int(400, 600);
            var bomb = new JevilBombs(x + (width / 2), y + (height / 2), "circle", parentState);
            bomb.animation.frameIndex = 0;
            parentState.dangerObjects.add(bomb);
            bomb.scale.set(2, 2);

            flixel.math.FlxVelocity.moveTowardsPoint(bomb, FlxPoint.get(parentState.player.x + offsets[i], parentState.player.y), randomSpeed);
        }

        fanComboCount++;

        if (fanComboCount >= targetFanCombos)
        {
            fanComboCount = 0;
            targetFanCombos = 0;

            new FlxTimer().start(1, teleport);
        }
        else
        {
            new FlxTimer().start(interval, function(_)
            {
                if (ultimateTriggered || state == "ultimate_barrage") return;
                attackFan();
            });
        }
    }
    
    function attackSpades()
    {
        var randomY:Float = FlxG.random.float(250, 500);
        var goLeft:Bool = false;
        
        if (spadeComboCount == 0 && hp >= 90)
        {
            targetSpadeCombos = FlxG.random.int(4, 8);
        }
        else
        {
            targetSpadeCombos = FlxG.random.int(6, 12);
        }
        
        if (spadeComboCount == 0)
        {
            goLeft = FlxG.random.bool(50);
        }
        else
        {
            goLeft = !lastAttackWasLeft;
        }

        x = goLeft ? 150 : 1080;
        y = randomY;

        if (goLeft)
        {
            animation.play("teleportReverse", true, false);
            lastAttackWasLeft = true;
        }
        else
        {
            animation.play("teleport", true, false);
            lastAttackWasLeft = false;
        }

        particlesJevil();

        FlxTween.globalManager.cancelTweensOf(this);
        FlxG.sound.play(AssetPaths.jevil_attack01__ogg, 0.75, false);
        FlxG.sound.play(AssetPaths.beep__ogg, 0.5, false);
        
        var cooldownAttack:Float = 0.75;
        if (hp <= 90) { cooldownAttack = 0.5; }

        var bulletSpawnX:Float = x + (width / 2) - 25;
        var bulletSpawnY:Float = y + (height / 2) - 50;

        var baseAngle = flixel.math.FlxAngle.angleBetween(this, parentState.player, true);
        var spreadOffsets:Array<Float> = [-15, -5, 5, 15];
        
        for (offset in spreadOffsets)
        {
            var finalAngle = baseAngle + offset + FlxG.random.float(-3, 3);
            
            var b = new JevilBullet(bulletSpawnX, bulletSpawnY, "spade", finalAngle, parentState);
            b.scale.set(1, 1);
            b.animation.play("clubIdle");
            b.updateHitbox();
            parentState.dangerObjects.add(b);
        }

        spadeComboCount++;

        FlxTween.tween(this, {y: y - 10}, 0.75, {type: PINGPONG, ease: FlxEase.sineInOut});

        if (spadeComboCount >= targetSpadeCombos)
        {
            spadeComboCount = 0;
            targetSpadeCombos = 0;
            new FlxTimer().start(0.5, teleport);
        }
        else
        {
            new FlxTimer().start(cooldownAttack, function(_)
            {
                if (ultimateTriggered || state == "ultimate_barrage") return;
                FlxTween.cancelTweensOf(this);
                attackSpades();
            });
        }
    }
     
    function attackScythe()
    {
        animation.play("teleport");

        new FlxTimer().start(0.5, function(_)
        {
            FlxTween.tween(this.shield, {alpha: 0}, 0.5, {ease: FlxEase.quadOut});
            FlxTween.tween(this, {alpha: 0}, 0.5, {ease: FlxEase.quadOut});
        });


        if (FlxG.sound.music != null && FlxG.sound.music.playing)
        {
            var randomSound = FlxG.random.int(0, 1);

            switch (randomSound)
            {
                case 0:
                    FlxG.sound.play(AssetPaths.jevil_attack02__ogg);
                case 1:
                    FlxG.sound.play(AssetPaths.jevil_attack03__ogg);
                default:
                    FlxG.sound.play(AssetPaths.jevil_attack02__ogg);
            }
        }

        var dist:Float = 250;
        var px:Float = parentState.player.x + (parentState.player.width / 2);
        var py:Float = parentState.player.y + (parentState.player.height / 2);


        spawnScythe(px - 25, py - dist); // Top
        spawnScythe(px - 25, py + dist); // Bottom
        spawnScythe(px - dist, py - 25); // Left
        spawnScythe(px + dist, py - 25); // Right

        new FlxTimer().start(2.5, function(_)
        {
            FlxTween.tween(shield, {alpha: 1}, 0.25, {ease: FlxEase.quadIn});
            FlxTween.tween(this, {alpha: 1}, 0.25, {ease: FlxEase.quadIn});
            this.alpha = 1;
            teleport(_);
        });
    }

    function spawnScythe(sX:Float, sY:Float)
    {
        var s = new JevilDiamondScythe(sX, sY, parentState);
        parentState.dangerObjects.add(s);
    }

    function attackJail()
    {
        state = "attacking_jail";
        isVulnerable = false;

        x = 875;
        y = 58;

        particlesJevil();
        
        animation.play("laugh");
        this.flash.alpha = 0.2;
        FlxG.sound.play(AssetPaths.scythe_intro__ogg, 0.5, false);
        FlxG.sound.play(AssetPaths.jevil_laugh01__ogg);
        jailManager.createJail(0);

        var midX:Float = FlxG.width / 2;
        var midY:Float = FlxG.height / 2;
        var cellBottomY:Float = (midY - 25);
        var cellLeftX:Float = (midX - 200) + 10;
        var cellRightX:Float = (midX + 200) - 25;

        new FlxTimer().start(1.0, function(_)
        {
            var totalJewels:Int = 30;
            var spawnInterval:Float = 0.25;
            animation.play("dance");

            new FlxTimer().start(7.0, function(_)
            {
                animation.play("teleport" , true);
                FlxG.sound.play(AssetPaths.jevil_random_talk01__ogg, 1, false);
            });

            if (hp <= 50 && hp >= 35) { totalJewels = 40; spawnInterval = 0.2;}
            else if (hp < 25) { totalJewels = 50; spawnInterval = 0.185;}

            for (i in 0...totalJewels)
            {
                new FlxTimer().start(i * spawnInterval, function(t:FlxTimer)
                {
                    if (state != "attacking_jail" || !exists) return;

                    var randomX:Float = FlxG.random.float(cellLeftX + 50, cellRightX);
                    var jewel = new main.bosses.ch1.JevilProjectiles.JevilJewel(randomX, cellBottomY, parentState);
                    
                    parentState.dangerObjects.add(jewel);

                    if (i == totalJewels - 1)
                    {
                        new FlxTimer().start(1, function(_)
                        {
                            animation.play("laugh");
                            FlxG.sound.play(AssetPaths.jevil_explosion__ogg, 0.75, false);
                            FlxG.camera.shake(0.01, 0.15);
                            FlxG.sound.play(AssetPaths.jevil_laugh02__ogg, 1, false);

                            var particle = new flixel.effects.particles.FlxEmitter(650, 200);
                            particle.makeParticles(5, 5, FlxColor.WHITE, 150);
                            particle.color.set(FlxColor.RED, FlxColor.RED, FlxColor.ORANGE, FlxColor.YELLOW);
                            particle.launchMode = CIRCLE;
                            particle.speed.set(200, 500);
                            particle.lifespan.set(1, 3);
                            parentState.add(particle);
                            particle.start(true, 0, 150);

                            new FlxTimer().start(3.5, function(_)
                            {
                                if (parentState != null) 
                                {
                                    parentState.remove(particle);
                                }
                                if (particle != null) 
                                {
                                    particle.destroy();
                                }
                            });

                            jailManager.destroyJail();
                            

                            new FlxTimer().start(0.75, function(_)
                            {
                                teleport(null);
                            });

                        });
                    }
                });
            }
        });

    }

    function attackCircle()
    {
        state = "attacking_circle";
        FlxG.sound.play(AssetPaths.jevil_strong_attack01__ogg, 0.75, false);
        isVulnerable = false;

        animation.play("teleport");

        new FlxTimer().start(0.75, function(_)
        {
            animation.play("dance");
        });
        
        circleSpades = [];

        var radius:Float = 215;
        var totalSpades:Int = 12;
        var spawnInterval:Float = 0.15;

        if (hp <= 35) { spawnInterval = 0.1; radius = 200;}

        for (i in 0...totalSpades)
        {
            new FlxTimer().start(i * spawnInterval, function(t:FlxTimer)
            {
                if (state != "attacking_circle" || !exists) return;

                var angleDeg:Float = i * (360 / totalSpades);
                var angleRad:Float = angleDeg * Math.PI / 180;
                var spade = new main.bosses.ch1.JevilProjectiles.JevilCircleSpade(angleRad, radius, parentState.player, parentState);
                parentState.dangerObjects.add(spade);
                circleSpades.push(spade);

                FlxG.sound.play(AssetPaths.beep__ogg, 0.35, false);

                if (i == totalSpades - 1)
                {
                    new FlxTimer().start(1.0, function(_)
                    {
                        launchCircleSpadesSequence();
                        var randomSound = FlxG.random.int(1, 4);
                        animation.play("laugh");

                        new FlxTimer().start(1, function(_)
                        {
                            animation.play("dance");
                        });

                        FlxG.sound.play("assets/sounds/enemies/jevil/jevil_laugh0" + randomSound + ".ogg", 0.75, false);
                    });
                }
            });
        }
    }

    function launchCircleSpadesSequence()
    {
        for (spade in circleSpades)
        {
            if (spade != null && spade.exists)
            {
                spade.isFollowing = false;
            }
        }

        var launchIndex:Int = 0;
        var launchInterval:Float = 0.15;

        if (hp <= 35) { launchInterval = 0.125; }

        new FlxTimer().start(launchInterval, function(t:FlxTimer)
        {
            if (state != "attacking_circle" || !exists || circleSpades.length == 0)
            {
                t.destroy();
                return;
            }

            if (launchIndex < circleSpades.length)
            {
                var currentSpade = circleSpades[launchIndex];
                if (currentSpade != null && currentSpade.exists)
                {
                    var pX:Float = parentState.player.x + (parentState.player.width / 2);
                    var pY:Float = parentState.player.y + (parentState.player.height / 2);

                    currentSpade.launch(pX, pY, 750);
                    FlxG.sound.play(AssetPaths.dash__ogg, 0.3, false);
                    FlxG.sound.play(AssetPaths.jevil_teleport__ogg, 0.25, false);
                }
                
                launchIndex++;
                
                if (launchIndex >= circleSpades.length)
                {
                    new FlxTimer().start(1.5, function(_)
                    {
                        circleSpades = [];
                        teleport(null);
                    });
                }
            }
        }, circleSpades.length);
    }   

    function attackBombarding()
    {
        state = "attacking_bombarding";
        isVulnerable = false;

        animation.play("dance");
        FlxG.sound.play(AssetPaths.jevil_strong_attack03__ogg, 0.75, false);

        var totalBombs:Int = 6;
        var dropInterval:Float = 0.75;

        if (hp <= 50 && hp >= 25) { totalBombs = 8; dropInterval = 0.6;}
        else if (hp < 25) { totalBombs = 12; dropInterval = 0.5; }

        var ceilingY:Float = parentState.map.y + 20;

        for (i in 0...totalBombs)
        {
            new FlxTimer().start(i * dropInterval, function(t:FlxTimer)
            {
                if (state != "attacking_bombarding" || !exists) return;

                var randomX:Float = FlxG.random.bool(50) ? 150 : 1150;

                var bomb = new main.bosses.ch1.JevilProjectiles.JevilBombardingBomb(randomX, ceilingY, parentState);
                parentState.dangerObjects.add(bomb);

                if (i == totalBombs - 1)
                {
                    new FlxTimer().start(1.5, function(_)
                    {
                        teleport(null);
                    });
                }
            });
        }
    }

    function attackHearts()
    {
        state = "attacking_hearts";
        isVulnerable = false;

        var totalBombs:Int = 28;
        var travelSpeed:Float = 325;

        if (hp <= 50)
        {
            totalBombs = 40;
            travelSpeed = 400;
        }

        var totalWaves:Int = Std.int(totalBombs / 4);
        var waveInterval:Float = 0.75;
        var orbitAngles:Array<Float> = [0, 90, 180, 270];

        for (i in 0...totalWaves)
        {
            new FlxTimer().start(i * waveInterval, function(_)
            {
                if (state != "attacking_hearts" || !exists) return;

                var spawnLeft:Bool = FlxG.random.bool(50);
                var diamondCenterX:Float = spawnLeft ? 200 : 1100;
                var diamondCenterY:Float = FlxG.random.float(200, 550);
                var direction:Int = spawnLeft ? 1 : -1;

                FlxTween.cancelTweensOf(this);
                this.x = diamondCenterX - (this.width / 2);

                this.y = (diamondCenterY - (this.height / 2));

                animation.play(this.x < FlxG.width / 2 ? "teleportReverse" : "teleport", true, false);
                
                particlesJevil();

                FlxG.sound.play(AssetPaths.jevil_attack01__ogg, 0.75, false);
                FlxG.sound.play(AssetPaths.beep__ogg, 0.5, false);
                this.flash.alpha = 0.15;

                for (angleOffset in orbitAngles)
                {
                    var heart = new main.bosses.ch1.JevilProjectiles.JevilHeartBomb(diamondCenterX, diamondCenterY, angleOffset, 50, travelSpeed, direction);
                    parentState.dangerObjects.add(heart);
                }

                new FlxTimer().start(0.5, function(_)
                {
                    if (state == "attacking_hearts" && exists)
                    {
                        animation.stop();
                        animation.play("dance");
                    }
                });

                if (i == totalWaves - 1)
                {
                    new FlxTimer().start(1.0, function(_)
                    {
                        teleport(null);
                    });
                }
            });
        }
    }

    function startUltimateAttack()
    {
        
        this.visible = true;
        state = "ultimate_cutscene";
        FlxTween.cancelTweensOf(this);
        scale.set(2.5, 2.5);
        updateHitbox();
        animation.play("teleport");
        isVulnerable = false;
        if (parentState.dangerObjects != null)
        {
            parentState.dangerObjects.forEach(function(obj:flixel.FlxBasic)
            {
                if (obj != null)
                {
                    obj.destroy();
                }
            });
            
            parentState.dangerObjects.clear();
        }

        if (jailManager != null)
        {
            jailManager.destroyJail();
        }

        parentState.player.active = false;
        parentState.player.velocity.set(0, 0);
        parentState.player.acceleration.set(0, 0);
        
        this.x = 590;
        this.y = 250;

        if (parentState.bossHpBar != null) FlxTween.tween(parentState.bossHpBar, {alpha: 0}, 1, { ease: FlxEase.backIn });

        FlxTween.tween(this, {y: y - 10}, 0.75, {type: PINGPONG, ease: FlxEase.sineInOut});

        FlxG.sound.play(AssetPaths.jevil_attack02__ogg, 1.0, false);
        state = "ultimate_start";

        new FlxTimer().start(1, function(_)
        {
            if (!exists) return;
            this.flipX = true;

            new FlxTimer().start(1.0, function(_)
            {
                if (!exists) return;
                state = "ultimate_transition";
                PlayerData.lastMusicTime = FlxG.sound.music.time;
                PlayerData.currentSkin = "thekris";
                FlxTween.cancelTweensOf(this);
                this.flipX = true;
                main.RoomLoader.loadRoom(parentState, "boss-jevil03");
                FlxG.sound.music.time = PlayerData.lastMusicTime;
            });

            new FlxTimer().start(1.5, function(_)
            {
                FlxG.sound.play(AssetPaths.jevil_strong_attack01__ogg, 2.0, false);
            });
        });
    }

    public function attackCube()
    {
        if (cubeTriggered == true)
        {
            this.teleport();
            trace("attackCube early return");
            trace(cubeTriggered);
            return;
        }


        else
        {  
            cubeTriggered = true;
            trace("cubeTriggered is true");
        }
        
        this.flipX = false;
        state = "startCube";
        isVulnerable = false;
        FlxTween.cancelTweensOf(this);

        parentState.player.active = false;
        parentState.player.velocity.set(0, 0);
        parentState.player.acceleration.set(0, 0);

        animation.play("teleport", true, false);
        FlxG.sound.play(AssetPaths.jevil_random_talk01__ogg, 1, false);
        FlxTween.tween(shield, {alpha: 0}, 1, { ease: FlxEase.backIn });

        x = 590;
        y = 100;


        new FlxTimer().start(1.5, function(_)
        {
            FlxTween.tween(blackFade, {alpha: 0.75}, 1, { ease: FlxEase.backIn });
            if (parentState.bossHpBar != null)  FlxTween.tween(parentState.bossHpBar, {alpha: 0.25}, 1, { ease: FlxEase.backIn });
            new FlxTimer().start(0.3, function(_)
            {
                state = "attackingCube";
                PlayerData.currentSkin = "thekris";
                var jailDir = new JevilDirectionalAttack(this, parentState);
                jailDir.start();
            });
        });
    }
    
    public function teleport(?_ = null)
    {
        
        if (ultimateTriggered || state == "ultimate_barrage" || state == "ultimate_cutscene"
            || state == "ultimate_transition" || state == "dead" ) return;

        teleportCount++;
        FlxTween.cancelTweensOf(this);
        if (parentState.bossHpBar != null) FlxTween.tween(parentState.bossHpBar, {alpha: 1}, 0.5, { ease: FlxEase.backIn });
        FlxG.sound.play(AssetPaths.jevil_teleport__ogg, 1, false);
        animation.play("teleport", true, false);

        x = 590;
        y = 100;

        particlesJevil();

        new FlxTimer().start(0.5, function(_)
        {
            FlxTween.tween(this.scale, { x: -this.scale.x }, 0.25,
            {
                ease: FlxEase.quadInOut,
                onComplete: function(_)
                {
                    new FlxTimer().start(0.4, function(_)
                    {
                        onComplete: function(_)
                        {
                            flipX = !flipX;
                        }
                    });
                    
                }
            });
        });

        new FlxTimer().start(1, function(_)
        {
            
            if (teleportCount < 4)
            {
                flipX = !flipX;
                isVulnerable = false;
                shield.visible = true;
                startAttack();
            }
            else
            {
                flipX = !flipX;
                isVulnerable = true;
                canBeHit = true;
                shield.visible = false;
                teleportCount = 0;
                animation.play("tired");
                FlxTween.tween(this, { x: 590, y: 250 }, 0.5, { ease: FlxEase.quadOut });

                new FlxTimer().start(0.6, function(_)
                {
                    FlxTween.cancelTweensOf(this);
                    FlxTween.tween(this, {y: this.y - 5}, 0.5, {type: PINGPONG, ease: FlxEase.sineInOut});
                });

                new FlxTimer().start(2, function(_)
                {
                    FlxTween.cancelTweensOf(this);
                    FlxTween.tween(this, { x: 590, y: 100 }, 0.5, { ease: FlxEase.quadIn });
                });

                new FlxTimer().start(4, function(_)
                {
                    isVulnerable = false;
                    shield.visible = true;
                    startAttack();
                });


            }
        });
    }

    public function createTrail()
    {
        trail = new FlxTrail(this, null, 20, 2, 0.35, 0.04);
        parentState.add(trail);
        trail.visible = false;
    }

    function jevilDeath()
    {
        var jevilEnding = new FlxSprite();
        jevilEnding.frames = FlxAtlasFrames.fromSparrow(AssetPaths.jevil__png, AssetPaths.jevil__xml);
        jevilEnding.animation.addByPrefix("laugh", "jevil_laugh", 12, true);
        jevilEnding.animation.addByPrefix("danceLowHP", "jevil_dance_", 16, true);
        jevilEnding.animation.addByPrefix("teleportReverse", "jevil_teleport_r", 6, false);
        jevilEnding.animation.play("teleportReverse");
        jevilEnding.immovable = true;
        jevilEnding.scale.set(12, 12);
        jevilEnding.visible = false;
        parentState.add(jevilEnding);

        whiteFade.makeGraphic(FlxG.width + 50, FlxG.height + 50, FlxColor.WHITE, false);
        whiteFade.screenCenter();
        whiteFade.alpha = 0;
        parentState.add(whiteFade);


        parentState.bossHpBar.visible = false;
        parentState.bossHpBar.destroy();
        parentState.inmortal = true;
        parentState.player.active = false; 
        parentState.player.velocity.set(0, 0);
        parentState.player.acceleration.x = 0;

        if (FlxG.sound.music != null) { FlxG.sound.music.stop(); }

        FlxTween.cancelTweensOf(this);
        this.shield.visible = false;
        this.shield.destroy();
        this.alpha = 1;
        this.visible = true;

        this.x = 590;
        this.y = 150;

        this.animation.play("teleport", true, false);
        FlxG.sound.play(AssetPaths.jevil_laugh03__ogg, 1, false);

        new FlxTimer().start(2, function(_)
        {
            FlxG.sound.play(AssetPaths.jevil_laugh04__ogg, 1, false);
            this.animation.play("teleportReverse", true, false);
        });

        new FlxTimer().start(4, function(_)
        {
            this.animation.play("tired", true, false);
            FlxG.camera.shake(0.01, 0.15);
            FlxG.sound.play(AssetPaths.jevil_hit__ogg, 0.5, false);

            FlxTween.tween(this, {alpha: 0}, 1.5);
        });

        new FlxTimer().start(6, function(_)
        {
            this.visible = false;
            this.alpha = 0;
            
            jevilEnding.x = 250;
            jevilEnding.y = 300;
            jevilEnding.angle = -5;
            jevilEnding.visible = true;
            FlxTween.tween(jevilEnding, {y: jevilEnding.y - 20}, 0.8, {type: PINGPONG, ease: FlxEase.sineInOut});
            FlxG.sound.play(AssetPaths.start_fight02__ogg, 1, false);
            FlxG.sound.play(AssetPaths.jevil_strong_attack01__ogg, 1, false);
            FlxG.sound.play(AssetPaths.jevil_final_strike__ogg, 1, false);
            FlxG.sound.play(AssetPaths.jevil_cutscene__ogg, 1, false);
            FlxG.camera.shake(0.01, 6);

            var particle = new flixel.effects.particles.FlxEmitter(jevilEnding.x + (width / 2), jevilEnding.y + (height / 2), 25);
            particle.makeParticles(10, 10, FlxColor.WHITE, 150);
            particle.color.set(FlxColor.RED, FlxColor.GREEN, FlxColor.YELLOW, FlxColor.BLUE);
            particle.launchMode = CIRCLE;
            particle.speed.set(150, 350);
            particle.lifespan.set(2, 3);
            parentState.add(particle);
            particle.start(true, 0, 150);

            flash.alpha = 0.75;
            whiteFade.alpha = 0.25;

            var scytheTimer = new FlxTimer().start(0.08, function(timer:FlxTimer)
            {
                if (parentState == null || !jevilEnding.visible)
                {
                    timer.cancel();
                    return;
                }

                var fakeScythe = new FlxSprite(FlxG.random.float(-50, FlxG.width), -200);
                fakeScythe.loadGraphic(AssetPaths.jevil_scythe__png, false);
                
                var randomScale = FlxG.random.float(1.5, 5.0);
                fakeScythe.scale.set(randomScale, randomScale);
                fakeScythe.updateHitbox();
                
                fakeScythe.velocity.y = FlxG.random.float(600, 1400);
                fakeScythe.angularVelocity = FlxG.random.float(400, 1000);

                var fadeIdx = parentState.members.indexOf(whiteFade);
                if (fadeIdx != -1) parentState.insert(fadeIdx, fakeScythe);
                else parentState.add(fakeScythe);

                new FlxTimer().start(2.0, function(_)
                {
                    fakeScythe.destroy();
                });
            }, 75);
            
            FlxTween.tween(whiteFade, {alpha: 1}, 6,
            {
                onComplete: function(_)
                {
                    jevilEnding.visible = false;
                    new FlxTimer().start(2.5, function(_)
                    {

                        parentState.player.active = true;
                        RoomLoader.loadRoom(parentState, "boss-jevil05");
                        FlxG.camera.stopShake;
                        jevilEnding.destroy();
                        fightingBoss = false;
                        this.destroy();

                        var currentSeconds = PlayerData.totalSeconds;
                        PlayerData.spawnX = parentState.player.x;
			            PlayerData.spawnY = parentState.player.y + 60;
                        PlayerData.currentRoom = "boss-jevil05";
                        leveldata.misc.SaveManager.saveGame();
                        leveldata.misc.SaveManager.loadGame();
                        PlayerData.totalSeconds = currentSeconds;
                        whiteFade.destroy();
                        FlxG.resetState();
                        
                        
                    });
                }
            });

            var explosionAudioTimer = new FlxTimer().start(0.25, function(tmr:FlxTimer)
            {
                if (parentState == null || !exists)
                {
                    tmr.cancel();
                    return;
                }

                FlxG.sound.play(AssetPaths.scythe_explosion__ogg, 1, false);
                flash.alpha = 0.15;
            }, 0);

            new FlxTimer().start(6, function(_)
            {
                explosionAudioTimer.cancel();

            });

        });

        new FlxTimer().start(8, function(_)
        {
            jevilEnding.flipX = true;
            jevilEnding.animation.play("laugh", true, false);
            FlxG.sound.play(AssetPaths.jevil_laugh01__ogg, 1, false);

            new FlxTimer().start(2, function(_)
            {
                jevilEnding.animation.play("danceLowHP", true, false);
            });

        });


    }

    public function particlesJevil()
    {
        var particle = new flixel.effects.particles.FlxEmitter(x + (width / 2), y + (height / 2), 25);
        particle.makeParticles(4, 4, FlxColor.WHITE, 50);
        particle.color.set(FlxColor.BLUE, FlxColor.PURPLE, FlxColor.WHITE);
        particle.launchMode = CIRCLE;
        particle.speed.set(150, 350);
        particle.lifespan.set(0.25, 0.5);
        parentState.add(particle);
        particle.start(true, 0, 50);

        new FlxTimer().start(0.5, function(_)
        {
            if (parentState != null) parentState.remove(particle);
            if (particle != null) particle.destroy();
        });
    }

    override public function destroy()
    {
        if (trail != null)
        {
            trail.destroy();
            trail = null;
        }

        if (trailEffect != null)
        {
            try
            {
                trailEffect.destroy();
            }
            catch (e:Dynamic) {}
            trailEffect = null;
        }

        super.destroy();
    }



}