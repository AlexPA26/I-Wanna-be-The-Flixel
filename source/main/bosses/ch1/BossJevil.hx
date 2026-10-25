package main.bosses.ch1;

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
    public var tpIncrease:Int = 1;
    public var isVulnerable:Bool = false;
    public var canBeHit:Bool = false;
    public var ultimateTriggered:Bool = false;
    public var ultimateUsed:Bool = false;
    var cubeTriggered:Bool = false;
    var scytheTimeAccumulator:Float = 0;

    var attackTimers:Array<FlxTimer> = [];

    public var pirouetteManager:main.bosses.ch1.JevilPirouetteManager;
    public var forceTiredTurn:Bool = false;
    public var isForcingTired:Bool = false;
    var dialogueBox:main.bosses.ch1.JevilDialogue;
    public var jevilWasHit:Bool = false;
    var jail:FlxSprite;

    
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
    var spamComboCount:Int = 0;
    var lastAttackWasLeft:Bool = false;
    var targetSpadeCombos:Int = 0;
    var targetSpamCombos:Int = 0;
    var activeFakeClones:Array<main.bosses.ch1.JevilClone> = [];

    var jailExploded:Bool = false;

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

        phase01Attacks = [attackSpam];
        phase02Attacks = [attackSpam];
        phase03Attacks = [attackSpam];

        phase01Attacks =
        [
            attackSpades, attackBullets, attackFan, attackHearts, attackSpam, attackBullets, attackFan
        ];

        phase02Attacks =
        [
            attackScythe, attackBombarding, attackJail, attackBullets, attackCircle, attackHearts, attackFan, attackScythe,
            attackBombarding, attackSpam, attackJail, attackBullets, attackCircle
        ];


        phase03Attacks =
        [
            attackBombarding, attackScythe, attackCube, attackBullets, attackBombarding, attackJail, attackHearts,
            attackBombarding, attackCircle, attackSpam, attackScythe, attackBullets, attackBombarding, attackJail,
            attackFan, attackCircle, attackBombarding, attackHearts, attackJail
        ];

    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (!parentState.player.alive && !parentState.player.active && !parentState.player.exists)
        {
            parentState.circusBG.destroy();
        }

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

        #if !mobile
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

        if (FlxG.keys.justPressed.L) { hp -= 20; }

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

        #end

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
            teleportCount = 0;
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
        if (!PlayerData.jevilDialogueRead) parentState.playerDeathsTrigger = true;


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
                "* OH, YOU LOOK WEAK.\n* YOU ARE ALONE?",
                "* UEE HEE HEE!\n* I WILL NOT HOLD BACK,\n* BACK!!",
                "* IT'S GONNA BE FUN!\n* FUN...!!!",
                "* IF YOU DIE, YOU LOSE!",
                "* SIMPLE, RIGHT? RIGHT?!\n* UEE HEE!"
            ];

            dialogueBox.say(lines, function()
            {
                if (dialogueBox != null)
                {
                    parentState.remove(dialogueBox, true);
                    dialogueBox.destroy();
                    dialogueBox = null;

                    var trailEffect = new FlxTrail(this, null, 12, 2, 0.35, 0.03);
                    var jevilIndex = parentState.members.indexOf(this);
                    if (jevilIndex != -1) parentState.insert(jevilIndex, trailEffect);
                    else parentState.add(trailEffect);

                    
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
                    FlxTween.tween(this, { x: this.x + 50, y: this.y - 120 }, 0.5, { ease: FlxEase.quadOut });

                    new FlxTimer().start(1, function(t:FlxTimer)
                    {
                        dialogueBox = new main.bosses.ch1.JevilDialogue(parentState);
                        parentState.add(dialogueBox);

                        var lines:Array<String> =
                        [
                            "* NOW, NOW!!\n* LET THE GAMES BEGIN!!"
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

                                    new FlxTimer().start(0.5, function(t:FlxTimer)
                                    {
                                        startCutscene();
                                    });
                                }
                            });
                        });
                    };
                });
            });
    }

    public function startCutscene()
    {
        state = "cutscene";

        animation.play("laugh");
        FlxG.sound.play(AssetPaths.jevil_laugh01__ogg);
        FlxTween.tween(shield, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});

        new FlxTimer().start(1.0, function(_)
        {
            if (parentState.player != null && parentState.player.exists && parentState.player.alive)
            {
                if (FlxG.sound.music != null) { FlxG.sound.music.stop(); }
                var scythe = new IntroScythe(parentState.player.x -50, parentState.map.y - 100, parentState, 1400);
                FlxG.sound.play(AssetPaths.scythe_intro__ogg, 1, false);
                parentState.dangerObjects.add(scythe);
                parentState.player.active = true;
            }


            new FlxTimer().start(1.0, function(_)
            {
                if (parentState.circusBG.rotationSpeed == 0) FlxTween.tween(parentState.circusBG, {rotationSpeed: 80}, 0.5, {ease: FlxEase.linear});

                if (parentState.bg != null)
                {
                    FlxTween.tween(parentState.bg, {alpha: 1}, 2, {ease: FlxEase.quadOut});
                }
                state = "phase1";
                isVulnerable = false;
                if (!battleMusicStarted)
                {
                    battleMusicStarted = true;
                    if (parentState.player != null && parentState.player.exists && parentState.player.alive)
                    {
                        flash.alpha = 0.35;
                        if (!this.shield.visible) this.shield.visible = true;
                        FlxG.sound.play(AssetPaths.start_fight01__ogg, 0.75, false);
                        FlxG.sound.playMusic(AssetPaths.jevil_fight__ogg, 1, true);
                        parentState.playerDeathsTrigger = false;
                    }
                }
                parentState.initBossHUD(this);
                startAttack();
            });
        });

    }

    function startAttack()
    {
        if (attackInterrupted()) return;
        if (!canAttack()) return;

        if (parentState.player == null || !parentState.player.exists || !parentState.player.alive) return;

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

    function attackSpades()
    {
        var randomY:Float = FlxG.random.float(200, 400);
        var goLeft:Bool = false;
        
        if (spadeComboCount == 0)
        {
            if (hp >= 105)
            {
                targetSpadeCombos = FlxG.random.int(4, 5);
            }
                
            else if (hp >= 80)
            {
                targetSpadeCombos = FlxG.random.int(5, 6);
            }
                
            else
            {
                targetSpadeCombos = FlxG.random.int(6, 8);
            }

        }
        
        if (spadeComboCount == 0)
        {
            goLeft = FlxG.random.bool(50);
        }
        else
        {
            goLeft = !lastAttackWasLeft;
        }

        x = goLeft ? 150 : 900;
        y = randomY;

        if (goLeft)
        {
            animation.play("teleportReverse", true, false);
            FlxG.sound.play(AssetPaths.jevil_teleport__ogg, 0.65, false);
            lastAttackWasLeft = true;
        }
        else
        {
            animation.play("teleport", true, false);
            FlxG.sound.play(AssetPaths.jevil_teleport__ogg, 0.65, false);
            lastAttackWasLeft = false;
        }

        if (attackInterrupted()) return;
        particlesJevil();

        FlxTween.globalManager.cancelTweensOf(this);
        if (parentState.player == null || !parentState.player.exists || !parentState.player.alive) return;
        FlxG.sound.play(AssetPaths.jevil_attack01__ogg, 0.75, false);
        FlxG.sound.play(AssetPaths.beep__ogg, 0.25, false);
        
        var cooldownAttack:Float = 1;
        if (hp >= 80 && hp < 105) { cooldownAttack = 0.9; }
        else if (hp > 0 && hp < 80) { cooldownAttack = 0.85; }
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
            createAttackTimer(0.5, function(_)
            {
                if (attackInterrupted()) return;
                teleport();
            });
        }
        else
        {
            createAttackTimer(cooldownAttack, function(_)
            {
                if (attackInterrupted()) return;

                FlxTween.cancelTweensOf(this);
                attackSpades();
            });
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

        createAttackTimer(1.75, function(_)
        {
            if (isForcingTired) return;
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
            createAttackTimer(i * interval, function(_)
            {
                if (attackInterrupted()) return;
                if (parentState.player == null || !parentState.player.exists || !parentState.player.alive) return;

                FlxG.sound.play(AssetPaths.beep__ogg, 0.65, false);

                var angle = flixel.math.FlxAngle.angleBetween(this, parentState.player, true);
                angle += FlxG.random.float(-20, 20);

                var b = new JevilBullet(x, y, "circle", 600, angle, parentState);
                parentState.dangerObjects.add(b);
            });
        }
        createAttackTimer(2.5, function(_)
        {
            if (attackInterrupted()) return;
            teleport();
        });
    }

    function attackSpam()
    {
        if (spamComboCount == 0)
        {
            if (hp >= 105) { targetSpamCombos = 18; }
            else if (hp >= 80) { targetSpamCombos = 20; }
            else { targetSpamCombos = 24; }

            this.visible = false;
            this.x = 590;
            this.y = -400;
        }

        var goLeft:Bool = (spamComboCount == 0) ? FlxG.random.bool(50) : !lastAttackWasLeft;
        var randomY:Float = FlxG.random.float(100, 450);
        var cloneX:Float = goLeft ? 150 : 900;

        lastAttackWasLeft = goLeft;

        if (attackInterrupted()) return;
        if (parentState.player == null || !parentState.player.exists || !parentState.player.alive) return;

        FlxG.sound.play(AssetPaths.jevil_teleport__ogg, 0.35, false);
        FlxG.sound.play(AssetPaths.jevil_attack01__ogg, 0.75);

        if (!this.visible) this.visible;

        var clone = new main.bosses.ch1.JevilClone(cloneX, randomY, parentState, goLeft);
        parentState.add(clone);
        activeFakeClones.push(clone);

        var jewelSpawnX:Float = cloneX + (clone.width / 2) - 10;
        var jewelSpawnY:Float = randomY + (clone.height / 2) - 16;

        var targetX:Float = parentState.player.x + parentState.player.width / 2;
        var targetY:Float = parentState.player.y + parentState.player.height / 2;

        var jewel = new main.bosses.ch1.JevilProjectiles.JevilJewelSpam(jewelSpawnX, jewelSpawnY, targetX, targetY, parentState);
        parentState.dangerObjects.add(jewel);

        new FlxTimer().start(0.5, function(_)
        {
            if (clone != null && clone.exists)
            {
                clone.squishOutAndDestroy();
            }
            activeFakeClones.remove(clone);
        });

        spamComboCount++;

        if (spamComboCount >= targetSpamCombos)
        {
            spamComboCount = 0;
            targetSpamCombos = 0;

            createAttackTimer(0.75, function(_)
            {
                for (c in activeFakeClones)
                {
                    if (c != null && c.exists)
                    {
                        parentState.remove(c, true);
                        c.destroy();
                    }
                }
                activeFakeClones = [];

                this.visible = true;
                this.x = 590;
                this.y = 335;

                if (attackInterrupted()) return;
                teleport();
            });
        }
        else
        {
            createAttackTimer(0.5, function(_)
            {
                if (attackInterrupted()) return;
                attackSpam();
            });
        }
    }




    function attackFan()
    {
        if (attackInterrupted()) return;
        if (parentState.player == null || !parentState.player.exists || !parentState.player.alive) return;

        if (fanComboCount == 0)
        {
            targetFanCombos = FlxG.random.int(3, 4);
        }

        if (this.hp <= 75) targetFanCombos = FlxG.random.int(5, 6);

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

        createAttackTimer(0.5, function(_)
        {
            if (attackInterrupted()) return;

            animation.stop();
            animation.play("dance");
        });

        FlxG.sound.play(AssetPaths.jevil_laugh03__ogg, 0.75, false);
        FlxG.sound.play(AssetPaths.scythe_explosion__ogg, 0.5, false);
        this.flash.alpha = 0.2;

        var interval:Float;
        if (hp >= 75) { interval = 1.25; }
        else { interval = 1; }

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

            createAttackTimer(1, function(_)
            {
                if (attackInterrupted()) return;
                teleport();
            });
        }
        else
        {
            createAttackTimer(interval, function(_)
            {
                if (attackInterrupted()) return;
                attackFan();
            });
        }
    }

    function attackHearts()
    {
        if (checkForceTired()) return;
        if (attackInterrupted()) return;

        state = "attacking_hearts";
        isVulnerable = false;

        var totalBombs = hp <= 50 ? 36 : 28;
        var travelSpeed = hp <= 50 ? 450 : 400;

        var totalWaves = Std.int(totalBombs / 4);
        var waveInterval = 0.75;
        var orbitAngles = [0, 90, 180, 270];

        for (i in 0...totalWaves)
        {
            createAttackTimer(i * waveInterval, function(_)
            {
                if (attackInterrupted()) return;
                if (state != "attacking_hearts") return;
                if (parentState.player == null || !parentState.player.exists || !parentState.player.alive) return;

                var spawnLeft = FlxG.random.bool(50);
                var diamondCenterX = spawnLeft ? 200 : 1100;
                var diamondCenterY = FlxG.random.float(350, 600);
                var direction = spawnLeft ? 1 : -1;

                FlxTween.cancelTweensOf(this);

                x = diamondCenterX - width / 2;
                y = diamondCenterY - height / 2;

                animation.play(x < FlxG.width / 2 ? "teleportReverse" : "teleport", true);

                particlesJevil();

                FlxG.sound.play(AssetPaths.jevil_attack01__ogg, 0.75);
                FlxG.sound.play(AssetPaths.beep__ogg, 0.5);
                flash.alpha = 0.15;

                for (angleOffset in orbitAngles)
                {
                    var heart = new JevilHeartBomb(diamondCenterX, diamondCenterY, angleOffset, 50, travelSpeed, direction);

                    parentState.dangerObjects.add(heart);
                }

                createAttackTimer(0.5, function(_)
                {
                    if (attackInterrupted()) return;
                    if (state != "attacking_hearts") return;

                    animation.stop();
                    animation.play("dance");
                });

                if (i == totalWaves - 1)
                {
                    createAttackTimer(1.0, function(_)
                    {
                        if (attackInterrupted()) return;
                        teleport();
                    });
                }
            });
        }
    }

    function attackScythe()
    {
        if (checkForceTired()) return;
        if (attackInterrupted()) return;

        animation.play("teleport");

        createAttackTimer(0.5, function(_)
        {
            if (attackInterrupted()) return;

            FlxTween.tween(shield, {alpha: 0}, 0.5, {ease: FlxEase.quadOut});
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


        spawnScythe(px - 25, py - dist);
        spawnScythe(px - 25, py + dist);
        spawnScythe(px - dist, py - 25);
        spawnScythe(px + dist, py - 25);

        
        createAttackTimer(2.5, function(_)
        {
            if (attackInterrupted()) return;

            FlxTween.tween(shield, {alpha: 1}, 0.25, {ease: FlxEase.quadIn});
            FlxTween.tween(this, {alpha: 1}, 0.25, {ease: FlxEase.quadIn});
            alpha = 1;

            teleport();
        });
    }

    function spawnScythe(sX:Float, sY:Float)
    {
        if (attackInterrupted()) return;
        if (parentState.player == null || !parentState.player.exists || !parentState.player.alive) return;
        var s = new JevilDiamondScythe(sX, sY, parentState);
        s.alpha = 0;

        parentState.dangerObjects.add(s);

        FlxTween.tween(s, {alpha: 1}, 0.5,{ ease: FlxEase.quadOut });


    }

    function attackJail()
    {
        jailExploded = false;
        state = "attacking_jail";
        isVulnerable = false;

        x = 900;
        y = 125;

        particlesJevil();
        
        animation.play("laugh");
        this.flash.alpha = 0.25;
        FlxG.sound.play(AssetPaths.scythe_intro__ogg, 0.5, false);
        FlxG.sound.play(AssetPaths.jevil_strong_attack03__ogg, 0.85, false);
        jailManager.createJail(0);

        var midX:Float = FlxG.width / 2;
        var midY:Float = FlxG.height / 2;
        var cellBottomY:Float = (midY + 50);
        var cellLeftX:Float = (midX - 200) + 10;
        var cellRightX:Float = (midX + 200) - 25;

        createAttackTimer(1.0, function(_)
        {
            if (attackInterrupted()) return;
            var totalJewels:Int = 32;
            var spawnInterval:Float = 0.225;
            animation.play("dance");

            createAttackTimer(5.5, function(_)
            {
                if (attackInterrupted()) return;
                animation.play("teleport" , true);
                FlxG.sound.play(AssetPaths.jevil_random_talk01__ogg, 1, false);
            });

            if (hp <= 50 && hp >= 35)
            { 
                totalJewels = 40; spawnInterval = 0.2;
            }
            else if (hp < 25)
            {
                totalJewels = 50; spawnInterval = 0.185;
            }

            for (i in 0...totalJewels)
            {
                createAttackTimer(i * spawnInterval, function(t:FlxTimer)
                {
                    if (attackInterrupted()) return;
                    if (!parentState.player.exists && !parentState.player.alive) return;
                    if (state != "attacking_jail" || !exists) return;

                    var randomX:Float = FlxG.random.float(cellLeftX + 50, cellRightX);
                    var jewel = new main.bosses.ch1.JevilProjectiles.JevilJewel(randomX, cellBottomY, parentState, "black_white");
                    
                    parentState.dangerObjects.add(jewel);

                    if (i == totalJewels - 1)
                    {
                        if (!parentState.player.exists && !parentState.player.alive) return;
                        animation.play("laugh");
                        FlxG.sound.play(AssetPaths.jevil_laugh02__ogg, 1, false);
                        createAttackTimer(1, function(_)
                        {
                            if (attackInterrupted()) return;
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

                            createAttackTimer(3.5, function(_)
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
                            

                            createAttackTimer(0.75, function(_)
                            {
                                if (attackInterrupted()) return;
                                teleport(null);
                            });

                        });
                    }
                });
            }
        });

    }

    function explodeJail():Void
    {
        if (jailExploded) return;
        jailExploded = true;
        FlxG.sound.play(AssetPaths.jevil_explosion__ogg, 0.75);
        FlxG.camera.shake(0.01, 0.15);

        var particle = new flixel.effects.particles.FlxEmitter(650, 275);
        particle.makeParticles(5, 5, FlxColor.WHITE, 150);
        particle.color.set(FlxColor.RED, FlxColor.RED, FlxColor.ORANGE, FlxColor.YELLOW);
        particle.launchMode = CIRCLE;
        particle.speed.set(200, 500);
        particle.lifespan.set(1, 3);

        parentState.add(particle);
        particle.start(true, 0, 150);

        createAttackTimer(3.5, function(_)
        {
            if (parentState != null)
                parentState.remove(particle);

            particle.destroy();
        });

        jailManager.destroyJail();
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
        if (checkForceTired()) return;
        if (attackInterrupted()) return;

        state = "attacking_bombarding";
        isVulnerable = false;

        animation.play("dance");
        FlxG.sound.play(AssetPaths.jevil_strong_attack03__ogg, 0.75);

        var totalBombs:Int = 20;
        var dropInterval:Float = 0.6;

        if (hp <= 50 && hp >= 25)
        {
            totalBombs = 22;
            dropInterval = 0.55;
        }
        else if (hp < 25)
        {
            totalBombs = 24;
            dropInterval = 0.50;
        }

        var ceilingY:Float = parentState.map.y + 20;

        for (i in 0...totalBombs)
        {
            createAttackTimer(i * dropInterval, function(_)
            {
                if (attackInterrupted()) return;
                if (state != "attacking_bombarding" || !exists) return;
                if (parentState.player == null || !parentState.player.exists || !parentState.player.alive) return;

                var randomX:Float = FlxG.random.bool(50) ? 150 : 1150;

                var bomb = new JevilBombardingBomb(randomX, ceilingY, parentState);
                parentState.dangerObjects.add(bomb);

                if (i == totalBombs - 1)
                {
                    createAttackTimer(1.5, function(_)
                    {
                        if (attackInterrupted()) return;
                        teleport();
                    });
                }
            });
        }
    }

    
    // ########################################
    // ########################################
    // ########################################
    // ########################################
    // ########################################


    function startUltimateAttack()
    {
        
        this.visible = true;
        state = "ultimate_cutscene";
        teleportCount = 0;
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

        FlxTween.cancelTweensOf(parentState.player);
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
                tpIncrease = 3;
                main.RoomLoader.loadRoom(parentState, "boss-jevil03");
                parentState.player.canJump = false;
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
            trace("attackCube Early Return");
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

    // ########################################
    // ########################################
    // ########################################
    // ########################################
    
    public function teleport(?_ = null)
    {
        if (state == "dead") return;
        if (ultimateTriggered) return;
        if (state == "ultimate_barrage"|| state == "ultimate_cutscene" || state == "ultimate_transition") return;

        if (!parentState.player.alive && !parentState.player.exists) return;
        teleportCount++;
        FlxTween.cancelTweensOf(this);
        if (parentState.bossHpBar != null) FlxTween.tween(parentState.bossHpBar, {alpha: 1}, 0.5, { ease: FlxEase.backIn });
        FlxG.sound.play(AssetPaths.jevil_teleport__ogg, 1, false);
        animation.play("teleport", true, false);

        x = 590;
        y = 100;

        particlesJevil();

        createAttackTimer(0.2, function(_)
        {
            flipX = !flipX;

            createAttackTimer(0.4, function(_)
            {
                flipX = !flipX;
            });
        });

        createAttackTimer(1, function(_)
        {
            if (state == "dead") return; if (ultimateTriggered) return;

            if (teleportCount < 4)
            {
                isVulnerable = false;
                shield.visible = true;
                startAttack();
            }
            else
            {
            if (parentState.player == null || !parentState.player.exists || !parentState.player.alive) return;

            isVulnerable = true;
            canBeHit = true;
            teleportCount = 0;
            isForcingTired = false;

            animation.play("tired");

            if (shield != null)
                shield.visible = false;

            FlxG.sound.play(AssetPaths.jevil_tired__ogg, 0.75);

            FlxTween.tween(this, {x:590, y:350}, 0.5, {ease:FlxEase.quadOut});

            createAttackTimer(0.6, function(_)
            {
                if (attackInterrupted()) return;

                FlxTween.cancelTweensOf(this);
                FlxTween.tween(this, {y:y - 5}, 0.5,
                {
                    type: PINGPONG,
                    ease: FlxEase.sineInOut
                });
            });

            createAttackTimer(3, function(_)
            {
                if (attackInterrupted()) return;

                FlxTween.cancelTweensOf(this);
                FlxTween.tween(this, {x:590, y:100}, 0.5,
                {
                    ease: FlxEase.quadIn
                });
            });

            createAttackTimer(3.5, function(_)
            {
                if (attackInterrupted()) return;

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

            cancelAttackTimers();

            if (state == "attacking_jail")
            {
                explodeJail();
            }

            FlxTween.cancelTweensOf(this);

            if (shield != null) FlxTween.cancelTweensOf(shield);

            alpha = 1;

            if (shield != null)
            {
                shield.alpha = 1;
                shield.visible = true;
            }

            teleportCount = 3;
            teleport();

            return true;
        }

        return isForcingTired;
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
        if (parentState.player.alive && parentState.player.exists)
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

        if (craziness) craziness = false;
        if (parentState.tpBar != null && parentState.tpBar.exists) parentState.tpBar.visible = false;
        if (parentState.tpBarDeco != null && parentState.tpBarDeco.exists) parentState.tpBarDeco.visible = false;
        if (parentState.bossHpBar != null && parentState.bossHpBar.exists)
        {
            parentState.bossHpBar.visible = false;
            parentState.bossHpBar.destroy();
        }

        if (parentState.tpText != null && parentState.tpText.visible) parentState.tpText.visible = false;
        if (parentState.chapterHUD.playerDeaths != null && parentState.chapterHUD.playerDeaths.visible) 
        parentState.chapterHUD.playerDeaths.visible = false;

        if (flash != null) flash.alpha = 0.75;

        parentState.playerDeathsTrigger = true;
        parentState.player.x = 350;
        parentState.player.y = 350;
        parentState.inmortal = true;
        parentState.player.active = false;
        parentState.player.velocity.set(0, 0);
        parentState.player.acceleration.x = 0;

        jail = new FlxSprite(parentState.player.x, parentState.player.y);
        jail.loadGraphic(AssetPaths.mini_jail__png, false);
        jail.alpha = 0;
        jail.x -= 55;
        jail.y -= 55;
        parentState.add(jail);
        FlxTween.tween(jail, {alpha: 1}, 0.35, {ease: FlxEase.quadOut});
        FlxTween.tween(jail, { y: jail.y + 5 }, 2, { type: PINGPONG, ease: FlxEase.sineInOut });

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
        FlxTween.tween(this, { y: this.y - 15 }, 2, { type: PINGPONG, ease: FlxEase.sineInOut });
        deathAlphaPulse();
    }

    function deathAlphaPulse():Void
    {
        if (!exists || !deathIdleLoopActive) return;

        FlxTween.tween(this, { alpha: 0 }, 0.75,
        {
            onComplete: function(_)
            {
                if (!exists || !deathIdleLoopActive) return;

                FlxTween.tween(this, { alpha: 1 }, 0.75,
                {
                    onComplete: function(_)
                    {
                        new FlxTimer().start(0.6, function(_)
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

        var lines:Array<String> = ["* UEE UEE HEE!\n* PLACEHOLDER TEXT!!"];

        if (jevilWasHit)
        {
            lines =
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
        }

        else if (!jevilWasHit)
        {
            PlayerData.jevilPacifist = true;
            trace("Jevil pacifist! new Skin unlocked!");
            
            lines =
            [
                "* WHAT FUN!!!\n* I'M EXHAUSTED!!!\n* YOU KNOW HOW TO TIRE ME OUT!!",
                "* NOW I WILL CONTINUE MY SLEEP\n* FOR MY REMAINING 92 YEARS.",
                "* SADLY FOR YOU, YOU CAN'T DREAM\n* LIKE I WILL SOON.",
                "* INSTEAD, A NIGHTMARE WILL FALL\n* UPON YOU.",
                "* THE FIRST PIECE OF YOUR GOAL\n* IS WAITING.",
                "* YOU CAN'T SAVE THIS WORLD\n* FROM DISASTER... YET.",
                "* 5 PIECES IN TOTAL!!\n* AND YOU'LL ONLY HAVE ONE!!\n* ONE!!",
                "* BUT... ARE YOU WORTHY,\n* KID?!",
                "* UEE HEE HEE!",
                "* I MAY HAVE EXTRA STRENGTH FOR\n* A LITTLE SURPRISE!!",
                "* IF YOU SURVIVE, MY TREASURE\n* WILL BE YOURS,\n* YOURS...!!",
                "* TAKE IT AND DO YOUR\n* STRONGEST---!",
                "* ARE YOU READY!? UEE HEE HEE\n* MY FINAL CHAOS!!",
                "* BYE-BYE!!"
            ];
        }

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
        jail.alpha = 0;
        var particle = new flixel.effects.particles.FlxEmitter(parentState.player.x, parentState.player.y);
        particle.makeParticles(4, 4, FlxColor.WHITE, 50);
        particle.color.set(FlxColor.ORANGE, FlxColor.RED, FlxColor.RED);
        particle.launchMode = CIRCLE;
        particle.speed.set(150, 350);
        particle.lifespan.set(0.25, 0.5);
        parentState.add(particle);
        particle.start(true, 0, 50);

        FlxG.sound.play(AssetPaths.jevil_explosion__ogg, 0.85, false);

        new FlxTimer().start(0.5, function(_)
        {
            if (parentState != null) parentState.remove(particle);
            if (particle != null) particle.destroy();
        });

        parentState.player.active = true;
        parentState.specialState = true;
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

        
        var particle = new flixel.effects.particles.FlxEmitter(jevilEnding.x + (width / 2), jevilEnding.y + (height / 2));
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

                    FlxG.camera.stopShake;
                    jevilEnding.destroy();
                    parentState.fightingBoss = false;
                    parentState.specialState = false;
                    this.destroy();

                    var currentSeconds = PlayerData.totalSeconds;
                    PlayerData.spawnX = parentState.player.x;
                    PlayerData.spawnY = parentState.player.y - 150;
                    RoomLoader.loadRoom(parentState, "boss-jevil05");
                    PlayerData.currentRoom = "boss-jevil05";
                    PlayerData.totalSeconds = currentSeconds;
                    if (parentState.circusBG.rotationSpeed != 0) parentState.circusBG.rotationSpeed = 0;
                    leveldata.misc.SaveManager.saveGame();
                    parentState.bg.alpha = 1;


                    FlxTween.tween(whiteFade, {alpha: 0}, 3,);
                    
                    
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

    // ########################################


    public function particlesJevil()
    {
        var particle = new flixel.effects.particles.FlxEmitter(x + (width / 2), y + (height / 2));
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

    function createAttackTimer(time:Float, callback:FlxTimer->Void):FlxTimer
    {
        var timer = new FlxTimer();

        attackTimers.push(timer);

        timer.start(time, function(t)
        {
            attackTimers.remove(timer);
            callback(t);
        });

        return timer;
    }

    function cancelAttackTimers():Void
    {
        var timers = attackTimers.copy();

        attackTimers.resize(0);

        for (timer in timers)
        {
            if (timer != null)
                timer.cancel();
        }

    }

    inline function attackInterrupted():Bool
    {
        return checkForceTired()
            || ultimateTriggered
            || state == "ultimate_barrage"
            || state == "ultimate_cutscene"
            || state == "ultimate_transition"
            || state == "startCube"
            || state == "dead";
    }

    inline function canAttack():Bool
    {
        return !attackInterrupted()
            && hp > 0
            && parentState.player != null
            && parentState.player.exists
            && parentState.player.alive;
    }


}
