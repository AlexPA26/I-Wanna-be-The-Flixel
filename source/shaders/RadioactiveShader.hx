package shaders;

import flixel.system.FlxAssets.FlxShader;

class RadioactiveShader extends FlxShader
{
    @:glFragmentSource('
#pragma header

uniform float time;
uniform float toxicIntensity;

void main()
{
    vec2 uv = openfl_TextureCoordv;

    // 1. Direct texture sample (NO screen wobble)
    vec4 col = flixel_texture2D(bitmap, uv);

    // Calculate luminance / brightness
    float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));

    // 2. Very subtle Radioactive Color Grade (Micro green boost)
    vec3 toxicGrade = vec3(0.97, 1.04, 0.97);
    vec3 color = mix(col.rgb, col.rgb * toxicGrade, toxicIntensity);

    // 3. Faint "Radioactive" Highlight Glow
    // Adds a barely-noticeable electric lime sheen on bright highlights
    float highlight = smoothstep(0.5, 0.9, gray);
    vec3 radioactiveGlow = vec3(0.15, 0.85, 0.1) * highlight * 0.06 * toxicIntensity;
    color += radioactiveGlow;

    // 4. Subtle Shadow Contrast (Deepens darks just a tiny bit)
    color = pow(color, vec3(1.04));

    // 5. Soft Vignette
    float dist = length(uv - vec2(0.5));
    float vignette = smoothstep(0.88, 0.35, dist);
    color *= mix(1.0, vignette, 1);

    gl_FragColor = vec4(color, col.a);
}
')

    public function new(intensity:Float = 0.5)
    {
        super();
        if (data != null)
        {
            if (data.time != null) data.time.value = [0.0];
            if (data.toxicIntensity != null) data.toxicIntensity.value = [intensity];
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