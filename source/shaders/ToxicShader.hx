package shaders;

import flixel.system.FlxAssets.FlxShader;

class ToxicShader extends FlxShader
{
    @:glFragmentSource('
#pragma header

uniform float time;
uniform float distortionAmount;
uniform float toxicIntensity;

void main()
{
    vec2 uv = openfl_TextureCoordv;

    // 1. Very subtle heat/gas wobble distortion
    float wobbleX = sin(uv.y * 16.0 + time * 2.5) * cos(uv.x * 12.0 + time * 1.8);
    float wobbleY = cos(uv.x * 14.0 + time * 2.0) * sin(uv.y * 10.0 + time * 2.2);
    
    uv += vec2(wobbleX, wobbleY) * distortionAmount;

    // 2. Sample game graphics
    vec4 col = flixel_texture2D(bitmap, uv);

    // Calculate luminance / brightness
    float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));

    // 3. Radioactive Color Grade (Pushes strong toxic greens & damp sewer blues)
    vec3 toxicGrade = vec3(0.9, 1.05, 0.9);
    vec3 color = mix(col.rgb, col.rgb * toxicGrade, toxicIntensity);

    // 4. Neon "Radioactive" Highlight Glow
    // Finds bright elements and adds an electric lime luminescence
    float highlight = smoothstep(0.35, 0.85, gray);
    vec3 radioactiveGlow = vec3(0.25, 0.95, 0.15) * highlight * 0.30 * toxicIntensity;
    color += radioactiveGlow;

    // 5. Deep Damp Shadows
    color = pow(color, vec3(1.12));

    // 6. Dirty Slime Vignette
    float dist = length(uv - vec2(0.5));
    float vignette = smoothstep(0.85, 0.22, dist);
    color *= vignette;

    gl_FragColor = vec4(color, col.a);
}
')

    public function new(distortion:Float = 0.0025, intensity:Float = 1.0)
    {
        super();
        if (data != null)
        {
            if (data.time != null) data.time.value = [0.0];
            if (data.distortionAmount != null) data.distortionAmount.value = [distortion];
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