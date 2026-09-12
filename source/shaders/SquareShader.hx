package shaders;

import flixel.system.FlxAssets.FlxShader;


class SquareShader extends FlxShader
{
    @:glFragmentSource('
#pragma header

uniform float time;

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main()
{
    vec4 texColor = flixel_texture2D(bitmap, openfl_TextureCoordv);

    // ===================================
    // 1. Infinite nested squares
    // ===================================
    // Centered UV, -1..1 range.
    vec2 uv = (openfl_TextureCoordv - 0.5) * 2.0;

    // Chebyshev ("square") distance instead of a circular length() — this is
    // what makes the level sets come out as SQUARES instead of circles.
    float d = max(abs(uv.x), abs(uv.y));
    d = max(d, 0.0001); // avoid log2(0) at dead center

    // log2(d) shrinks toward -infinity as d -> 0 (the center). Subtracting a
    // continuously growing time term and taking floor() of the result gives a
    // ring index that keeps counting forever in one direction — the squares
    // never actually reset or pop, they just keep receding "infinitely".
    float zoomSpeed = 0.5;
    float rings = log2(d) - time * zoomSpeed;
    float ringIndex = floor(rings);

    // ===================================
    // 2. Two-color alternating bands
    // ===================================
    float bandParity = mod(ringIndex, 2.0);

    vec3 colorA = vec3(1.0, 0.0, 0.0);   // Red
    vec3 colorB = vec3(1.0, 0.35, 0.55); // Red-pink

    vec3 baseColor = mix(colorA, colorB, bandParity);

    // ===================================
    // 3. Slow hue rotation — +25 degrees every 2 seconds
    // ===================================
    float hueStepDegrees = 25.0;
    float hueShift = floor(time / 2.0) * (hueStepDegrees / 360.0);

    vec3 hsv = rgb2hsv(baseColor);
    hsv.x = fract(hsv.x + hueShift);
    vec3 finalColor = hsv2rgb(hsv);

    gl_FragColor = vec4(finalColor, texColor.a);
}
')

    public function new()
    {
        super();
        // Initialize safely after super()
        if (data != null && data.time != null)
        {
            data.time.value = [0.0];
        }
    }

    public function update(elapsed:Float):Void
    {
        if (data != null && data.time != null)
        {
            if (data.time.value == null)
            {
                data.time.value = [0.0];
            }
            data.time.value[0] += elapsed;
        }
    }
}
