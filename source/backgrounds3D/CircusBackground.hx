package backgrounds3D;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import openfl.Vector;

typedef RenderTriangle =
{
    var x1:Float; var y1:Float;
    var x2:Float; var y2:Float;
    var x3:Float; var y3:Float;
    var color:Int;
    var avgZ:Float;
}

class CircusBackground extends FlxGroup
{
    public var canvas:CircusCanvas;
    
    public var focalLength:Float = 500;
    public var rotationAngle:Float = 0;
    public var rotationSpeed:Float = 0;
    
    public var floorY:Float = 50;
    public var ceilingY:Float = -375;
    
    public var distanceZ:Float = 0;
    public var squareSize:Float = 400;
    public var centerHeight:Float = 100;
    public var numSides:Int = 8;
    
    public var innerSquareSize:Float = 100;
    public var innerCenterHeight:Float = -170;
    public var ceilingInnerCenterHeight:Float = -400;
    public var meetInMiddle:Bool = false; 
    
    public var numSidesInner:Int = 8;
    
    public var floorPitchAngle:Float = 15;
    public var ceilingPitchAngle:Float = 45;
    public var ceilingInnerOffsetY:Float = 55; 

    public var palette:Array<Int>;
    public var innerPalette:Array<Int>;

    var paletteColors:Array<Int> = [];
    var colorIndexMap:Map<Int, Int> = new Map();

    public function new()
    {
        super();
        
        palette = [0xff050d80, 0xff1f2463];
        innerPalette = [0xff050d80, 0xff1f2463];

        canvas = new CircusCanvas();
        add(canvas);

        buildPaletteTexture();
    }


    public function buildPaletteTexture():Void
    {
        paletteColors = [];
        colorIndexMap = new Map();

        for (c in palette) registerColor(c);
        for (c in innerPalette) registerColor(c);
        if (paletteColors.length == 0) registerColor(0xffffffff);

        // unique = true so this never collides with another cached graphic.
        canvas.makeGraphic(paletteColors.length, 1, FlxColor.TRANSPARENT, true);
        for (i in 0...paletteColors.length)
        {
            canvas.pixels.setPixel32(i, 0, paletteColors[i]);
        }
        canvas.dirty = true;

        // Nearest-neighbour sampling, otherwise adjacent palette pixels blend
        // into each other and the colours come out muddy.
        canvas.antialiasing = false;
    }

    inline function registerColor(c:Int):Void
    {
        if (!colorIndexMap.exists(c))
        {
            colorIndexMap.set(c, paletteColors.length);
            paletteColors.push(c);
        }
    }

    // U coordinate of the centre of this colour's pixel in the palette strip.
    function colorU(c:Int):Float
    {
        var idx = colorIndexMap.exists(c) ? colorIndexMap.get(c) : 0;
        return (idx + 0.5) / paletteColors.length;
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        
        rotationAngle += rotationSpeed * elapsed;
        if (rotationAngle >= 360) rotationAngle -= 360;

        var t = innerSquareSize / squareSize;
        var innerBaseHeight = centerHeight * (1 - t);
        
        var floorApexY = innerCenterHeight;
        var ceilingApexY = ceilingInnerCenterHeight;

        if (meetInMiddle)
        {
            var midPointY = (floorY + ceilingY) / 2.0;
            floorApexY = (midPointY - floorY) - innerBaseHeight;
            ceilingApexY = (ceilingY - midPointY) - innerBaseHeight;
        }

        var verticesFloor = new Array<Array<Float>>();
        var verticesCeiling = new Array<Array<Float>>();

        var outerApex = verticesFloor.length;
        verticesFloor.push([0.0, centerHeight, 0.0]);
        
        for (i in 0...numSides)
        {
            var angle = (i * Math.PI * 2) / numSides;
            verticesFloor.push([Math.cos(angle) * squareSize, 0.0, Math.sin(angle) * squareSize]);
        }

        var innerApex = verticesFloor.length;
        verticesFloor.push([0.0, innerBaseHeight + floorApexY, 0.0]);
        
        for (i in 0...numSidesInner)
        {
            var angle = (i * Math.PI * 2) / numSidesInner;
            verticesFloor.push([Math.cos(angle) * innerSquareSize, innerBaseHeight, Math.sin(angle) * innerSquareSize]);
        }

        verticesCeiling.push([0.0, -centerHeight, 0.0]);
        for (i in 0...numSides)
        {
            var angle = (i * Math.PI * 2) / numSides;
            verticesCeiling.push([Math.cos(angle) * squareSize, 0.0, Math.sin(angle) * squareSize]);
        }
        verticesCeiling.push([0.0, -(innerBaseHeight + ceilingApexY), 0.0]);
        for (i in 0...numSidesInner)
        {
            var angle = (i * Math.PI * 2) / numSidesInner;
            verticesCeiling.push([Math.cos(angle) * innerSquareSize, -innerBaseHeight, Math.sin(angle) * innerSquareSize]);
        }

        var rad = rotationAngle * Math.PI / 180;
        var cosY = Math.cos(rad);
        var sinY = Math.sin(rad);

        var projX_floor = new Array<Float>();
        var projY_floor = new Array<Float>();
        var worldZ_floor = new Array<Float>();

        var floorPitchRad = floorPitchAngle * Math.PI / 180;
        var cosX_f = Math.cos(floorPitchRad);
        var sinX_f = Math.sin(floorPitchRad);

        for (v in verticesFloor)
        {
            var rx = v[0] * cosY - v[2] * sinY;
            var rz = v[0] * sinY + v[2] * cosY;
            var ry = v[1];

            var finalY = ry * cosX_f - rz * sinX_f;
            var finalZ = ry * sinX_f + rz * cosX_f;

            var wz = finalZ + distanceZ;
            var safeWz = (wz < -focalLength + 1) ? -focalLength + 1 : wz;
            var perspective = focalLength / (focalLength + safeWz);

            projX_floor.push(FlxG.width / 2 + rx * perspective);
            projY_floor.push(FlxG.height / 2 + (finalY + floorY) * perspective);
            worldZ_floor.push(wz);
        }

        var projX_ceiling = new Array<Float>();
        var projY_ceiling = new Array<Float>();
        var worldZ_ceiling = new Array<Float>();

        var ceilingPitchRad = ceilingPitchAngle * Math.PI / 180;
        var cosX_c = Math.cos(ceilingPitchRad);
        var sinX_c = Math.sin(ceilingPitchRad);

        for (v in verticesCeiling)
        {
            var rx = v[0] * cosY - v[2] * sinY;
            var rz = v[0] * sinY + v[2] * cosY;
            var ry = v[1];

            var finalY = ry * cosX_c - rz * sinX_c;
            var finalZ = ry * sinX_c + rz * cosX_c;

            var wz = finalZ + distanceZ;
            var safeWz = (wz < -focalLength + 1) ? -focalLength + 1 : wz;
            var perspective = focalLength / (focalLength + safeWz);

            projX_ceiling.push(FlxG.width / 2 + rx * perspective);
            projY_ceiling.push(FlxG.height / 2 + (finalY + ceilingY) * perspective);
            worldZ_ceiling.push(wz);
        }

        var floorOuterQueue = new Array<RenderTriangle>();
        var floorInnerQueue = new Array<RenderTriangle>();
        var ceilingOuterQueue = new Array<RenderTriangle>();
        var ceilingInnerQueue = new Array<RenderTriangle>();

        var sortByDepth = function(a:RenderTriangle, b:RenderTriangle)
        {
            if (a.avgZ > b.avgZ) return -1;
            if (a.avgZ < b.avgZ) return 1;
            return 0;
        };

        for (i in 0...numSides)
        {
            var i1 = i + 1;
            var i2 = ((i + 1) % numSides) + 1;
            var i3 = 0;
            
            var floorColor = palette[i % palette.length];
            var ceilingColor = palette[(i + 1) % palette.length]; 

            floorOuterQueue.push({
                x1: projX_floor[i1], y1: projY_floor[i1],
                x2: projX_floor[i2], y2: projY_floor[i2],
                x3: projX_floor[i3], y3: projY_floor[i3],
                color: floorColor,
                avgZ: (worldZ_floor[i1] + worldZ_floor[i2] + worldZ_floor[i3]) / 3.0
            });

            ceilingOuterQueue.push({
                x1: projX_ceiling[i1], y1: projY_ceiling[i1],
                x2: projX_ceiling[i2], y2: projY_ceiling[i2],
                x3: projX_ceiling[i3], y3: projY_ceiling[i3],
                color: ceilingColor,
                avgZ: (worldZ_ceiling[i1] + worldZ_ceiling[i2] + worldZ_ceiling[i3]) / 3.0
            });
        }

        var innerStartIndex = innerApex + 1;
        for (i in 0...numSidesInner)
        {
            var i1 = innerStartIndex + i;
            var i2 = innerStartIndex + ((i + 1) % numSidesInner);
            var i3 = innerApex;
            
            var floorInnerColor = innerPalette[i % innerPalette.length];
            var ceilingInnerColor = innerPalette[i % innerPalette.length];

            floorInnerQueue.push({
                x1: projX_floor[i1], y1: projY_floor[i1],
                x2: projX_floor[i2], y2: projY_floor[i2],
                x3: projX_floor[i3], y3: projY_floor[i3],
                color: floorInnerColor,
                avgZ: (worldZ_floor[i1] + worldZ_floor[i2] + worldZ_floor[i3]) / 3.0
            });

            ceilingInnerQueue.push({
                x1: projX_ceiling[i1], y1: projY_ceiling[i1] + ceilingInnerOffsetY,
                x2: projX_ceiling[i2], y2: projY_ceiling[i2] + ceilingInnerOffsetY,
                x3: projX_ceiling[i3], y3: projY_ceiling[i3] + ceilingInnerOffsetY,
                color: ceilingInnerColor,
                avgZ: (worldZ_ceiling[i1] + worldZ_ceiling[i2] + worldZ_ceiling[i3]) / 3.0
            });
        }

        floorOuterQueue.sort(sortByDepth);
        floorInnerQueue.sort(sortByDepth);
        ceilingOuterQueue.sort(sortByDepth);
        ceilingInnerQueue.sort(sortByDepth);

        var vCount:Int = 0;
        canvas.vertices.length = 0;
        canvas.indices.length = 0;
        canvas.uvtData.length = 0;

        var pushTriangle = function(t:RenderTriangle)
        {
            canvas.vertices.push(t.x1); canvas.vertices.push(t.y1);
            canvas.vertices.push(t.x2); canvas.vertices.push(t.y2);
            canvas.vertices.push(t.x3); canvas.vertices.push(t.y3);

            canvas.indices.push(vCount);
            canvas.indices.push(vCount + 1);
            canvas.indices.push(vCount + 2);

            // All 3 vertices sample the SAME palette pixel, so the triangle
            // comes out flat-filled in that colour.
            var u = colorU(t.color);
            canvas.uvtData.push(u); canvas.uvtData.push(0.5);
            canvas.uvtData.push(u); canvas.uvtData.push(0.5);
            canvas.uvtData.push(u); canvas.uvtData.push(0.5);

            vCount += 3;
        };

        for (t in ceilingInnerQueue) pushTriangle(t);
        for (t in ceilingOuterQueue) pushTriangle(t);
        for (t in floorOuterQueue) pushTriangle(t);
        for (t in floorInnerQueue) pushTriangle(t);
    }
}

class CircusCanvas extends FlxSprite
{
    public var vertices:Vector<Float> = new Vector<Float>();
    public var indices:Vector<Int> = new Vector<Int>();
    public var uvtData:Vector<Float> = new Vector<Float>();

    public function new()
    {
        super(0, 0);
        // The real texture (a palette strip) is built by
        // CircusBackground.buildPaletteTexture(); this is only a placeholder so
        // `graphic` is never null if draw() somehow runs first.
        makeGraphic(1, 1, FlxColor.WHITE, true);
        antialiasing = false;
    }

    override public function draw():Void
    {
        if (vertices.length == 0 || alpha == 0 || !visible || graphic == null) return;
        
        for (camera in cameras)
        {
            if (!camera.visible || !camera.exists) continue;

            // One call that works in BOTH renderTile and renderBlit - it picks
            // the right path internally. No `colors` argument any more, because
            // the colour now lives in the texture itself via the UVs.
            camera.drawTriangles(graphic, vertices, indices, uvtData);
        }
    }
}