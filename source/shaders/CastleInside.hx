package shaders;

import flixel.system.FlxAssets.FlxShader;

class CastleInside extends FlxShader
{
    @:glFragmentSource('
#pragma header

uniform float time;

void main()
{
    vec2 uv = openfl_TextureCoordv;
    vec4 col = flixel_texture2D(bitmap, uv);

    //---------------------------------------------------------
    // Warm torch color grading
    //---------------------------------------------------------

    vec3 color = col.rgb;

    // Warm the image
    color.r *= 1.08;
    color.g *= 1.02;
    color.b *= 0.90;

    // Slight brightness boost
    color *= 1.03;

    // Slight contrast
    color = pow(color, vec3(0.97));

    //---------------------------------------------------------
    // Castle vignette
    //---------------------------------------------------------

    float dist = length(uv - vec2(0.5));

    // Nice smooth falloff
    float vignette = 1.0 - smoothstep(0.25, 0.82, dist);

    // Dont make the corners completely black
    vignette = mix(0.65, 1.0, vignette);

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
            data.time.value[0] += elapsed;
    }
}