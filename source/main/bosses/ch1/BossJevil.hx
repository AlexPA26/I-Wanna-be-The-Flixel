package main.bosses.ch1;

import backgrounds3D.CircusBackground;
import leveldata.hazards.SolidBlock;
import leveldata.hazards.SmallSpike;
import leveldata.blockdata.NormalSlab;
import leveldata.events.NormalTrampolineMini;
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
    var scytheTimeAccumulator:Float = 0;

    public var pirouetteManager:main.bosses.ch1.JevilPirouetteManager;
    public var forceTiredTurn:Bool = false;
    public var isForcingTired:Bool = false;
    var dialogueBox:main.bosses.ch1.JevilDialogue;
    
    public var blackFade:FlxSprite;
    var whiteFade = new FlxSprite();
    var player:Player;
    public var playerHUD:FlxSprite;
    public var craziness:Bool = false;
    var soul:FlxSprite;
    public var flash:FlxSprite;
    public var ultimateManager:main.bosses.ch1.JevilUltimateState;
    public var shield:FlxSprite;
    var trailEffect:main.bosses.ch1.JevilEffect;
    var jailObjects:flixel.group.FlxGroup;
    public var battleMusicStarted:Bool = false;
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
        this.visible = true;

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

        trailEffect = new main.bosses.ch1.JevilEffect(this, parentState);
        pirouetteManager = new JevilPirouetteManager(this, parentState);
        if (parentState != null) parentState.add(trailEffect);

        // PlayerData.jevilDialogueRead = false;
        FlxTween.tween(this, {y: y - 10}, 0.75, {type: PINGPONG, ease: FlxEase.sineInOut});

        phase01Attacks = [attackBullets];
        phase02Attacks = [attackBullets];
        phase03Attacks = [attackBullets];

        // phase01Attacks =
        // [
        //     attackSpades, attackBullets, attackFan, attackFan, attackHearts, attackBullets, attackFan, attackSpades
        // ];

        // phase02Attacks =
        // [
        //     attackFan, attackScythe, attackJail, attackBullets, attackCircle, attackHearts, attackScythe,
        //     attackBombarding, attackScythe, attackJail, attackBullets, attackCircle
        // ];


        // phase03Attacks =
        // [
        //     attackBombarding, attackScythe, attackCube, attackBullets, attackJail, attackHearts,
        //     attackBombarding, attackCircle, attackHearts, attackScythe, attackBullets, attackBombarding, attackJail,
        //     attackFan, attackCircle, attackBombarding, attackHearts, attackJail
        // ];

    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (pirouetteManager != null)
        {
            pirouetteManager.update(elapsed);
        }

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

        if (state == "returningCube")
        {
            new FlxTimer().start(2, function(_)
            {
                parentState.inmortal = false;
            });
        }
        if (FlxG.keys.justPressed.U)
        {
            ultimateTriggered = true;
            startUltimateAttack();
            return;
        }

        if (FlxG.keys.justPressed.Y)
        {
            parentState.currentTP += 90;
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
        }

        if (FlxG.keys.justPressed.L) { hp -= 35; }

        if (FlxG.keys.justPressed.C)
        {
            trace("------------------------------");
            trace("Current Phase: " + state);
            trace("Current Jevil animation: " + animation.curAnim.name);
            trace("Current Health: " + this.hp);
            trace("Player alive and exists: " + parentState.player.alive + " || " + parentState.player.exists);
            trace("Player Y: " + parentState.player.y);
            trace("Player Inmortal?: " + parentState.inmortal);
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
            ultimateManager.scytheIntro(parentState, 550, 300);
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
                FlxTween.tween(parentState.player, {x: 625, y: 550}, 0.5, { });
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

        if (!parentState.player.alive && !parentState.player.exists)
        {
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

        }
    }

    public function preCutscene()
    {
        state = "precutscene";
        parentState.currentBossName = "jevil";

        parentState.player.active = false; 
        parentState.player.velocity.set(0, 0);
        parentState.player.acceleration.x = 0;
        parentState.fightingBoss = true;

        var cooldown = 0.5;
        if (PlayerData.jevilDialogueRead) cooldown = 0.15;

        new FlxTimer().start(cooldown, function(t:FlxTimer)
        {
            if (PlayerData.jevilDialogueRead)
            {
                FlxTween.cancelTweensOf(this);
                startCutscene();
            }
            else
            {
                initialDialogue();
            }
        });
    }
    

    public function initialDialogue()
    {
        new FlxTimer().start(1, function(t:FlxTimer)
        {
            FlxG.sound.play(AssetPaths.jevil_laugh01__ogg, 0.85, false);

            dialogueBox = new main.bosses.ch1.JevilDialogue(parentState);
            parentState.add(dialogueBox);

            var lines:Array<String> =
            [
                "* UEE HEE!\n* A NEW VISITOR!\n* NOW I CAN PLAY, PLAY!",
                "* OH, YOU LOOK WEAK.\n* ARE YOU ALONE?",
                "* UEE HEE HEE!\n* I WILL NOT HOLD BACK THEN!",
                "* IT'S GONNA BE FUN!\n* FUN...!!!",
                "* IF YOU DIE, YOU LOSE!",
                "* SIMPLE, RIGHT? RIGHT?!\n* UEE HEE!"
            ];

            dialogueBox.say(lines, function()
            {
                if (dialogueBox != null)
                {
                    PlayerData.jevilDialogueRead = true;
                    leveldata.misc.SaveManager.saveGame();
                    parentState.remove(dialogueBox, true);
                    dialogueBox.destroy();
                    dialogueBox = null;

                    var trailEffect = new FlxTrail(this, null, 12, 2, 0.35, 0.03);
                    var jevilIndex = parentState.members.indexOf(this);
                    if (jevilIndex != -1) parentState.insert(jevilIndex, trailEffect);
                    else parentState.add(trailEffect);

                    parentState.add(trailEffect);
                    
                    new FlxTimer().start(0.5, function(t:FlxTimer)
                    {
                        if (trailEffect != null)
                        {
                            parentState.remove(trailEffect, true);
                            trailEffect.destroy();
                            trailEffect = null;
                        }
                    });
                    
                    FlxTween.cancelTweensOf(this);
                    FlxTween.tween(this, { x: this.x + 50, y: this.y - 120 }, 0.4, { ease: FlxEase.quadOut });

                    new FlxTimer().start(0.5, function(t:FlxTimer)
                    {
                        startCutscene();
                    });

                }
            });
        });
    }

    public function startCutscene()
    {
        state = "cutscene";
        parentState.playerDeathsTrigger = false;

        animation.play("laugh");
        FlxG.sound.play(AssetPaths.jevil_laugh01__ogg);
        this.shield.visible = true;
        FlxTween.tween(shield, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});

        new FlxTimer().start(1.0, function(_)
        {
            if (parentState.player != null && parentState.player.exists && parentState.player.alive)
            {
                if (FlxG.sound.music != null) { FlxG.sound.music.stop(); }
                var scythe = new IntroScythe(parentState.player.x -50, parentState.map.y - 100, parentState, 1200);
                FlxG.sound.play(AssetPaths.scythe_intro__ogg, 1, false);
                parentState.dangerObjects.add(scythe);
                parentState.player.active = true;
            }


            new FlxTimer().start(1.0, function(_)
            {
                if (parentState.circusBG.rotationSpeed == 0) parentState.circusBG.rotationSpeed = 80;

                if (parentState.bg != null)
                {
                    FlxTween.tween(parentState.bg, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
                }
                state = "phase1";
                isVulnerable = false;
                if (!battleMusicStarted)
                {
                    battleMusicStarted = true;
                    if (parentState.player != null && parentState.player.exists && parentState.player.alive)
                    {
                        flash.alpha = 0.35;
                        FlxG.sound.play(AssetPaths.start_fight01__ogg, 0.75, false);
                        FlxG.sound.playMusic(AssetPaths.jevil_fight__ogg, 0.95, true);
                        parentState.playerDeathsTrigger = true;
                    }
                }
                parentState.initBossHUD(this);
                startAttack();
            });
        });

    }

    function startAttack()
    {
        if (checkForceTired()) return;
        if (ultimateTriggered || state == "ultimate_barrage"|| state == "ultimate_cutscene" || state == "ultimate_transition" || state == "startCube") return;
        if (hp <= 0) { return; }

        if (!parentState.player.exists && !parentState.player.alive) return;

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

    public function takeDamage(damageAmount:Int, specialDamage:Bool)
    {
        var textColor:FlxColor = (damageAmount >= 2) ? FlxColor.YELLOW : FlxColor.WHITE;
        var dmgTextWidth:Int = 48;
        var dmgTextX:Float = this.x + (this.width + 5 - dmgTextWidth) / 2;
        var dmgTextY:Float = this.y - 22;

        var dmgText:flixel.text.FlxText = new flixel.text.FlxText(dmgTextX, dmgTextY, dmgTextWidth, Std.string(damageAmount), 16);
        dmgText.setFormat("assets/fonts/deltarune.otf", 24, textColor, "center", flixel.text.FlxText.FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
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
            if (!specialDamage) return;
        }

        hp -= damageAmount;



        if (!ultimateUsed && hp <= 50 && hp > 0)
        {
            ultimateUsed = true;
            ultimateTriggered = true;
            startUltimateAttack();
            return;
        }

        if (damageAmount == 2)
        {
            flash.alpha = 0.1;
            FlxG.sound.play(AssetPaths.jevil_confirm__ogg, 0.35, false);
        }

        FlxG.sound.play(AssetPaths.jevil_hit__ogg, 1, false);
        trace("[ HP Remaining: " + hp + " ]");

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
        var bulletCount:Int = 12;
        var interval:Float = 0.2;

        if (hp <= 50) {bulletCount = 15; interval = 0.175; }

        for (i in 0...bulletCount)
        {

            new FlxTimer().start(i * interval, function(_)
            {
                if (parentState.player == null || !parentState.player.exists || !parentState.player.alive) return;
                FlxG.sound.play(AssetPaths.playershoot__ogg, 1, false);
                var angle = flixel.math.FlxAngle.angleBetween(this, parentState.player, true);
                angle += FlxG.random.float(-20, 20);
                var b = new JevilBullet(x, y, "circle", 600, angle, parentState);
                parentState.dangerObjects.add(b);
            });
        }
        new FlxTimer().start(2.5, teleport);
    }

    function attackFan()
    {
        if (checkForceTired()) return;
        if (!parentState.player.exists && !parentState.player.alive) return;

        if (fanComboCount == 0)
        {
            targetFanCombos = FlxG.random.int(2, 4);
        }

        if (this.hp <= 60) targetFanCombos = FlxG.random.int(4, 6);

        var randomX = FlxG.random.float(250, 1000);
        this.x = randomX;

        if (this.x <= 590)
        {
            animation.play("teleportReverse", true, false);
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
        FlxG.sound.play(AssetPaths.scythe_explosion__ogg, 0.5, false);
        this.flash.alpha = 0.2;

        var interval:Float;
        if (hp >= 75) { interval = 1.5; }
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

            new FlxTimer().start(1, function(tmr)
            {
                teleport(tmr);
            });
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
        var randomY:Float = FlxG.random.float(200, 400);
        var goLeft:Bool = false;
        
        if (spadeComboCount == 0 && hp >= 90)
        {
            targetSpadeCombos = FlxG.random.int(4, 6);
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

        if (checkForceTired()) return;
        particlesJevil();

        FlxTween.globalManager.cancelTweensOf(this);
        if (!parentState.player.exists && !parentState.player.alive) return;
        FlxG.sound.play(AssetPaths.jevil_attack01__ogg, 0.75, false);
        FlxG.sound.play(AssetPaths.beep__ogg, 0.5, false);
        
        var cooldownAttack:Float = 0.85;
        if (hp <= 90) { cooldownAttack = 0.65; }

        var bulletSpawnX:Float = x + (width / 2) - 25;
        var bulletSpawnY:Float = y + (height / 2) - 50;

        var baseAngle = flixel.math.FlxAngle.angleBetween(this, parentState.player, true);
        var spreadOffsets:Array<Float> = [-15, -5, 5, 15];
        
        for (offset in spreadOffsets)
        {
            var finalAngle = baseAngle + offset + FlxG.random.float(-3, 3);
            
            var b = new JevilBullet(bulletSpawnX, bulletSpawnY, "spade", 450, finalAngle, parentState);
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
        if (!parentState.player.alive && !parentState.player.exists) return;
        var s = new JevilDiamondScythe(sX, sY, parentState);
        parentState.dangerObjects.add(s);
    }

    function attackJail()
    {
        state = "attacking_jail";
        isVulnerable = false;

        x = 900;
        y = 125;

        particlesJevil();
        
        animation.play("laugh");
        this.flash.alpha = 0.25;
        FlxG.sound.play(AssetPaths.scythe_intro__ogg, 0.5, false);
        FlxG.sound.play(AssetPaths.jevil_laugh01__ogg);
        jailManager.createJail(0);

        var midX:Float = FlxG.width / 2;
        var midY:Float = FlxG.height / 2;
        var cellBottomY:Float = (midY + 50);
        var cellLeftX:Float = (midX - 200) + 10;
        var cellRightX:Float = (midX + 200) - 25;

        new FlxTimer().start(1.0, function(_)
        {
            var totalJewels:Int = 30;
            var spawnInterval:Float = 0.25;
            animation.play("dance");

            new FlxTimer().start(5.5, function(_)
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
                    if (!parentState.player.exists && !parentState.player.alive) return;
                    if (state != "attacking_jail" || !exists) return;

                    var randomX:Float = FlxG.random.float(cellLeftX + 50, cellRightX);
                    var jewel = new main.bosses.ch1.JevilProjectiles.JevilJewel(randomX, cellBottomY, parentState);
                    
                    parentState.dangerObjects.add(jewel);

                    if (i == totalJewels - 1)
                    {
                        if (!parentState.player.exists && !parentState.player.alive) return;
                        animation.play("laugh");
                        FlxG.sound.play(AssetPaths.jevil_laugh02__ogg, 1, false);
                        new FlxTimer().start(1, function(_)
                        {
                            if (!parentState.player.exists && !parentState.player.alive) return;
                            
                            FlxG.sound.play(AssetPaths.jevil_explosion__ogg, 0.75, false);
                            FlxG.camera.shake(0.01, 0.15);

                            var particle = new flixel.effects.particles.FlxEmitter(650, 275);
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
                if (!parentState.player.alive && !parentState.player.exists) return;
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

        var totalBombs:Int = 8;
        var dropInterval:Float = 0.75;

        if (hp <= 50 && hp >= 25) { totalBombs = 12; dropInterval = 0.65;}
        else if (hp < 25) { totalBombs = 14; dropInterval = 0.5; }

        var ceilingY:Float = parentState.map.y + 20;

        for (i in 0...totalBombs)
        {
            
            new FlxTimer().start(i * dropInterval, function(t:FlxTimer)
            {
                if (!parentState.player.alive && !parentState.player.exists) return;
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
                if (!parentState.player.exists && !parentState.player.alive) return;
                if (state != "attacking_hearts" || !exists) return;

                var spawnLeft:Bool = FlxG.random.bool(50);
                var diamondCenterX:Float = spawnLeft ? 200 : 1100;
                var diamondCenterY:Float = FlxG.random.float(350, 600);
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
                FlxTween.cancelTweensOf(this);
                this.flipX = false;
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
        
        state = "startCube";
        isVulnerable = false;
        FlxTween.cancelTweensOf(this);
        this.flipX = false;

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
                var jailDir = new JevilDirectionalAttack(this, parentState);
                jailDir.start();
            });
        });
    }
    
    public function teleport(?_ = null)
    {
        if (ultimateTriggered || state == "ultimate_barrage" || state == "ultimate_cutscene"
            || state == "ultimate_transition" || state == "dead" ) return;

        if (!parentState.player.alive && !parentState.player.exists) return;
        teleportCount++;
        FlxTween.cancelTweensOf(this);
        if (parentState.bossHpBar != null) FlxTween.tween(parentState.bossHpBar, {alpha: 1}, 0.5, { ease: FlxEase.backIn });
        FlxG.sound.play(AssetPaths.jevil_teleport__ogg, 1, false);
        animation.play("teleport", true, false);

        x = 590;
        y = 100;

        particlesJevil();

        new FlxTimer().start(0.2, function(_)
        {
            flipX = !flipX;

            new FlxTimer().start(0.4, function(_)
            {
                flipX = !flipX;
            });
        });

        new FlxTimer().start(1, function(_)
        {
            
            if (teleportCount < 4)
            {
                isVulnerable = false;
                shield.visible = true;
                startAttack();
            }
            else
            {
                if (!parentState.player.alive && !parentState.player.exists) return;
                isVulnerable = true;
                canBeHit = true;
                teleportCount = 0;
                isForcingTired = false;
                animation.play("tired");
                if (shield.visible && shield != null) shield.visible = false;
                FlxG.sound.play(AssetPaths.jevil_tired__ogg, 0.75, false);
                FlxTween.tween(this, { x: 590, y: 350 }, 0.5, { ease: FlxEase.quadOut });

                new FlxTimer().start(0.6, function(_)
                {
                    if (state == "dead") return;
                    if (ultimateTriggered) return;
                    FlxTween.cancelTweensOf(this);
                    FlxTween.tween(this, {y: this.y - 5}, 0.5, {type: PINGPONG, ease: FlxEase.sineInOut});
                });

                new FlxTimer().start(3, function(_)
                {
                    if (state == "dead") return;
                    if (ultimateTriggered) return;
                    FlxTween.cancelTweensOf(this);
                    FlxTween.tween(this, { x: 590, y: 100 }, 0.5, { ease: FlxEase.quadIn });
                });

                new FlxTimer().start(3.5, function(_)
                {
                    if (state == "dead") return;
                    if (ultimateTriggered) return;
                    isVulnerable = false;
                    shield.visible = true;
                    startAttack();
                });


            }
        });
    }

    public function checkForceTired():Bool
    {
        if (forceTiredTurn)
        {
            forceTiredTurn = false;
            isForcingTired = true;
            FlxTween.cancelTweensOf(this);
            teleportCount = 3;
            teleport();
            return true;
        }
        if (isForcingTired) return true; 
        
        return false;
    }

    public function createTrail()
    {
        trail = new FlxTrail(this, null, 20, 2, 0.35, 0.04);
        parentState.add(trail);
        trail.visible = false;
    }

    var deathIdleLoopActive:Bool = false;

    function jevilDeath()
    {
        if (craziness) craziness = false;
        if (parentState.tpBar != null && parentState.tpBar.exists) parentState.tpBar.visible = false;
        if (parentState.tpBarDeco != null && parentState.tpBarDeco.exists) parentState.tpBarDeco.visible = false;
        if (parentState.bossHpBar != null && parentState.bossHpBar.exists)
        {
            parentState.bossHpBar.visible = false;
            parentState.bossHpBar.destroy();
        }

        if (parentState.tpText != null && parentState.tpText.visible) parentState.tpText.visible = false;
        if (parentState.playerDeaths != null && parentState.playerDeaths.visible) parentState.playerDeaths.visible = false;

        if (flash != null) flash.alpha = 0.75;

        parentState.playerDeathsTrigger = true;
        parentState.player.x = 335;
        parentState.player.y = 325;
        parentState.inmortal = true;
        parentState.player.active = false;
        parentState.player.velocity.set(0, 0);
        parentState.player.acceleration.x = 0;

        trailEffect.visible = false;

        if (FlxG.sound.music != null) { FlxG.sound.music.stop(); }

        if (parentState.circusBG.rotationSpeed != 0) parentState.circusBG.rotationSpeed = 0;
        FlxTween.tween(parentState.bg, {alpha: 0}, 0.25, {ease: FlxEase.quadOut});
        FlxTween.cancelTweensOf(this);
        this.shield.visible = false;
        this.shield.destroy();
        this.alpha = 1;
        this.visible = true;

        this.animation.play("teleport", true, false);
        FlxG.sound.play(AssetPaths.jevil_laugh03__ogg, 1, false);

        new FlxTimer().start(3, function(_)
        {
            this.animation.play("idle", true, false);

            FlxTween.tween(this, { x: 900, y: 285 }, 1.0,
            {
                ease: FlxEase.quadInOut,
                onComplete: function(_)
                {
                    startDeathIdleLoop();

                    new FlxTimer().start(1.5, function(_)
                    {
                        startDeathDialogue();
                    });
                }
            });
        });
    }

    function startDeathIdleLoop():Void
    {
        deathIdleLoopActive = true;
        FlxTween.tween(this, { y: this.y - 15 }, 0.75, { type: PINGPONG, ease: FlxEase.sineInOut });
        deathAlphaPulse();
    }

    function deathAlphaPulse():Void
    {
        if (!exists || !deathIdleLoopActive) return;

        FlxTween.tween(this, { alpha: 0 }, 0.65,
        {
            onComplete: function(_)
            {
                if (!exists || !deathIdleLoopActive) return;

                FlxTween.tween(this, { alpha: 1 }, 0.65,
                {
                    onComplete: function(_)
                    {
                        new FlxTimer().start(0.75, function(_)
                        {
                            deathAlphaPulse();
                        });
                    }
                });
            }
        });
    }

    function startDeathDialogue():Void
    {
        FlxG.sound.playMusic(AssetPaths.circus__ogg, 1, true);
        FlxG.sound.music.pitch = 0.8;
        dialogueBox = new main.bosses.ch1.JevilDialogue(parentState);
        parentState.add(dialogueBox);

        var lines:Array<String> =
        [
            "* HA HA HA.\n* WHAT FUN!!!",
            "* YOU'RE FAST, STRONG, AGILE,\n* AGILE.",
            "* BUT THERE ARE YET FASTER, YET\n* STRONGER.",
            "* YOU REMIND ME OF THEM...\n* ANYWAY.",
            "* THE POWER OF THE FIRST PIECE\n* IS DRAWING CLOSER.",
            "* SOON, WITH ITS FULL POWER,\n* AND THANKS TO 'HIM'.",
            "* THIS WORLD WILL BE COVERED IN\n* TOTAL DARKNESS AND DESPAIR.",
            "* KID, CAN YOU STOP IT?",
            "* UEE HEE HEE!",
            "* EITHER WAY, A SURPRISE\n* WAITS FOR YOU JUST\n* AROUND THE CORNER...!",
            "* BRAVE KID!\n* CAN YOU ENDURE THIS\n* FINAL CHAOS?!",
            "* NOTHING CAN SAVE YOU\n* FROM DEATH!!",
            "* BYE-BYE!!\n* UEE HEE HEE!"
        ];

        dialogueBox.say(lines, function()
        {
            if (dialogueBox != null)
            {
                parentState.remove(dialogueBox, true);
                dialogueBox.destroy();
                dialogueBox = null;
            }

            new FlxTimer().start(1, function(_)
            {
                if (FlxG.sound.music != null) { FlxG.sound.music.stop(); }
                FlxG.sound.play(AssetPaths.jevil_attack02__ogg, 1.0, false);
                deathIdleLoopActive = false;
                FlxTween.cancelTweensOf(this);

                ultimateManager.scytheIntro(parentState, 850, 325);

                FlxTween.tween(this, { alpha: 0 }, 1,
                {
                    onComplete: function(_)
                    {
                        new FlxTimer().start(2, function(_)
                        {
                            startFakeEnding();
                        });
                    }
                });
            });
        });
    }

    function startFakeEnding():Void
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

        if (parentState.circusBG.rotationSpeed != 100) parentState.circusBG.rotationSpeed = 100;
        FlxTween.tween(parentState.bg, {alpha: 1}, 0.25, {ease: FlxEase.quadOut});

        whiteFade.makeGraphic(FlxG.width + 50, FlxG.height + 50, FlxColor.WHITE, false);
        whiteFade.screenCenter();
        whiteFade.alpha = 0;
        parentState.add(whiteFade);

        this.visible = false;
        this.alpha = 0;

        jevilEnding.x = 250;
        jevilEnding.y = 300;
        jevilEnding.angle = -5;
        jevilEnding.visible = true;
        FlxTween.tween(jevilEnding, {y: jevilEnding.y - 20}, 0.8, {type: PINGPONG, ease: FlxEase.sineInOut});
        if (FlxG.sound.music != null) { FlxG.sound.music.stop(); }
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
                    parentState.fightingBoss = false;
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

        new FlxTimer().start(2, function(_)
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
            if (parentState != null)
                parentState.remove(trail, true);

            trail.destroy();
            trail = null;
        }

        if (trailEffect != null)
        {
            trailEffect.destroy();
            trailEffect = null;
        }

        super.destroy();
    }



}