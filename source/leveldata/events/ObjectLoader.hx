package leveldata.events;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import leveldata.collectibles.RedCoin;
import flixel.addons.editors.tiled.TiledLayer;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledObjectLayer;
import leveldata.blockdata.*;
import leveldata.deco.*;
import leveldata.events.*;
import leveldata.hazards.*;
import leveldata.misc.*;
import main.ChapterState;
import main.PlayerData;

class ObjectLoader
{
    public static function loadEverything(tiledData:TiledMap, state:ChapterState, offsetX:Float, offsetY:Float):Void
    {

        for (layer in tiledData.layers)
        {
            if (layer.type == TiledLayerType.OBJECT)
            {
                var objectLayer:TiledObjectLayer = cast layer;

                for (obj in objectLayer.objects)
                {
                    var spawnX = obj.x + offsetX;
                    var spawnY = obj.y + offsetY;

                    if (obj.gid > 0) 
                    {
                        spawnY -= obj.height;
                    }

                    switch (obj.name)
                    {
                        case "warp":
                        var target = obj.properties.get("target");
                        var dir = obj.properties.get("direction");
                        var newChapter = obj.properties.get("newChapter");
                        
                        var warp = new WarpTrigger(spawnX, spawnY, obj.width, obj.height, target, dir);
                        warp.newChapter = newChapter;
                        state.warpsGroup.add(warp);

                        case "spike":
                        var localID:Int = 0;
                        if (obj.properties.contains("id")) 
                        {
                            localID = Std.parseInt(obj.properties.get("id"));
                        } 
                        else 
                        {
                            var tileset = tiledData.getGidOwner(obj.gid);
                            localID = obj.gid - tileset.firstGID;
                        }
                            var spike = new NormalSpike(spawnX, spawnY, localID);
                            state.dangerObjects.add(spike);

                        case "small-spike":
                        var localID:Int = 0;
                        if (obj.properties.contains("id")) 
                        {
                            localID = Std.parseInt(obj.properties.get("id"));
                        } 
                        else 
                        {
                            var tileset = tiledData.getGidOwner(obj.gid);
                            localID = obj.gid - tileset.firstGID;
                        }
                            var smallSpike = new SmallSpike(spawnX, spawnY, localID);
                            state.dangerObjects.add(smallSpike);

                        case "switch-spike":
                            var localID:Int = 0;
                            var movement:Int = 50;
                            var status:String = "none";
                            var auto:Bool = false;
                            var speed:Float = 1.5;

                            if (obj.properties.contains("auto"))
                            {
                                auto = obj.properties.get("auto") == "true";

                                if (obj.properties.contains("speed"))
                                {
                                    var parsedSpeed:Float = Std.parseFloat(obj.properties.get("speed"));

                                    if (parsedSpeed > 0)
                                    {
                                        speed = parsedSpeed;
                                    }
                                }
                            }

                            if (obj.properties.contains("status"))
                            {
                                status = obj.properties.get("status");
                            }
                            if (obj.properties.contains("id")) 
                            {
                                localID = Std.parseInt(obj.properties.get("id"));
                            } 
                            var sSpike = new SwitchSpike(spawnX, spawnY, localID, status, movement, auto, speed);
                            state.dangerObjects.add(sSpike);

                        case "save":
                            var save = new SavePoint(spawnX, spawnY);
                            if (PlayerData.currentRoom != state.currentRoomName)
                            {
                                state.savesGroup.add(save);
                            }

                        case "redCoin":
                            var id:String = obj.properties.get("id");

                            if (!PlayerData.isCoinCollected(id))
                            {
                                var coin = new RedCoin(spawnX, spawnY, id);
                                state.redCoinsGroup.add(coin);
                                state.redCoinParticlesGroup.add(coin.particle);
                            }

                        case "doubleJump":
                            var doubleJump = new DoubleJumpObj(spawnX, spawnY);
                            state.doubleJumpGroup.add(doubleJump);
                            
                        case "flip":
                            var flip = new FlipSwitch(spawnX, spawnY);
                            state.flipGroup.add(flip);

                        case "portal":
                            var portal = new PortalWarp(spawnX, spawnY);
                            state.portalGroup.add(portal);

                        case "laser":
                            var dir:String = "hor";
                            if (obj.properties.contains("direction")) { dir = obj.properties.get("direction"); }
                            var laser = new YellowLaser(spawnX, spawnY, dir); 
                            state.dangerObjects.add(laser);

                        case "trampoline":
                            var tramp = new NormalTrampoline(spawnX, spawnY);
                            state.trampolines.add(tramp);
                        
                        case "trampoline-mini":
                            var dir:String = "up";
                            if (obj.properties.contains("direction"))
                            {
                                dir = obj.properties.get("direction");
                            } 
                                
                            var trampMini = new NormalTrampolineMini(spawnX, spawnY, dir);
                                state.trampolinesMini.add(trampMini);

                        case "platform":
                            var dir = obj.properties.get("direction");
                            var speed = 180;
                            var tileset = tiledData.getGidOwner(obj.gid);
                            var localID:Int = obj.gid - tileset.firstGID;

                            if (obj.properties.contains("speed"))
                            {
                                speed = Std.parseInt(obj.properties.get("speed"));
                            }

                            var plat = new MovingBlock(spawnX, spawnY, dir, localID, speed);
                            state.platforms.add(plat);

                        case "falling":
                            var dir = obj.properties.get("direction");
                            var tileset = tiledData.getGidOwner(obj.gid);
                            var localID:Int = obj.gid - tileset.firstGID;
                            var fall = new FallingBlock(spawnX, spawnY, dir, localID);
                            state.fallingBlock.add(fall);

                        case "light":
                            var color:String = "orange";
                            if (obj.properties != null && obj.properties.contains("color"))
                            {
                                var customColor:String = obj.properties.get("color");
                                
                                if (customColor != null && customColor != "")
                                {
                                    color = customColor;
                                }
                            }
                            var light = new LightTorch(spawnX, spawnY, color);
                            light.x -= light.width / 2;
                            light.y -= light.height / 2;
                            state.lightsGroup.add(light);

                        case "slab":
                            var tileset = tiledData.getGidOwner(obj.gid);
                            var localID:Int = obj.gid - tileset.firstGID;
                            var slab = new NormalSlab(spawnX, spawnY, localID);
                            state.slabs.add(slab);

                        case "solid_block":
                            var tileset = tiledData.getGidOwner(obj.gid);
                            var localID:Int = obj.gid - tileset.firstGID;
                            var solid = new SolidBlock(spawnX, spawnY, localID);
                            state.solidBlock.add(solid);

                        case "invisBlock":
                            var tileset = tiledData.getGidOwner(obj.gid);
                            var localID:Int = obj.gid - tileset.firstGID;
                            var invBlock = new InvisibleBlock(spawnX, spawnY, localID);
                            state.invisBlock.add(invBlock);
                            
                        case "image":
                            var imageName:String = "";
                            var opacity:Float = 1;
                            var scale:Float = 1;
                            var tweenDuration:Float = 1;

                            if (obj.properties.contains("imageName"))
                            {
                                imageName = obj.properties.get("imageName");
                            }

                            if (imageName != "")
                            {
                                var imgSprite = new flixel.FlxSprite(spawnX, spawnY);
                                var imgPath = "assets/data/images/chapter" + PlayerData.currentChapter + "/" + imageName + ".png";
                                
                                imgSprite.loadGraphic(imgPath);
                                var blockCenterX:Float = spawnX + (obj.width / 2);
                                var blockCenterY:Float = spawnY + (obj.height / 2);
                                imgSprite.x = blockCenterX - (imgSprite.width / 2);
                                imgSprite.y = blockCenterY - (imgSprite.height / 2);

                                if (obj.properties.contains("alpha"))
                                {
                                    opacity = Std.parseFloat(obj.properties.get("alpha"));
                                    imgSprite.alpha = opacity;
                                }

                                if (obj.properties.contains("scale"))
                                {
                                    scale = Std.parseFloat(obj.properties.get("scale"));
                                    imgSprite.scale.set(scale, scale);
                                    imgSprite.updateHitbox();
                                }

                                if (obj.properties.contains("tweenDuration"))
                                {
                                    tweenDuration = Std.parseFloat(obj.properties.get("tweenDuration"));
                                }

                                if (obj.properties.contains("tween"))
                                {
                                    var offY = Std.parseFloat(obj.properties.get("tween"));
                                    FlxTween.tween(imgSprite, {y: imgSprite.y - offY}, tweenDuration, {type: PINGPONG, ease: FlxEase.sineInOut});
                                }
                                state.roomImages.add(imgSprite);
                            }

                    }
                }
            }
        }
    }
}