package backgrounds3D;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

typedef RenderTriangle =
{
    var x1:Int; var y1:Int;
    var x2:Int; var y2:Int;
    var x3:Int; var y3:Int;
    var color:Int;
    var avgZ:Float;
}

class CircusBackground extends FlxGroup
{
    public var canvas:FlxSprite;
    
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
    public var innerCenterHeight:Float = -170; // Floor inner apex height
    public var ceilingInnerCenterHeight:Float = -400; // Ceiling inner apex height
    public var meetInMiddle:Bool = false; 
    
    public var numSidesInner:Int = 8;
    
    // --- PERSPECTIVE CONTROLS ---
    public var floorPitchAngle:Float = 15;    // Pitch for floor cone (tilted down)
    public var ceilingPitchAngle:Float = 45;  // Pitch for ceiling cone (tilted up)
    
    // --- SHIFT CEILING INNER TRIANGLE DOWNWARD ---
    public var ceilingInnerOffsetY:Float = 55; 

    public var palette:Array<Int>;
    public var innerPalette:Array<Int>;
    var _rect:Rectangle;

    public function new()
    {
        super();
        
        _rect = new Rectangle(0, 0, 0, 1);

        palette = [
            0xff050d80, 0xff1f2463
        ];

        innerPalette = [
            0xff050d80, 0xff1f2463
        ];

        canvas = new FlxSprite(0, 0);
        canvas.makeGraphic(FlxG.width, FlxG.height, 0x00000000, true);
        add(canvas);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        
        canvas.pixels.lock();
        canvas.pixels.fillRect(canvas.pixels.rect, 0x00000000);

        rotationAngle += rotationSpeed * elapsed;
        if (rotationAngle >= 360) rotationAngle -= 360;

        // ==========================================
        // 1. CALCULATE APEX HEIGHTS
        // ==========================================
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

        // ==========================================
        // 2. BUILD VERTICES FOR FLOOR & CEILING
        // ==========================================
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

        // ==========================================
        // 3. PROJECT 3D TO SCREEN SPACE
        // ==========================================
        var projX_floor = new Array<Int>();
        var projY_floor = new Array<Int>();
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

            projX_floor.push(Std.int(FlxG.width / 2 + rx * perspective));
            projY_floor.push(Std.int(FlxG.height / 2 + (finalY + floorY) * perspective));
            worldZ_floor.push(wz);
        }

        var projX_ceiling = new Array<Int>();
        var projY_ceiling = new Array<Int>();
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

            projX_ceiling.push(Std.int(FlxG.width / 2 + rx * perspective));
            projY_ceiling.push(Std.int(FlxG.height / 2 + (finalY + ceilingY) * perspective));
            worldZ_ceiling.push(wz);
        }

        // ==========================================
        // 4. FOUR SEPARATE QUEUES FOR CORRECT LAYERING
        // ==========================================
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

        // Populate Outer Queues
        for (i in 0...numSides)
        {
            var i1 = i + 1;
            var i2 = ((i + 1) % numSides) + 1;
            var i3 = 0;
            
            var floorColor = palette[i % palette.length];
            var ceilingColor = palette[(i + 1) % palette.length]; // Swapped colors for ceiling

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

        // Populate Inner Queues
        var innerStartIndex = innerApex + 1;
        for (i in 0...numSidesInner)
        {
            var i1 = innerStartIndex + i;
            var i2 = innerStartIndex + ((i + 1) % numSidesInner);
            var i3 = innerApex;
            
            var floorInnerColor = innerPalette[i % innerPalette.length];
            var ceilingInnerColor = innerPalette[(i + 1) % innerPalette.length]; // Swapped colors for inner ceiling

            floorInnerQueue.push({
                x1: projX_floor[i1], y1: projY_floor[i1],
                x2: projX_floor[i2], y2: projY_floor[i2],
                x3: projX_floor[i3], y3: projY_floor[i3],
                color: floorInnerColor,
                avgZ: (worldZ_floor[i1] + worldZ_floor[i2] + worldZ_floor[i3]) / 3.0
            });

            ceilingInnerQueue.push({
                x1: projX_ceiling[i1], y1: projY_ceiling[i1] + Std.int(ceilingInnerOffsetY),
                x2: projX_ceiling[i2], y2: projY_ceiling[i2] + Std.int(ceilingInnerOffsetY),
                x3: projX_ceiling[i3], y3: projY_ceiling[i3] + Std.int(ceilingInnerOffsetY),
                color: ceilingInnerColor,
                avgZ: (worldZ_ceiling[i1] + worldZ_ceiling[i2] + worldZ_ceiling[i3]) / 3.0
            });
        }

        // Sort each queue individually by depth
        floorOuterQueue.sort(sortByDepth);
        floorInnerQueue.sort(sortByDepth);
        ceilingOuterQueue.sort(sortByDepth);
        ceilingInnerQueue.sort(sortByDepth);

        // ==========================================
        // 5. RENDER IN THE CORRECT OVERLAP ORDER
        // ==========================================
        
        // 1. Draw Ceiling Inner first (so the platform can cover it)
        for (t in ceilingInnerQueue)
        {
            drawTriangle(canvas.pixels, t.x1, t.y1, t.x2, t.y2, t.x3, t.y3, t.color);
        }
        
        // 2. Draw Ceiling Outer platform on top (hides the root of the ceiling inner triangle)
        for (t in ceilingOuterQueue)
        {
            drawTriangle(canvas.pixels, t.x1, t.y1, t.x2, t.y2, t.x3, t.y3, t.color);
        }
        
        // 3. Draw Floor Outer platform
        for (t in floorOuterQueue)
        {
            drawTriangle(canvas.pixels, t.x1, t.y1, t.x2, t.y2, t.x3, t.y3, t.color);
        }
        
        // 4. Draw Floor Inner shape on top of the floor platform
        for (t in floorInnerQueue)
        {
            drawTriangle(canvas.pixels, t.x1, t.y1, t.x2, t.y2, t.x3, t.y3, t.color);
        }

        canvas.pixels.unlock();
        canvas.dirty = true;
    }

    function drawTriangle(bmp:BitmapData, x1:Int, y1:Int, x2:Int, y2:Int, x3:Int, y3:Int, color:Int)
    {
        if (y1 > y2) { var ty = y1; y1 = y2; y2 = ty; var tx = x1; x1 = x2; x2 = tx; }
        if (y1 > y3) { var ty = y1; y1 = y3; y3 = ty; var tx = x1; x1 = x3; x3 = tx; }
        if (y2 > y3) { var ty = y2; y2 = y3; y3 = ty; var tx = x2; x2 = x3; x3 = tx; }

        if (y1 == y3) return;

        if (y2 == y3)
        {
            drawFlatBottomTriangle(bmp, x1, y1, x2, y2, x3, y3, color);
        }
        else if (y1 == y2)
        {
            drawFlatTopTriangle(bmp, x1, y1, x2, y2, x3, y3, color);
        }
        else
        {
            var x4 = Std.int(x1 + ((y2 - y1) / (y3 - y1)) * (x3 - x1));
            drawFlatBottomTriangle(bmp, x1, y1, x2, y2, x4, y2, color);
            drawFlatTopTriangle(bmp, x2, y2, x4, y2, x3, y3, color);
        }
    }

    function drawFlatBottomTriangle(bmp:BitmapData, x1:Int, y1:Int, x2:Int, y2:Int, x3:Int, y3:Int, color:Int)
    {
        var invslope1:Float = (x2 - x1) / (y2 - y1);
        var invslope2:Float = (x3 - x1) / (y3 - y1);
        var curx1:Float = x1;
        var curx2:Float = x1;
        var startY = y1;
        var endY = y2;

        if (startY < 0)
        {
            curx1 += invslope1 * (-startY);
            curx2 += invslope2 * (-startY);
            startY = 0;
        }
        if (endY >= bmp.height) endY = bmp.height - 1;

        for (y in startY...endY + 1)
        {
            renderScanline(bmp, y, curx1, curx2, color);
            curx1 += invslope1;
            curx2 += invslope2;
        }
    }

    function drawFlatTopTriangle(bmp:BitmapData, x1:Int, y1:Int, x2:Int, y2:Int, x3:Int, y3:Int, color:Int)
    {
        var invslope1:Float = (x3 - x1) / (y3 - y1);
        var invslope2:Float = (x3 - x2) / (y3 - y2);
        var curx1:Float = x1;
        var curx2:Float = x2;
        var startY = y1;
        var endY = y3;

        if (startY < 0)
        {
            curx1 += invslope1 * (-startY);
            curx2 += invslope2 * (-startY);
            startY = 0;
        }
        if (endY >= bmp.height) endY = bmp.height - 1;

        for (y in startY...endY + 1)
        {
            renderScanline(bmp, y, curx1, curx2, color);
            curx1 += invslope1;
            curx2 += invslope2;
        }
    }

    @:inline
    function renderScanline(bmp:BitmapData, y:Int, xStart:Float, xEnd:Float, color:Int)
    {
        if (xStart > xEnd)
        {
            var tmp = xStart;
            xStart = xEnd;
            xEnd = tmp;
        }

        var ix1 = Std.int(xStart);
        var ix2 = Std.int(xEnd);

        if (ix1 < 0) ix1 = 0;
        if (ix2 >= bmp.width) ix2 = bmp.width - 1;

        if (ix1 <= ix2)
        {
            _rect.x = ix1;
            _rect.y = y;
            _rect.width = (ix2 - ix1) + 1;
            bmp.fillRect(_rect, color);
        }
    }
}