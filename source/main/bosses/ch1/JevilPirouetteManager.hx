package main.bosses.ch1;

import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.addons.effects.FlxTrail;
import flixel.effects.particles.FlxEmitter;
import main.ChapterState;
import main.bosses.ch1.BossJevil.Jevil;

class JevilPirouetteManager
{
    public var jevil:Jevil;
    public var state:ChapterState;
    public var isPirouetting:Bool = false;
    public var pirouetteTrail:FlxTrail;

    var blackBox:FlxSprite;
    var menuOpen:Bool = false;
    var actButton:FlxSprite;
    var hypnosisText:FlxText;
    var pirouetteText:FlxText;

    var descLine1:FlxText;
    var descLine2:FlxText;
    var descLine3:FlxText;

    var soulSelection:FlxSprite;
    var numberSelection:Int = 1;
    var hintOpenMenu:FlxText;

    var uselessBird:FlxSprite;
    public var invenciblePlayerTimer:Float = 0;
    var flippedCameraTimer:Float = 0;
    

    public function new(jevil:Jevil, state:ChapterState)
    {
        this.jevil = jevil;
        this.state = state;
        
        actButton = new FlxSprite();
        actButton.loadGraphic(AssetPaths.jevil_act_buttom__png, true, 69, 59);
        actButton.animation.add("idle", [0], 1, false);
        actButton.animation.add("active", [0, 1], 6, false);
        actButton.animation.play("idle");
        actButton.x = 50;
        actButton.y = 600;
        actButton.visible = false;
        if (state != null) state.add(actButton);

        hintOpenMenu = new FlxText(actButton.x + 7, actButton.y + 65, actButton.width, "[TAB]");
        hintOpenMenu.setFormat(null, 16, FlxColor.WHITE, "left", flixel.text.FlxText.FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
        hintOpenMenu.visible = false;
        if (state != null) state.add(hintOpenMenu);


    }

    public function update(elapsed:Float)
    {
        
        var isSpecialState = (jevil.state == "waiting" || jevil.state == "ultimate_barrage" || jevil.state == "ultimate_cutscene"
            || jevil.state == "ultimate_transition" || jevil.state == "startCube" || jevil.state == "ultimate_start"
            || jevil.state == "ultimate_return_transition" || jevil.state == "returningCube" || jevil.state == "precutscene"
            || jevil.state == "cutscene" || jevil.state == "dead");

        if (jevil == null || state == null || state.player == null) return;

        if (uselessBird != null && uselessBird.exists)
        {
            if (uselessBird.x >= 1600)
            {
                uselessBird.kill();
                uselessBird.destroy();
            }
        }

        actButton.visible = !(jevil.state == "waiting" || jevil.state == "precutscene" || jevil.state == "cutscene" || jevil.state == "dead");
        actButton.active = !isSpecialState;

        hintOpenMenu.visible = !(jevil.state == "waiting" || jevil.state == "precutscene" || jevil.state == "cutscene" || jevil.state == "dead");
        hintOpenMenu.active = !isSpecialState;

        if (actButton.active && state.currentTP >= 20)
        {
            if (actButton.animation.exists("active"))
            {
                actButton.animation.play("active");
            }
            actButton.alpha = 1.0;
        }
        else
        {
            if (actButton.animation.exists("idle"))
            {
                actButton.animation.play("idle");
            }
            actButton.alpha = 0.65;
        }

        if (FlxG.keys.justPressed.TAB && actButton.active && state.currentTP >= 0)
        {
            if (isSpecialState)
            {
                if (menuOpen) closeMenu();
                return;
            }

            if (!menuOpen) openMenu();
            else closeMenu();
        }


        if (menuOpen)
        {
            if (pirouetteText != null)
                pirouetteText.color = (state.currentTP >= 20) ? FlxColor.WHITE : FlxColor.GRAY;

            if (hypnosisText != null)
                hypnosisText.color = (state.currentTP >= 50) ? FlxColor.WHITE : FlxColor.GRAY;
            // Move UP (1 or Up Arrow or W)
            if ((FlxG.keys.justPressed.ONE) && numberSelection != 1)
            {
                numberSelection = 1;
                FlxG.sound.play(AssetPaths.jevil_select__ogg, 0.25, false);
                updateSoulPosition();
            }

            // Move DOWN (2 or Down Arrow or S)
            if ((FlxG.keys.justPressed.TWO) && numberSelection != 2)
            {
                numberSelection = 2;
                FlxG.sound.play(AssetPaths.jevil_select__ogg, 0.25, false);
                updateSoulPosition();
            }

            // CANCEL (X Key)
            if (FlxG.keys.justPressed.X)
            {
                FlxG.sound.play(AssetPaths.jevil_teleport__ogg, 0.75, false);
                closeMenu();
            }

            if (FlxG.keys.justPressed.Z || FlxG.keys.justPressed.ENTER)
            {
                if (numberSelection == 1)
                {
                    if (state.currentTP >= 20 && !isPirouetting && state.player.alive && state.player.isGrounded && !isSpecialState)
                    {
                        state.currentTP -= 20;
                        if (state.currentTP < 0) state.currentTP = 0;
                        closeMenu();
                        startPirouette();
                    }

                    else
                    {
                        FlxG.sound.play(AssetPaths.error__ogg, 0.65, false);
                    }
                }
                else if (numberSelection == 2)
                {
                    if (state.currentTP >= 50 && !isPirouetting && state.player.alive && state.player.isGrounded && !isSpecialState)
                    {
                        state.currentTP -= 50;
                        if (state.currentTP < 0) state.currentTP = 0;
                        closeMenu();
                        startHypnosis();
                    }
                    else
                    {
                        FlxG.sound.play(AssetPaths.error__ogg, 0.65, false);
                    }
                }
            }
        }

        // ==========================================
        // 3. DIRECT SHORTCUT KEYS (OPTIONAL OVERWORLD SHORTCUTS)
        // ==========================================
        if (!menuOpen)
        {
            if (FlxG.keys.justPressed.S && state.currentTP >= 20 && !isPirouetting && state.player.alive)
            {
                if (state.player.isGrounded && !isSpecialState && jevil.state != "attacking_jail")
                {
                    state.currentTP -= 20;
                    if (state.currentTP <= 0) state.currentTP = 0;
                    startPirouette();
                }
            }

            if (FlxG.keys.justPressed.H && state.currentTP >= 50 && !isPirouetting && state.player.alive)
            {
                if (state.player.isGrounded && !isSpecialState && jevil.state != "attacking_jail")
                {
                    state.currentTP -= 50;
                    if (state.currentTP <= 0) state.currentTP = 0;
                    startHypnosis();
                }
            }
        }

        // ==========================================
        // 4. SPECIAL STATE TIMERS
        // ==========================================
        if (isSpecialState)
        {
            if (invenciblePlayerTimer > 0)
            {
                invenciblePlayerTimer = 0;
                state.inmortal = false;
                state.player.alpha = 1;
                FlxTween.cancelTweensOf(state.player); 
            }
            if (flippedCameraTimer > 0)
            {
                flippedCameraTimer = 0;
                FlxG.sound.play(AssetPaths.jevil_teleport__ogg, 0.75, false);
                FlxTween.tween(FlxG.camera, {angle: 0}, 0.2);
            }
        }
        else
        {
            if (invenciblePlayerTimer > 0)
            {
                invenciblePlayerTimer -= elapsed;
                if (invenciblePlayerTimer <= 0)
                {
                    invenciblePlayerTimer = 0;
                    state.inmortal = false;
                    state.player.alpha = 1;
                }
            }

            if (flippedCameraTimer > 0)
            {
                flippedCameraTimer -= elapsed;
                if (flippedCameraTimer <= 0)
                {
                    flippedCameraTimer = 0;
                    FlxTween.tween(FlxG.camera, {angle: 0}, 0.5);
                }
            }
        }
    }

    function openMenu()
    {
        FlxG.sound.play(AssetPaths.jevil_select__ogg, 0.35, false);
        
        if (blackBox == null)
        {
            blackBox = new FlxSprite();
            blackBox.makeGraphic(425, 150, FlxColor.BLACK, false);
            state.add(blackBox);
        }

        blackBox.alpha = 0.75;
        blackBox.x = actButton.x;
        blackBox.y = actButton.y - 175;
        blackBox.visible = true;

        if (pirouetteText == null)
        {
            pirouetteText = new FlxText(blackBox.x + 60, blackBox.y + 5, blackBox.width, "Pirouette");
            pirouetteText.setFormat("assets/fonts/deltarune.otf", 26, FlxColor.WHITE, "left", flixel.text.FlxText.FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
            if (state != null) state.add(pirouetteText);
        }

        if (hypnosisText == null)
        {
            hypnosisText = new FlxText(blackBox.x + 60, pirouetteText.y + 50, blackBox.width, "Hypnosis");
            hypnosisText.setFormat("assets/fonts/deltarune.otf", 26, FlxColor.WHITE, "left", flixel.text.FlxText.FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
            if (state != null) state.add(hypnosisText);
        }

        pirouetteText.color = (state.currentTP >= 20) ? FlxColor.WHITE : FlxColor.GRAY;
        hypnosisText.color = (state.currentTP >= 50) ? FlxColor.WHITE : FlxColor.GRAY;

        if (soulSelection == null)
        {
            soulSelection = new FlxSprite();
            soulSelection.loadGraphic(AssetPaths.soul__png, true, 20, 16, false);
            soulSelection.animation.add("idle", [0], 0, false);
            soulSelection.animation.play("idle");
            soulSelection.scale.set(1.5, 1.5);
            state.add(soulSelection);
        }
        soulSelection.visible = true;

        if (descLine1 == null)
        {
            descLine1 = new FlxText(blackBox.x + 280, blackBox.y + 5, 0, "");
            descLine1.setFormat("assets/fonts/deltarune.otf", 28, FlxColor.GRAY, "left", flixel.text.FlxText.FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
            if (state != null) state.add(descLine1);
        }

        if (descLine2 == null)
        {
            descLine2 = new FlxText(blackBox.x + 280, descLine1.y + 35, 0, "");
            descLine2.setFormat("assets/fonts/deltarune.otf", 28, FlxColor.GRAY, "left", flixel.text.FlxText.FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
            if (state != null) state.add(descLine2);
        }

        if (descLine3 == null)
        {
            descLine3 = new FlxText(blackBox.x + 280, descLine2.y + 50, 0, "");
            descLine3.setFormat("assets/fonts/deltarune.otf", 28, 0xFFFFA500, "left", flixel.text.FlxText.FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT); // 0xFFFFA500 is Deltarune Orange
            if (state != null) state.add(descLine3);
        }

        numberSelection = 1;
        updateSoulPosition();

        menuOpen = true;
    }

    function closeMenu()
    {
        if (blackBox != null)
        {
            state.remove(blackBox, true);
            blackBox.destroy();
            blackBox = null;
        }

        if (pirouetteText != null)
        {
            state.remove(pirouetteText, true);
            pirouetteText.destroy();
            pirouetteText = null;
        }

        if (hypnosisText != null)
        {
            state.remove(hypnosisText, true);
            hypnosisText.destroy();
            hypnosisText = null;
        }

        if (soulSelection != null)
        {
            state.remove(soulSelection, true);
            soulSelection.destroy();
            soulSelection = null;
        }

        if (descLine1 != null) { state.remove(descLine1, true); descLine1.destroy(); descLine1 = null; }
        if (descLine2 != null) { state.remove(descLine2, true); descLine2.destroy(); descLine2 = null; }
        if (descLine3 != null) { state.remove(descLine3, true); descLine3.destroy(); descLine3 = null; }
            
        menuOpen = false;
    }

    function updateSoulPosition()
    {
        if (soulSelection == null || pirouetteText == null || hypnosisText == null) return;

        if (numberSelection == 1)
        {
            soulSelection.x = pirouetteText.x - 32;
            soulSelection.y = pirouetteText.y + 18;

            if (descLine1 != null) descLine1.text = "Random";
            if (descLine2 != null) descLine2.text = "CHAOS";
            if (descLine3 != null) descLine3.text = "20% TP";
        }
        else if (numberSelection == 2)
        {
            soulSelection.x = hypnosisText.x - 32;
            soulSelection.y = hypnosisText.y + 18;
            if (descLine1 != null) descLine1.text = "Induce";
            if (descLine2 != null) descLine2.text = "TIRED";
            if (descLine3 != null) descLine3.text = "50% TP";
        }
    }

    function startPirouette()
    {
        if (!state.player.exists && !state.player.alive) return;
        isPirouetting = true;
        state.inmortal = true;
        trace("Player inmortal? " + state.inmortal);
        state.player.active = false;
        state.player.velocity.set(0, 0);
        state.player.alpha = 0.75;
        state.player.acceleration.set(0, 0);

        if (pirouetteTrail != null)
        {
            state.remove(pirouetteTrail, true);
            pirouetteTrail.destroy();
            pirouetteTrail = null;
        }

        pirouetteTrail = new FlxTrail(state.player, null, 12, 1, 0.25, 0.05);

        var playerIndex:Int = state.members.indexOf(state.player);
        if (playerIndex != -1) state.insert(playerIndex, pirouetteTrail);
        else state.add(pirouetteTrail);

        FlxG.sound.play(AssetPaths.jevil_pirouette__ogg, 1, false);

        var spinTime = 2 / 6.0; 

        function doSpin(count:Int)
        {
            if (!state.player.exists && !state.player.alive) return;
            if (count >= 6) return;
            var targetScale = (count % 2 == 0) ? -1 : 1;
            FlxTween.tween(state.player.scale, {x: targetScale}, spinTime,
            {
                onComplete: function(_) { doSpin(count + 1); }
            });
        }
        doSpin(0);
        new FlxTimer().start(2, function(_) { endPirouette(); });
    }

    function endPirouette()
    {
        if (pirouetteTrail != null)
        {
            if (state != null) state.remove(pirouetteTrail, true);
            pirouetteTrail.destroy();
            pirouetteTrail = null;
        }

        if (!state.player.exists && !state.player.alive) return;
        state.player.active = true;
        state.player.scale.x = 1;
        isPirouetting = false;

        if (invenciblePlayerTimer <= 0)
        {
            state.inmortal = false;
        }

        state.player.alpha = 1;
        if (jevil.flash != null) jevil.flash.alpha = 0.35;

        var randomEffect = FlxG.random.int(9, 9);
        executeEffect(randomEffect);
    }

    function executeEffect(id:Int)
    {
        switch (id)
        {
            default:
                FlxG.sound.play(AssetPaths.jevil_hypnosis__ogg, 1, false);
                applyDamageAndCheckTired(5, 1);

            case 1:
                FlxG.sound.play(AssetPaths.jevil_hypnosis__ogg, 1, false);
                applyDamageAndCheckTired(10, 1);

            case 2:
                FlxG.sound.play(AssetPaths.jevil_perfect__ogg, 1, false);
                FlxG.sound.play(AssetPaths.jevil_hypnosis__ogg, 0.5, false);
                if (!state.inmortal) state.inmortal = true;
                invenciblePlayerTimer = 10;
                FlxTween.tween(state.player, {alpha: 0.5}, 0.25);
                spawnSaveParticles();
                applyDamageAndCheckTired(20, 999);
                showPopup("A PERFECT 10!", FlxColor.WHITE);

            case 3:
                FlxG.sound.play(AssetPaths.jevil_weird_effect__ogg, 1, false);
                if (!state.inmortal) state.inmortal = true;
                FlxTween.tween(state.player, {alpha: 0.5}, 0.25);
                invenciblePlayerTimer = 7;
                showPopup("ETHEREAL!", FlxColor.WHITE);

            case 4:
                FlxG.sound.play(AssetPaths.jevil_weird_effect__ogg, 1, false);
                FlxG.sound.play(AssetPaths.flip__ogg, 0.5, false);
                FlxTween.tween(FlxG.camera, {angle: 180}, 0.5);
                flippedCameraTimer = 6.0;
                showPopup("CHAOS! CHAOS!", FlxColor.WHITE);

            case 5:
                FlxG.sound.play(AssetPaths.jevil_weird_effect__ogg, 1, false);
                var randomTP = FlxG.random.int(20, 50);
                if (state != null)
                {
                    state.currentTP += randomTP;
                    if (state.currentTP > state.maxTP) state.currentTP = state.maxTP;
                }
                showPopup("MORE CHAOS!", FlxColor.WHITE);

            case 6:
                FlxG.sound.play(AssetPaths.jevil_weird_effect__ogg, 1, false);
                FlxG.sound.play(AssetPaths.trampoline_bounce__ogg, 0.5, false);
                state.player.velocity.y = -1500;
                showPopup("CATCH ME!", FlxColor.WHITE);

            case 7:
                FlxG.sound.play(AssetPaths.jevil_weird_effect__ogg, 1, false);
                FlxG.sound.play(AssetPaths.jevil_laugh03__ogg, 0.5, false);
                state.player.controlsReversed = true;
                showPopup("MOVE! MOVE!", FlxColor.WHITE);

                new FlxTimer().start(10, function(_)
                {
                    state.player.controlsReversed = false;
                });

                var particle = new flixel.effects.particles.FlxEmitter(state.player.x, state.player.y);
                particle.makeParticles(4, 4, FlxColor.WHITE, 50);
                particle.color.set(FlxColor.BLUE, FlxColor.PURPLE, FlxColor.WHITE);
                particle.launchMode = CIRCLE;
                particle.speed.set(150, 350);
                particle.lifespan.set(0.25, 0.5);
                state.add(particle);
                particle.start(true, 0, 50);

                new FlxTimer().start(0.5, function(_)
                {
                    if (state != null) state.remove(particle);
                    if (particle != null) particle.destroy();
                });

            case 8:
                var randomY = FlxG.random.int(200, 400);
                FlxG.sound.play(AssetPaths.jevil_useless_bird__ogg, 0.75, false);
                uselessBird = new FlxSprite();
                uselessBird.loadGraphic(AssetPaths.jevil_useless_bird__png, true, 40, 40, false);
                uselessBird.animation.add("flap", [0, 1, 2], 8, true);
                uselessBird.animation.play("flap");
                uselessBird.x = -100;
                uselessBird.y = randomY;
                uselessBird.velocity.x = 300;
                FlxTween.tween(uselessBird, {y: uselessBird.y - 35}, 0.8, {type: PINGPONG, ease: FlxEase.sineInOut});
                state.add(uselessBird);

            case 9:
                FlxG.sound.play(AssetPaths.jevil_weird_effect__ogg, 1, false);
                FlxG.sound.play(AssetPaths.scythe_intro__ogg, 0.5, false);
                FlxG.camera.shake(0.02, 0.15);
                showPopup("SURPRISE!", FlxColor.WHITE);
                var scythe = new main.bosses.ch1.JevilProjectiles.IntroScythe(state.player.x -50, state.map.y - 100, state, 1000);
                state.dangerObjects.add(scythe);
        }

        if (jevil.hp <= 0 && jevil.state != "dead")
        {
            jevil.state = "dead";
            Reflect.callMethod(jevil, Reflect.field(jevil, "jevilDeath"), []);
        }
        else if (jevil.hp <= 50 && !jevil.ultimateTriggered && !jevil.ultimateUsed)
        {
            jevil.ultimateTriggered = true;
            Reflect.callMethod(jevil, Reflect.field(jevil, "startUltimateAttack"), []);
        }
    }

    function showPopup(text:String, color:FlxColor = FlxColor.WHITE)
    {
        var popup = new FlxText(0, 0, 0, text, 20);
        popup.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        popup.color = color;

        popup.x = state.player.x + (state.player.width / 2) - (popup.width / 2);
        popup.y = state.player.y - 30;

        state.popups.add(popup);

        FlxTween.num(0, 60, 0.8,
        {
            ease: FlxEase.circOut,
            onComplete: function(_)
            {
                popup.destroy();
            }
        },
        function(v:Float)
        {
            if (popup != null && popup.exists && state.player != null && state.player.exists)
            {
                popup.alpha = 1 - (v / 60);

                popup.x = state.player.x + (state.player.width / 2) - (popup.width / 2);
                popup.y = state.player.y - 30 - v;
            }
        });
    }

    function applyDamageAndCheckTired(damage:Int, teleportReduction:Int)
    {
        jevil.hp -= damage;

        if (teleportReduction == 999) 
        {
            Reflect.setProperty(jevil, "teleportCount", 0);
            jevil.forceTiredTurn = true;
        }
        else 
        {
            var currentTP:Int = Reflect.getProperty(jevil, "teleportCount");
            currentTP -= teleportReduction;
            
            if (currentTP <= 0) 
            {
                Reflect.setProperty(jevil, "teleportCount", 0);
                jevil.forceTiredTurn = true;
            }
            else 
            {
                Reflect.setProperty(jevil, "teleportCount", currentTP);
            }
        }
    }

    function spawnSaveParticles()
    {
        var particle = new FlxEmitter(state.player.x + (state.player.width / 2), state.player.y + (state.player.height / 2), 40);
        particle.makeParticles(4, 4, FlxColor.WHITE, 40);
        particle.color.set(FlxColor.RED, FlxColor.YELLOW, FlxColor.BLUE, FlxColor.LIME);
        particle.lifespan.set(0.5, 1.2);
        particle.speed.set(100, 400);
        particle.launchMode = CIRCLE;
        particle.acceleration.set(0, 500); 
        particle.drag.set(100, 100);
        particle.angularVelocity.set(-300, 300);

        state.add(particle);
        particle.start(true, 0, 30);

        new FlxTimer().start(1.5, function(_) { particle.destroy(); });
    }

    function startHypnosis()
    {
        FlxG.sound.play(AssetPaths.jevil_hypnosis__ogg, 1, false);
        applyDamageAndCheckTired(20, 999);
        jevil.flash.alpha = 0.35;

        var jevilCenterX:Float = jevil.x + (jevil.width / 2);
        var jevilCenterY:Float = jevil.y + (jevil.height / 2);

        var scales:Array<Float> = [4, 3.25, 2.5];
        var startAngles:Array<Float> = [60, 120, 180];
        var rotationAmounts:Array<Float> = [-360, -360, -360];
        var orbitRadius:Float = 45;

        for (i in 0...scales.length)
        {
            var ring = new FlxSprite();
            ring.loadGraphic(AssetPaths.jevil_hypnosis__png, false);
            ring.scale.set(scales[i], scales[i]);
            ring.updateHitbox();

            ring.alpha = 0.75;
            ring.blend = flash.display.BlendMode.ADD;
            
            state.add(ring);

            var startAngle = startAngles[i];
            var rotationAmount = rotationAmounts[i];

            var initRad:Float = startAngle * Math.PI / 180;
            ring.x = jevilCenterX + (Math.cos(initRad) * orbitRadius) - (ring.width / 2);
            ring.y = jevilCenterY + (Math.sin(initRad) * orbitRadius) - (ring.height / 2);

            FlxTween.num(0, rotationAmount, 1.0,
            {
                onComplete: function(_)
                {
                    ring.kill();
                    state.remove(ring, true);
                    ring.destroy();
                }
            },
            function(v:Float)
            {
                if (ring != null && ring.exists)
                {
                    var rad:Float = (startAngle + v) * Math.PI / 180;
                    ring.x = jevilCenterX + (Math.cos(rad) * orbitRadius) - (ring.width / 2);
                    ring.y = jevilCenterY + (Math.sin(rad) * orbitRadius) - (ring.height / 2);
                    ring.angle = v;
                }
            });

            FlxTween.tween(ring, {alpha: 0}, 1.0, { ease: FlxEase.quadOut });
        }
    }
}