package main.bosses.ch1;

import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.util.FlxDirectionFlags;
import flixel.FlxG;
import flixel.util.FlxTimer;
import main.ChapterState;

class Reznor extends FlxSprite
{
    public var status:String = "waiting"; 
    public var minions:Array<ReznorMinion> = [];
    public var createdSlabs:Array<leveldata.blockdata.NormalSlab> = [];
    
    public var platformData:Array<{plat:FlxSprite, radius:Float, initialAngle:Float}> = [];
    
    public var spinSprite:FlxSprite;
    public var fightingBoss:Bool = false;
    public var flash:FlxSprite;
    
    var parentState:ChapterState;
    public var wheelAngle:Float = 0;
    var rotationSpeed:Float = 50;

    public function new(x:Float, y:Float, stateRef:ChapterState)
    {
        super(x, y);
        this.parentState = stateRef;
        if (FlxG.sound.music != null) { FlxG.sound.music.stop(); }
        parentState.player.active = active;
        
        makeGraphic(1, 1, 0x00000000);
        
        spinSprite = new FlxSprite(x, y);
        spinSprite.loadGraphic(AssetPaths.reznor_spin__png, false);
        spinSprite.x = x - (spinSprite.width / 2);
        spinSprite.y = y - (spinSprite.height / 2);
        
        parentState.eventEffectGroup.add(spinSprite);

        var platformCoords =
        [
            {x: 750, y: 553},
            {x: 1085, y: 550},
            {x: 735, y: 200},
            {x: 1070, y: 205}
        ];

        for (i in 0...platformCoords.length)
        {
            var plat = new FlxSprite(platformCoords[i].x, platformCoords[i].y);
            plat.immovable = true;
            plat.allowCollisions = FlxDirectionFlags.UP;
            plat.loadGraphic(AssetPaths.reznor_platform__png, false);
            parentState.eventEffectGroup.insert(1, plat);

            var platCenterX = plat.x + (plat.width / 2);
            var platCenterY = plat.y + (plat.height / 2);
            var dx = platCenterX - this.x;
            var dy = platCenterY - this.y;
            var rad = Math.sqrt(dx * dx + dy * dy);
            var initAng = Math.atan2(dy, dx) * 180 / Math.PI;

            platformData.push({plat: plat, radius: rad, initialAngle: initAng});

            var minion = new ReznorMinion(this, plat, parentState);
            minions.push(minion);
            parentState.dangerObjects.add(minion);
        }

        flash = new FlxSprite();
        flash.makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE, true);
        flash.alpha = 0;
        parentState.eventEffectGroup.add(flash);

        var slab1 = new leveldata.blockdata.NormalSlab(90, 535, 22);
        var slab2 = new leveldata.blockdata.NormalSlab(140, 535, 22);
        var slab3 = new leveldata.blockdata.NormalSlab(190, 535, 22);

        createdSlabs.push(slab1);
        createdSlabs.push(slab2);
        createdSlabs.push(slab3);

        parentState.slabs.add(slab1);
        parentState.slabs.add(slab2);
        parentState.slabs.add(slab3);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (status == "waiting")
        {
            if (parentState != null && parentState.player != null && parentState.player.x >= 350)
            {
                parentState.player.active = false;
                startCutscene();
            }
            return;
        }

        wheelAngle += rotationSpeed * elapsed;
        if (spinSprite != null)
        {
            spinSprite.angle = wheelAngle;
        }


        if (status != "dead" && status != "ending")
        {
            for (data in platformData)
            {
                if (data.plat != null && data.plat.exists)
                {
                    var currentAngleRad = (wheelAngle + data.initialAngle) * (Math.PI / 180);
                    var newPlatCenterX = this.x + Math.cos(currentAngleRad) * data.radius;
                    var newPlatCenterY = this.y + Math.sin(currentAngleRad) * data.radius;

                    data.plat.x = newPlatCenterX - (data.plat.width / 2);
                    data.plat.y = newPlatCenterY - (data.plat.height / 2);
                }
            }
        }

        if (parentState.player != null && parentState.player.exists)
        {
            for (data in platformData)
            {
                if (data.plat != null && data.plat.exists)
                {
                    FlxG.collide(parentState.player, data.plat);
                }
            }
        }

        if (flash.alpha > 0)
        {
            flash.alpha -= elapsed;
        }

        if (status == "dead")
        {
            endingCutscene();
        }

        checkPhases();
    }

    public function startCutscene():Void
    {
        status = "cutscene";
        parentState.currentBossName = "reznor";
        FlxG.camera.shake(0.01, 1.5);
        FlxG.sound.play(AssetPaths.jevil_laugh01__ogg, 1, false);
        parentState.fightingBoss = true;

        new FlxTimer().start(2, function(_)
        {
            flash.alpha = 0.35;
            FlxG.sound.play(AssetPaths.start_fight01__ogg, 0.75, false);
            FlxG.sound.playMusic(AssetPaths.reznor_fight__ogg, 1, true);
            if (FlxG.sound.music != null)
            {
                FlxG.sound.music.loopTime = 5325;
            }
            status = "phase1";
            parentState.player.active = active;
            for (reznor in minions)
            {
                reznor.canBeHit = true;
            }
            startAttacking();
        });
    }

    public function startAttacking():Void {}

    function checkPhases()
    {
        if (status == "dead" || status == "ending") return;

        var aliveCount = 0;
        for (m in minions) 
        {
            if (m.alive && m.exists) aliveCount++;
        }

        if (aliveCount == 0 && status != "dead") 
        {
            status = "dead";
            if (FlxG.sound.music != null) { FlxG.sound.music.stop(); }
            rotationSpeed = 0; 
            parentState.player.active = false;
            parentState.player.velocity.y = 0;
            parentState.player.velocity.x = 0;
        } 
        else if (aliveCount <= 2 && status == "phase1") 
        {
            status = "phase2";
            rotationSpeed = 75;
            FlxG.sound.music.pitch = 1.1;
        }
        else if (aliveCount == 1 && status == "phase2") 
        {
            status = "phase3";
            rotationSpeed = 90;
            FlxG.sound.music.pitch = 1.25;
        }
    }

    public function endingCutscene():Void
    {
        status = "ending";
        new FlxTimer().start(2, function(_)
        {
            FlxG.sound.play(AssetPaths.jevil_explosion__ogg, 1, false);
            FlxG.camera.shake(0.05, 1);
            flash.alpha = 0.5;

            var particle = new flixel.effects.particles.FlxEmitter(950, 800);
            particle.makeParticles(5, 5, FlxColor.WHITE, 150);
            particle.color.set(FlxColor.RED, FlxColor.RED, FlxColor.ORANGE, FlxColor.YELLOW);
            particle.launchMode = CIRCLE;
            particle.speed.set(200, 500);
            particle.lifespan.set(1, 3);
            parentState.dangerObjects.add(particle);
            particle.start(true, 0, 150);

            new FlxTimer().start(3.5, function(_)
            {
                if (parentState != null) 
                {
                    parentState.dangerObjects.remove(particle, true);
                }
                if (particle != null) 
                {
                    particle.destroy();
                }
            });

            new FlxTimer().start(3, function(_)
            {
                parentState.player.active = true;
                parentState.fightingBoss = false;

                for (slab in createdSlabs)
                {
                    if (slab != null)
                    {
                        parentState.slabs.remove(slab, true);
                        slab.destroy();
                    }
                }
                createdSlabs = [];
            });
        });
    }

    override public function destroy():Void
    {
        createdSlabs = [];
        minions = [];
        platformData = [];
        super.destroy();
    }
}

class ReznorMinion extends FlxSprite
{
    public var platform:FlxSprite;
    public var hp:Int = 30;
    public var canBeHit:Bool = false;

    var centerAnchor:Reznor;
    var parentState:ChapterState;

    public function new(centerAnchor:Reznor, plat:FlxSprite, stateRef:ChapterState)
    {
        super(plat.x, plat.y);
        
        this.centerAnchor = centerAnchor;
        this.parentState = stateRef;
        this.platform = plat;

        loadGraphic(AssetPaths.reznor__png, true, 96, 96);
        animation.add("idle", [1], 1, false);
        animation.add("attacking", [0, 1], 3, true);
        animation.play("idle");

        this.x = platform.x + (platform.width / 2) - (this.width / 2);
        this.y = platform.y - this.height;
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (centerAnchor.status == "waiting") return;

        if (alive && platform != null)
        {
            this.x = platform.x + (platform.width / 2) - (this.width / 2);
            this.y = platform.y - this.height; 
        }

        if (!this.alive && this.y >= 800)
        {
            FlxG.camera.shake(0.02, 0.01);
            FlxG.sound.play(AssetPaths.jevil_explosion__ogg, 0.5, false);

            var particle = new flixel.effects.particles.FlxEmitter(this.x, 750);
            particle.makeParticles(5, 5, FlxColor.WHITE, 100);
            particle.color.set(FlxColor.RED, FlxColor.RED, FlxColor.ORANGE, FlxColor.YELLOW);
            particle.launchMode = CIRCLE;
            particle.speed.set(400, 800);
            particle.lifespan.set(0.5, 2);
            parentState.dangerObjects.add(particle);
            particle.start(true, 0, 100);

            new FlxTimer().start(2, function(_)
            {
                if (parentState != null) 
                {
                    parentState.dangerObjects.remove(particle, true);
                }
                if (particle != null) 
                {
                    particle.destroy();
                }
            });

            this.active = false;
            this.destroy();
        }
    }

    public function takeDamage(damage:Int)
    {
        if (!alive || !canBeHit) return;
        canBeHit = false;

        hp -= damage;
        FlxFlicker.flicker(this, 0.2, 0.04, true);
        FlxG.sound.play(AssetPaths.jevil_hit__ogg, 0.5, false);

        if (hp <= 0)
        {
            this.alive = false;
            this.flipY = true;

            this.velocity.y = 500; 

            FlxG.camera.shake(0.015, 0.1);
            FlxG.sound.play(AssetPaths.reznor_down__ogg, 1, false);
        }
        else
        {
            new FlxTimer().start(0.1, function(_)
            {
                if (this.alive) canBeHit = true;
            });
        }
    }

    override public function destroy():Void
    {
        platform = null; 
        super.destroy();
    }
}