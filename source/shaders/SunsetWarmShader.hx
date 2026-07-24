package shaders;

import flixel.system.FlxAssets.FlxShader;

class SunsetWarmShader extends FlxShader
{
    @:glFragmentSource('
#pragma header

uniform float time;

void main()
{
    vec2 uv = openfl_TextureCoordv;
    vec4 col = flixel_texture2D(bitmap, uv);

    //---------------------------------------------------------
    // Sunset Warmth Color Grading
    //---------------------------------------------------------

    vec3 color = col.rgb;

    // Golden-amber sunset tint (boosts reds/oranges, softens blues)
    color.r *= 1.12;
    color.g *= 1.01;
    color.b *= 0.82;

    // Slight warmth brightness boost
    color *= 1.02;

    // Soft contrast boost for rich shadows
    color = pow(color, vec3(0.96));

    //---------------------------------------------------------
    // Stronger Sunset Vignette
    //---------------------------------------------------------

    float dist = length(uv - vec2(0.5));

    // Tighter falloff starting closer to screen center (0.18 -> 0.75)
    float vignette = 1.0 - smoothstep(0.18, 0.75, dist);

    // Darkens corners down to 35% brightness (much stronger than CastleInside 65%)
    vignette = mix(0.35, 1.0, vignette);

    color *= vignette;

    gl_FragColor = vec4(color, col.a);
}
')

    public function new()
    {
        super();

        if (data != null && data.time != null)
            data.time.value = [0.0];
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