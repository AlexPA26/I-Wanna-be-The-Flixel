package main.bosses.ch1;

import flixel.tweens.FlxEase;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import main.bosses.ch1.BossJevil.Jevil;
import flixel.FlxG;
import flixel.util.FlxTimer;
import haxe.Json;
import openfl.utils.Assets;
import main.PlayerData;
import main.ChapterState;

class JevilUltimateState
{
    private var boss:Jevil;
    private var fakeoutScythe:main.bosses.ch1.JevilProjectiles.JevilUltimateScythe;
    private var whiteFade:FlxSprite;
    var soul:FlxSprite = new FlxSprite();
    var parentState:ChapterState;
    var blackFade = new FlxSprite();

    var activeTimers:Array<FlxTimer> = [];

    public function new(bossInstance:Jevil)
    {
        this.boss = bossInstance;
    }

    function mkTimer(delay:Float, cb:FlxTimer->Void, loops:Int = 1):FlxTimer
    {
        var t:FlxTimer = new FlxTimer();
        activeTimers.push(t);
        t.start(delay, cb, loops);
        return t;
    }

    public function scytheIntro(state:ChapterState, offsetX:Int, offsetY:Int):Void
    {
        parentState = state;
        mkTimer(0, function(t:FlxTimer)
        {
            if (!parentState.player.alive && !parentState.player.exists) return;
            var cutsceneScythe = new FlxSprite();
            cutsceneScythe.loadGraphic(AssetPaths.jevil_scythe__png, false);
            cutsceneScythe.screenCenter();
            cutsceneScythe.x = offsetX;
            cutsceneScythe.y = offsetY;
            cutsceneScythe.scale.set(4.5, 0.2);
            cutsceneScythe.updateHitbox();
            parentState.add(cutsceneScythe);

            FlxTween.tween(cutsceneScythe.scale, { x: 2.3, y: 2.3 }, 0.75,
            {
                ease: FlxEase.elasticOut,
                onComplete: function(_)
                {
                    cutsceneScythe.updateHitbox(); 
                    cutsceneScythe.y -= 50;
                    cutsceneScythe.x += 50;

                    FlxTween.tween(cutsceneScythe.scale, { x: -2.3 }, 0.4,
                    {
                        ease: FlxEase.quadInOut,
                        onComplete: function(_)
                        {
                            mkTimer(0, function(_)
                            {
                                cutsceneScythe.velocity.y = -1400; 
                                FlxTween.tween(blackFade, {alpha: 0}, 0.5, { ease: FlxEase.backIn });

                                var checkOffscreenTimer:FlxTimer;
                                checkOffscreenTimer = mkTimer(0.05, function(timer:FlxTimer)
                                {
                                    if (cutsceneScythe.y < -300)
                                    {
                                        if (!parentState.player.alive && !parentState.player.exists) return;
                                        cutsceneScythe.kill();
                                        cutsceneScythe.destroy();
                                        parentState.remove(cutsceneScythe, true);
                                        timer.destroy(); 
                                        
                                    }
                                }, 0); 
                            });
                        }
                    });
                }
            });
        });
    }

    public function initBarrage(state:ChapterState):Void
    {
        parentState = state;

        mkTimer(1, function(t:FlxTimer)
        {
            blackFade.makeGraphic(FlxG.width, FlxG.height, flixel.util.FlxColor.BLACK);
            blackFade.scrollFactor.set();
            blackFade.alpha = 0;
            parentState.insert(5, blackFade);

            FlxTween.tween(blackFade, {alpha: 1}, 1, { ease: FlxEase.backIn });

        });

    }
    public function executeBarrage(state:ChapterState):Void
    {
        parentState = state;
        blackFade.visible = false;

        try
        {
            var jsonString:String = Assets.getText("assets/data/bosses/jevil/jevil_ultimate.json");
            var scytheData:Array<Dynamic> = Json.parse(jsonString);

            var accumulatedDelay:Float = 0.0;

            for (i in 0...scytheData.length)
            {
                var dataNode = scytheData[i];
                accumulatedDelay += dataNode.delay;

                mkTimer(accumulatedDelay, function(t:FlxTimer)
                {
                    if (boss.state != "ultimate_barrage" || !boss.exists) return;
                    if (parentState.player == null || !parentState.player.exists || !parentState.player.alive) return;

                    var spawnX:Float = dataNode.x;
                    var scythe = new main.bosses.ch1.JevilProjectiles.JevilUltimateScythe(spawnX, -150, state);
                    state.dangerObjects.add(scythe);
                });
            }
        }
        catch (e:Dynamic)
        {
            trace("Error parsing jevil_ultimate.json timeline profile: " + e);
        }

        mkTimer(10.0, function(t:FlxTimer)
        {
            if (boss.state != "ultimate_barrage" || !boss.exists) return;
            if (parentState.player == null || !parentState.player.exists || !parentState.player.alive) return;
            triggerMidAttackEvent(state);
        });

        mkTimer(14.0, function(t:FlxTimer)
        {
            if (boss.state != "ultimate_barrage" || !boss.exists) return;
            if (parentState.player == null || !parentState.player.exists || !parentState.player.alive) return;

            var finalSound = FlxG.sound.play(AssetPaths.jevil_final_strike__ogg, 0.75, false);
            
            fakeoutScythe = new main.bosses.ch1.JevilProjectiles.JevilUltimateScythe(0, 0, state);
            fakeoutScythe.scale.set(25, 25);
            fakeoutScythe.updateHitbox();
            fakeoutScythe.angle = 195;
            fakeoutScythe.velocity.y = 80;
            fakeoutScythe.x -= 100;
            fakeoutScythe.y -= 1000;
            fakeoutScythe.angularVelocity = 0;
            state.dangerObjects.add(fakeoutScythe);
            
            var baseX = fakeoutScythe.x;
            {
                var trail = Reflect.field(fakeoutScythe, "trail");
                if (trail != null)
                {
                    trail.visible = false;
                }
            }

            FlxTween.num(-8, 8, 0.02, { type: PINGPONG }, function(offset:Float)
            {
                if (fakeoutScythe != null && fakeoutScythe.exists)
                {
                    fakeoutScythe.x = baseX + offset;
                }
            });
            
            whiteFade = new FlxSprite();
            whiteFade.makeGraphic(FlxG.width, FlxG.height, flixel.util.FlxColor.WHITE);
            whiteFade.scrollFactor.set();
            whiteFade.alpha = 0;
            state.add(whiteFade);
            FlxTween.tween(whiteFade, {alpha: 1}, 5);

            mkTimer(6.0, function(_)
            {
                if (fakeoutScythe != null && fakeoutScythe.exists)
                {
                    fakeoutScythe.kill();
                    fakeoutScythe.exists = false;
                    try
                    {
                        if (state != null && state.dangerObjects != null)
                        {
                            state.dangerObjects.remove(fakeoutScythe, true);
                        }
                    }
                    catch (e:Dynamic) {}
                    fakeoutScythe = null;
                }

                if (finalSound != null)
                {
                    finalSound.stop();
                }
                
                boss.ultimateUsed = true;
                teleportBack();
                FlxTween.tween(whiteFade, {alpha: 0}, 1.5,
                {
                    onComplete: function(_)
                    {
                        try
                        {
                            if (whiteFade != null)
                            {
                                whiteFade.kill();
                                whiteFade.exists = false;
                                if (state != null)
                                {
                                    state.remove(whiteFade, true);
                                }
                                whiteFade = null;
                            }
                        }
                        catch (e:Dynamic) {}
                    }
                });
            });
        });
    }


    private function triggerMidAttackEvent(state:ChapterState):Void
    {
        FlxG.sound.play(AssetPaths.jevil_teleport__ogg, 1, false);

        var jevilCutscene = new FlxSprite();
        jevilCutscene.frames = FlxAtlasFrames.fromSparrow(AssetPaths.jevil__png, AssetPaths.jevil__xml);
        jevilCutscene.animation.addByPrefix("teleport", "jevil_teleport_", 4, false);
        jevilCutscene.animation.play("teleport");
        jevilCutscene.screenCenter();
        jevilCutscene.y -= 175;
        jevilCutscene.x -= 50;

        jevilCutscene.scale.set(4.0, 0.4);
        jevilCutscene.updateHitbox();
        parentState.add(jevilCutscene);

        FlxTween.tween(jevilCutscene.scale, { x: 2.5, y: 2.5 }, 0.18, { ease: FlxEase.backOut });

        mkTimer(0.35, function(_)
        {
            FlxG.sound.play(AssetPaths.jevil_strong_attack02__ogg, 1, false);
        });

        mkTimer(0.75, function(_)
        {
            FlxTween.tween(jevilCutscene.scale, { x: 4.0, y: 0.4 }, 0.18,
            {
                ease: FlxEase.backIn,
                onComplete: function(_)
                {
                    jevilCutscene.kill();
                    jevilCutscene.destroy();
                }
            });
            FlxG.sound.play(AssetPaths.jevil_teleport__ogg, 1, false);
        });
        
    }

    private function teleportBack():Void
    {
        parentState = cast FlxG.state;
        parentState.player.visible = true;

        if (!boss.exists) return;
        
        trace("Barrage completed! Transitioning back to normal room template layout...");

        if (parentState.player.exists)
        {
            boss.state = "ultimate_return_transition";
            boss.hp -= 1;
            parentState.player.y = 500;
            main.RoomLoader.loadRoom(cast FlxG.state, "boss-jevil04");
            if (parentState.bossHpBar.exists) FlxTween.tween(parentState.bossHpBar, {alpha: 1}, 1, { ease: FlxEase.backIn });
            boss.ultimateTriggered = false; 
        }
    }

    public function cancelBarrage():Void
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

        if (parentState != null && parentState.dangerObjects != null)
        {
            parentState.dangerObjects.forEachOfType(main.bosses.ch1.JevilProjectiles.JevilUltimateScythe, function(scythe)
            {
                if (scythe != null && scythe.exists)
                {
                    scythe.kill();
                    if (scythe != null && scythe.alive)
                    {
                        scythe.kill(); 
                    }
                }
            });
        }

        if (fakeoutScythe != null)
        {
            fakeoutScythe.kill();
            fakeoutScythe.exists = false;
            fakeoutScythe.destroy();
            fakeoutScythe = null;
        }

        if (whiteFade != null)
        {
            whiteFade.kill();
            whiteFade.destroy();
            whiteFade = null;
        }

        if (blackFade != null)
        {
            blackFade.visible = false;
        }
    }
}
