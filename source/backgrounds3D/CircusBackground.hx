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
    public var rotationSpeed:Float = 80;
    public var floorY:Float = 50;
    public var distanceZ:Float = 0;
    public var squareSize:Float = 500;
    public var centerHeight:Float = 100;
    public var numSides:Int = 8;
    public var innerSquareSize:Float = 100;
    public var innerCenterHeight:Float = -200;
    public var numSidesInner:Int = 8;

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

        var vertices = [[0.0, centerHeight, 0.0]];
        for (i in 0...numSides)
        {
            var angle = (i * Math.PI * 2) / numSides;
            var vx = Math.cos(angle) * squareSize;
            var vz = Math.sin(angle) * squareSize;
            vertices.push([vx, 0.0, vz]);
        }

        // The outer floor's own apex is at centerHeight and its rim is at 0,
        // so the floor is itself a shallow cone - its surface height varies
        // by radius. Find that local height at the inner ring's radius so
        // the small shape's base sits flush on it instead of floating.
        var innerBaseHeight = centerHeight * (1.0 - innerSquareSize / squareSize);

        // Inner fan gets its OWN apex (separate from vertex 0), offset from
        // that local base height by innerCenterHeight - so it pokes up/down
        // relative to the surface it's actually sitting on, staying grounded
        // instead of floating disconnected above/below it.
        var innerApexIndex = numSides + 1;
        vertices.push([0.0, innerBaseHeight + innerCenterHeight, 0.0]);

        var innerStartIndex = innerApexIndex + 1;
        for (i in 0...numSidesInner)
        {
            var angle = (i * Math.PI * 2) / numSidesInner;
            var vx = Math.cos(angle) * innerSquareSize;
            var vz = Math.sin(angle) * innerSquareSize;
            vertices.push([vx, innerBaseHeight, vz]);
        }

        var projX = new Array<Int>();
        var projY = new Array<Int>();
        var worldZ = new Array<Float>();

        var rad = rotationAngle * Math.PI / 180;
        var cos = Math.cos(rad);
        var sin = Math.sin(rad);

        for (v in vertices)
        {
            var rx = v[0] * cos - v[2] * sin;
            var rz = v[0] * sin + v[2] * cos;
            var ry = v[1];

            var wx = rx;
            var wy = ry + floorY;
            var wz = rz + distanceZ;

            // Safety clamp: as the ring rotates, wz can get arbitrarily
            // close to -focalLength (here squareSize == focalLength, so it
            // actually reaches it). At that point focalLength + wz -> 0 and
            // "perspective" spikes toward infinity for a frame, throwing
            // that vertex way off screen - that's the flicker. Clamp the
            // divisor so it never gets closer than 1 unit to zero.
            var safeWz = wz;
            var minWz = -focalLength + 1;
            if (safeWz < minWz) safeWz = minWz;

            var perspective = focalLength / (focalLength + safeWz);
            var sx = Std.int(FlxG.width / 2 + wx * perspective);
            var sy = Std.int(FlxG.height / 2 + wy * perspective);

            projX.push(sx);
            projY.push(sy);
            worldZ.push(wz);
        }

        // 2. DYNAMICALLY GENERATE BLUEPRINT FACES
        // Outer and inner fans are kept as two SEPARATE queues on purpose.
        // Both live on the same flat floor plane, so the inner fan's disc
        // sits inside the same screen-space area the outer fan already
        // covers near the apex. If we depth-sorted them together, a far
        // outer triangle could occasionally land in the draw order after
        // a near inner triangle and poke over it. Instead we fully sort +
        // draw the outer floor first, then fully sort + draw the smaller
        // inner shape on top - so it's always cleanly centered above the
        // floor with zero chance of being covered.
        var outerQueue = new Array<RenderTriangle>();
        var innerQueue = new Array<RenderTriangle>();

        var sortByDepth = function(a:RenderTriangle, b:RenderTriangle)
        {
            if (a.avgZ > b.avgZ) return -1;
            if (a.avgZ < b.avgZ) return 1;
            return 0;
        };

        // Outer floor fan
        for (i in 0...numSides)
        {
            var i1 = i + 1;
            var i2 = ((i + 1) % numSides) + 1;
            var i3 = 0;

            var color = palette[i % palette.length];
            var avgDepth = (worldZ[i1] + worldZ[i2] + worldZ[i3]) / 3.0;

            outerQueue.push({
                x1: projX[i1], y1: projY[i1],
                x2: projX[i2], y2: projY[i2],
                x3: projX[i3], y3: projY[i3],
                color: color,
                avgZ: avgDepth
            });
        }

        // Inner, smaller fan - its own (raised/lowered) apex, but centered
        // on the same x/z origin as the outer floor's apex.
        for (i in 0...numSidesInner)
        {
            var i1 = innerStartIndex + i;
            var i2 = innerStartIndex + ((i + 1) % numSidesInner);
            var i3 = innerApexIndex;

            var color = innerPalette[i % innerPalette.length];
            var avgDepth = (worldZ[i1] + worldZ[i2] + worldZ[i3]) / 3.0;

            innerQueue.push({
                x1: projX[i1], y1: projY[i1],
                x2: projX[i2], y2: projY[i2],
                x3: projX[i3], y3: projY[i3],
                color: color,
                avgZ: avgDepth
            });
        }

        outerQueue.sort(sortByDepth);
        innerQueue.sort(sortByDepth);

        for (t in outerQueue)
        {
            drawTriangle(canvas.pixels, t.x1, t.y1, t.x2, t.y2, t.x3, t.y3, t.color);
        }
        for (t in innerQueue)
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