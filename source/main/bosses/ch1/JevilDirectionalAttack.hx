package main.bosses.ch1;

import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.math.FlxVelocity;
import flixel.math.FlxPoint;
import main.ChapterState;
import main.bosses.ch1.BossJevil.Jevil;


class JevilDirectionalAttack extends FlxBasic
{
    static inline var BOX_SIZE:Float = 250;
    static inline var BOX_CENTER_X:Float = 635;
    static inline var BOX_CENTER_Y:Float = 300;
    static inline var MAX_SOUL_HP:Float = 95;
    static inline var DAMAGE_PER_HIT:Float = 28;
    static inline var HIT_COOLDOWN:Float = 1.5;
    static inline var SOUL_SPEED:Float = 220;

    var jevil:Jevil;
    var parentState:ChapterState;
    var blackBox = new FlxSprite();
    var soul:FlxSprite;
    var box:FlxSprite;
    var hpBarFill:FlxSprite;
    var hpBarBG:FlxSprite;
    var hpText:FlxText;

    var soulHP:Float = MAX_SOUL_HP;
    var soulInvulnerable:Bool = false;
    var inputEnabled:Bool = false;
    var isDead:Bool = false;
    var isEnding:Bool = false;

    var attackCounter:Int = 0;
    var targetAttacks:Int = 0;
    var lastAttackWasLeft:Bool = false;

    var returnX:Float;
    var returnY:Float;

    var activeTimers:Array<FlxTimer> = [];

    public function new(jevil:Jevil, parentState:ChapterState)
    {
        super();
        this.jevil = jevil;
        this.parentState = parentState;
    }

    public function start():Void
    {
        parentState.add(this);
        returnX = parentState.player.x;
        returnY = parentState.player.y;

        jevil.visible = false;
        parentState.player.visible = false;
        parentState.player.active = false;
        parentState.player.velocity.set(0, 0);
        FlxG.sound.play(AssetPaths.beep__ogg, 1, false);

        var dangerIdx:Int = parentState.members.indexOf(parentState.dangerObjects);
        if (dangerIdx == -1) dangerIdx = parentState.members.length;
        parentState.remove(jevil.blackFade, true);
        parentState.insert(dangerIdx, jevil.blackFade);

        blackBox = new FlxSprite();
        blackBox.makeGraphic(Std.int(BOX_SIZE), Std.int(BOX_SIZE), FlxColor.BLACK, true);
        blackBox.setPosition(BOX_CENTER_X - BOX_SIZE / 2, BOX_CENTER_Y - BOX_SIZE / 2);
        blackBox.scale.set(0.05, 0.05);
        blackBox.alpha = 1;
        parentState.insert(dangerIdx + 1, blackBox);

        box = new FlxSprite();
        box.makeGraphic(Std.int(BOX_SIZE), Std.int(BOX_SIZE), FlxColor.TRANSPARENT, true);
        FlxSpriteUtil.drawRect(box, 0, 0, BOX_SIZE, BOX_SIZE, FlxColor.TRANSPARENT, { thickness: 12, color: FlxColor.GREEN });
        box.setPosition(BOX_CENTER_X - BOX_SIZE / 2, BOX_CENTER_Y - BOX_SIZE / 2);
        box.scale.set(0.05, 0.05);
        parentState.insert(dangerIdx + 2, box);

        parentState.remove(jevil, true);
        parentState.insert(dangerIdx + 3, jevil);

        soul = new FlxSprite(returnX, returnY);
        soul.loadGraphic(AssetPaths.soul__png, true, 20, 16);
        soul.animation.add("idle", [0], 0, false);
        soul.animation.play("idle");
        soul.scale.set(1.5, 1.5);
        soul.updateHitbox();
        soul.alpha = 0;
        parentState.add(soul);

        FlxTween.tween(soul, { alpha: 1 }, 0.15);
        FlxTween.tween(soul, { x: BOX_CENTER_X - soul.width / 2, y: BOX_CENTER_Y - soul.height / 2 }, 0.5,
        {
            ease: FlxEase.quadOut
        });

        FlxTween.tween(box.scale, { x: 1, y: 1 }, 0.5, { ease: FlxEase.quadOut });
        FlxTween.tween(box, { angle: 360 }, 0.5, { });

        FlxTween.tween(blackBox.scale, { x: 1, y: 1 }, 0.5, { ease: FlxEase.quadOut });
        FlxTween.tween(blackBox, { angle: 360 }, 0.5, { });
        
        mkTimer(0.5, function(_)
        {
            createHUD();
            inputEnabled = true;

            parentState.dangerObjects.forEach(function(obj:flixel.FlxBasic)
            {
                if (obj != null && !Std.isOfType(obj, JevilDirectionalJewel))
                {
                    var sprite = cast(obj, FlxSprite);
                    if (sprite != null)
                    {
                        sprite.visible = false;
                    }
                }
            });

            mkTimer(0.5, function(_)
            {
                targetAttacks = FlxG.random.int(16, 20);
                attackCounter = 0;
                runAttackCycle();
            });
        });
    }

    function createHUD():Void
    {
        var barWidth:Int = 135;
        var barHeight:Int = 15;
        var barX:Int = 355;
        var barY:Int = 520;

        hpBarBG = new FlxSprite(barX, barY);
        hpBarBG.makeGraphic(barWidth, barHeight, FlxColor.RED);
        hpBarBG.alpha = 0;
        parentState.add(hpBarBG);

        hpBarFill = new FlxSprite(barX, barY);
        hpBarFill.makeGraphic(barWidth, barHeight, 0xff0095e8);
        hpBarFill.origin.set(0, hpBarFill.height / 2);
        hpBarFill.alpha = 0;
        parentState.add(hpBarFill);

        FlxTween.tween(jevil.playerHUD, {alpha: 1}, 1);
        FlxTween.tween(hpBarFill, {alpha: 1}, 1);

        new FlxTimer().start(1, function(_)
        {
            hpBarBG.alpha = 1;
        });

        hpText = new FlxText(barX + 17, barY - 35, barWidth, soulHPLabel(), 24);
        hpText.setFormat("assets/fonts/deltarune.otf", 20, FlxColor.WHITE, "center", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        parentState.add(hpText);

        updateHUD();
    }

    inline function soulHPLabel():String
    {
        return Std.int(Math.max(soulHP, 0)) + " /  " + Std.int(MAX_SOUL_HP);
    }

    function updateHUD():Void
    {
        if (hpBarFill == null || hpText == null) return;

        var pct:Float = Math.max(soulHP, 0) / MAX_SOUL_HP;
        hpBarFill.scale.x = pct;
        hpText.text = soulHPLabel();
    }

    function runAttackCycle():Void
    {
        if (isDead || isEnding) return;

        if (attackCounter >= targetAttacks)
        {
            endSequence();
            return;
        }

        fireVolley();
        attackCounter++;

        mkTimer(0.75, function(_)
        {
            runAttackCycle();
        });
    }

    function fireVolley():Void
    {
        if (isDead) return;

        var goLeft:Bool = (attackCounter == 0) ? FlxG.random.bool(50) : !lastAttackWasLeft;
        lastAttackWasLeft = goLeft;

        var spawnX:Float = goLeft ? 300 : 850;
        var spawnY:Float = FlxG.random.float(100, 300);

        jevil.visible = true;
        jevil.setPosition(spawnX, spawnY);
        jevil.updateHitbox();
        jevil.animation.play(goLeft ? "teleportReverse" : "teleport", true, false);
        FlxG.sound.play(AssetPaths.jevil_teleport__ogg, 1, false);
        jevil.particlesJevil();

        FlxTween.cancelTweensOf(jevil);
        FlxTween.tween(jevil, {y: jevil.y - 10}, 0.5, {type: PINGPONG, ease: FlxEase.sineInOut});

        var offsets:Array<Float> = [-60, -30, 0, 30, 60];
        var targetX:Float = soul.x + soul.width / 2;
        var targetY:Float = soul.y + soul.height / 2;

        for (offset in offsets)
        {
            var jewel = new JevilDirectionalJewel(spawnX, spawnY, targetX, targetY + offset);
            parentState.dangerObjects.add(jewel);
        }

        mkTimer(0.5, function(_)
        {
            FlxTween.cancelTweensOf(jevil);
            if (jevil.exists) jevil.visible = false;
        });
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (isDead || soul == null) return;

        if (inputEnabled)
        {
            handleSoulMovement(elapsed);
        }

        checkJewelHits();
    }

    function handleSoulMovement(elapsed:Float):Void
    {
        var vx:Float = 0;
        var vy:Float = 0;

        if (FlxG.keys.anyPressed(["LEFT", "A"])) vx -= SOUL_SPEED;
        if (FlxG.keys.anyPressed(["RIGHT", "D"])) vx += SOUL_SPEED;
        if (FlxG.keys.anyPressed(["UP", "W"])) vy -= SOUL_SPEED;
        if (FlxG.keys.anyPressed(["DOWN", "S"])) vy += SOUL_SPEED;

        soul.x += vx * elapsed;
        soul.y += vy * elapsed;

        var minX:Float = BOX_CENTER_X - BOX_SIZE / 2 + 4;
        var maxX:Float = BOX_CENTER_X + BOX_SIZE / 2 - soul.width - 4;
        var minY:Float = BOX_CENTER_Y - BOX_SIZE / 2 + 4;
        var maxY:Float = BOX_CENTER_Y + BOX_SIZE / 2 - soul.height - 4;

        if (soul.x < minX) soul.x = minX;
        if (soul.x > maxX) soul.x = maxX;
        if (soul.y < minY) soul.y = minY;
        if (soul.y > maxY) soul.y = maxY;
    }

    function checkJewelHits():Void
    {
        if (soulInvulnerable) return;

        parentState.dangerObjects.forEachOfType(JevilDirectionalJewel, function(jewel:JevilDirectionalJewel)
        {
            if (soulInvulnerable || isDead) return;

            if (jewel.exists && jewel.overlaps(soul))
            {
                jewel.destroy();
                onSoulHit();
            }
        });
    }

    function onSoulHit():Void
    {
        FlxG.sound.play(AssetPaths.jevil_hit__ogg, 1, false);

        soulHP -= DAMAGE_PER_HIT;
        updateHUD();
        showDamageText();
        FlxG.camera.shake(0.01, 0.15);

        if (soulHP <= 0)
        {
            killSoulSafely();
            return;
        }

        soulInvulnerable = true;
        soul.alpha = 0.65;

        mkTimer(HIT_COOLDOWN, function(_)
        {
            if (isDead) return;
            soulInvulnerable = false;
            soul.alpha = 1;
        });
    }

    function showDamageText():Void
    {
        var dmgTextWidth:Int = 24;
        var dmgTextX:Float = soul.x + (soul.width - 10 - dmgTextWidth) / 2;
        var dmgTextY:Float = soul.y - 22;

        var dmgText:FlxText = new FlxText(dmgTextX, dmgTextY, dmgTextWidth + 50, Std.int(DAMAGE_PER_HIT) + "", 16);
        dmgText.setFormat("assets/fonts/deltarune.otf", 24, FlxColor.RED, "center", flixel.text.FlxText.FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        parentState.add(dmgText);

        FlxTween.tween(dmgText, { y: dmgTextY - 10 }, 0.18, { ease: FlxEase.quadOut, onComplete: function(_)
        {
            FlxTween.tween(dmgText, { y: dmgTextY - 6 }, 0.12, { ease: FlxEase.quadIn });
        }});

        mkTimer(0.75, function(_)
        {
            dmgText.kill();
            dmgText.destroy();
        });
    }

    function killSoulSafely():Void
    {
        if (isDead) return;
        isDead = true;

        for (t in activeTimers)
        {
            if (t != null)
            {
                t.cancel();
                t.destroy();
            }
        }
        activeTimers = [];

        if (parentState.player != null)
        {
            parentState.player.x = soul.x;
            parentState.player.y = soul.y;
            parentState.killPlayer();
        }
    }

    function endSequence():Void
    {
        if (isEnding || isDead) return;
        isEnding = true;
        jevil.state = "returningCube";
        jevil.visible = true;
        jevil.x = 590;
        jevil.y = 50;
        jevil.animation.play("laugh");
        FlxG.sound.play(AssetPaths.jevil_laugh01__ogg, 0.85, false);

        mkTimer(1.0, function(_)
        {
            FlxTween.tween(jevil.blackFade, {alpha: 0}, 1, { ease: FlxEase.backIn });
            FlxTween.tween(blackBox, {alpha: 0}, 0.5, { onComplete: function(_) { blackBox.destroy(); }});
            FlxTween.tween(box, { alpha: 0 }, 0.5, { onComplete: function(_) { box.destroy(); }});
            FlxTween.tween(jevil.playerHUD, { alpha: 0 }, 0.5, { onComplete: function(_) { box.destroy(); }});

            if (hpBarBG != null) hpBarBG.destroy();
            if (hpBarFill != null) hpBarFill.destroy();
            if (hpText != null) hpText.destroy();

            FlxTween.tween(soul, { x: returnX, y: returnY }, 0.5,
            {
                ease: FlxEase.quadInOut,
                onComplete: function(_)
                {
                    PlayerData.currentSkin = Jevil.playerSkin;
                    soul.destroy();
                    jevil.playerHUD.visible = false;
                    jevil.playerHUD.destroy();

                    jevil.flash.alpha = 1;

                    parentState.player.visible = true;
                    parentState.player.active = true;

                    parentState.dangerObjects.forEach(function(obj:flixel.FlxBasic)
                    {
                        if (obj != null)
                        {
                            var sprite = cast(obj, FlxSprite);
                            if (sprite != null)
                            {
                                sprite.visible = true;
                            }
                        }
                    });

                    if (parentState.currentBoss != null && parentState.currentBoss != jevil)
                    {
                        var stray = parentState.currentBoss;
                        parentState.remove(stray, true);
                        stray.destroy();
                    }

                    parentState.currentBoss = jevil;
                    jevil.teleport();
                    parentState.remove(this);
                    FlxTween.tween(jevil.shield, {alpha: 1}, 1, { ease: FlxEase.backIn });
                    this.destroy();
                }
            });
        });
    }

    function mkTimer(delay:Float, cb:FlxTimer->Void):FlxTimer
    {
        var t:FlxTimer = new FlxTimer();
        activeTimers.push(t);
        t.start(delay, cb);
        return t;
    }

    override public function destroy():Void
    {
        for (t in activeTimers)
        {
            if (t != null)
            {
                t.cancel();
                t.destroy();
            }
        }
        activeTimers = [];

        super.destroy();
    }
}


class JevilDirectionalJewel extends FlxSprite
{
    static inline var SPEED:Float = 380;

    public function new(x:Float, y:Float, targetX:Float, targetY:Float)
    {
        super(x, y);

        FlxG.sound.play(AssetPaths.jevil_attack01__ogg, 0.4, false);
        loadGraphic(AssetPaths.jewel__png, true, 19, 33);
        animation.add("idle", [0], 1, false);
        animation.play("idle");
        updateHitbox();

        FlxVelocity.moveTowardsPoint(this, FlxPoint.get(targetX, targetY), SPEED);
    }

    override public function update(elapsed:Float):Void
    {
        if (velocity.x != 0 || velocity.y != 0)
        {
            angle = Math.atan2(velocity.y, velocity.x) * 180 / Math.PI;
        }

        super.update(elapsed);



        if (!isOnScreen())
        {
            destroy();
        }
    }
}
