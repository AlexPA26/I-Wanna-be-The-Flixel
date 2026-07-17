package shaders;

import flixel.system.FlxAssets.FlxShader;

class CastleIndoors extends FlxShader
{
    @:glFragmentSource('
#pragma header

uniform float time;
uniform float rayIntensity;
uniform float torchFlickerSpeed;

void main()
{
    vec2 uv = openfl_TextureCoordv;

    // 1. Sample original game graphics
    vec4 col = flixel_texture2D(bitmap, uv);

    // 2. Ambient Torchlight Flicker (Warm amber/orange organic pulsing)
    float flicker = 0.96 + 0.04 * (sin(time * torchFlickerSpeed) * cos(time * (torchFlickerSpeed * 1.61)));
    vec3 torchWarmth = vec3(1.08, 0.96, 0.85) * flicker;
    vec3 color = col.rgb * torchWarmth;

    // 3. Castle Window Light Shafts (Slanted dust/god rays)
    vec2 rayUv = uv;
    rayUv.x += rayUv.y * 0.35; // Slant angle (rays coming from top-left windows)

    float rayPattern = sin(rayUv.x * 20.0 + time * 0.7) * sin(rayUv.x * 9.0 - time * 0.4);
    float rayAlpha = smoothstep(0.15, 0.85, rayPattern) * (1.0 - uv.y) * 0.22 * rayIntensity;

    // Warm golden light for the rays
    vec3 rayColor = vec3(1.0, 0.92, 0.72) * rayAlpha;
    color += rayColor;

    // 4. Subtle Gothic Contrast (Deepens dark stone shadows)
    color = pow(color, vec3(1.08));

    // 5. Heavy Castle Wall Vignette
    float dist = length(uv - vec2(0.5));
    float vignette = smoothstep(0.82, 0.28, dist);
    color *= vignette;

    gl_FragColor = vec4(color, col.a);
}
')

    public function new(rayPower:Float = 1.0, flickerSpeed:Float = 9.0)
    {
        super();
        if (data != null)
        {
            if (data.time != null) data.time.value = [0.0];
            if (data.rayIntensity != null) data.rayIntensity.value = [rayPower];
            if (data.torchFlickerSpeed != null) data.torchFlickerSpeed.value = [flickerSpeed];
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