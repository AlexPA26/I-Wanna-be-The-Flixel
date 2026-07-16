package main.bosses.ch1;

import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.group.FlxGroup;
import main.ChapterState;
import leveldata.hazards.SolidBlock;

class JevilJailManager
{
    private var state:ChapterState;
    private var jailObjects:FlxGroup;
    private var jailVisualOverlay:FlxSprite;

    public function new(stateRef:ChapterState)
    {
        this.state = stateRef;
        this.jailObjects = new FlxGroup();
    }

    public function createJail(tileID:Int = 0):Void
    {
        var midX:Float = FlxG.width / 2;
        var midY:Float = FlxG.height / 2;

        var arenaWidth:Float = 300;
        var arenaHeight:Float = 250;

        state.player.setPosition(midX - (state.player.width / 2), midY - (state.player.height / 2) - 200);
        state.player.velocity.set(0, 0);

        var tileSize:Float = 50;
        
        var startX:Float = Math.floor((midX - (arenaWidth / 2)) / tileSize) * tileSize;
        var startY:Float = (Math.floor((midY - (arenaHeight / 2)) / tileSize) * tileSize) - 185;
        
        var columns:Int = Std.int(arenaWidth / tileSize) + 2;
        var rows:Int = Std.int(arenaHeight / tileSize) + 2;

        var totalJailWidth:Float = columns * tileSize;
        var totalJailHeight:Float = rows * tileSize;

        var placeTile = function(tx:Float, ty:Float)
        {
            var block = new SolidBlock(tx, ty, tileID);
            
            block.alpha = 0; 
            
            state.solidBlock.add(block);
            jailObjects.add(block);
        };

        for (col in 0...columns)
        {
            for (row in 0...rows)
            {
                if (col == 0 || col == columns - 1 || row == 0 || row == rows - 1)
                {
                    var posX:Float = startX + (col * tileSize);
                    var posY:Float = startY + (row * tileSize);
                    placeTile(posX, posY);
                }
            }
        }

        jailVisualOverlay = new FlxSprite(startX, startY);
        jailVisualOverlay.loadGraphic(AssetPaths.jail__png, false);
        jailVisualOverlay.setGraphicSize(Std.int(totalJailWidth), Std.int(totalJailHeight));
        jailVisualOverlay.updateHitbox();
        state.add(jailVisualOverlay);

        FlxTween.tween(jailVisualOverlay, {y: jailVisualOverlay.y - 3}, 0.8, {type: PINGPONG, ease: flixel.tweens.FlxEase.sineInOut});
    }

    public function destroyJail():Void
    {
        if (jailObjects != null)
        {
            jailObjects.forEach(function(basicObj:flixel.FlxBasic) 
            {
                if (basicObj != null)
                {
                    var sprite:flixel.FlxSprite = cast basicObj;
                    state.solidBlock.remove(cast sprite, true);
                    sprite.destroy();
                }
            });
            jailObjects.clear();
        }

        if (jailVisualOverlay != null)
        {
            state.remove(jailVisualOverlay, true);
            jailVisualOverlay.destroy();
            jailVisualOverlay = null;
        }
    }
}