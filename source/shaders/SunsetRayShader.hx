package shaders;

import flixel.system.FlxAssets.FlxShader;

class SunsetRayShader extends FlxShader
{
    @:glFragmentSource('
#pragma header

uniform float time;
uniform float rayIntensity;
uniform float pixelSize; // 1.0 = Normal resolution, 4.0 = 4x Pixelated blocks

// Multi-frequency wave function for soft shifting sunbeams
float rayNoise(float angle, float t)
{
    float n = sin(angle * 10.0 + t * 0.15) * 0.5;
    n += sin(angle * 22.0 - t * 0.10) * 0.3;
    n += sin(angle * 45.0 + t * 0.20) * 0.2;
    return pow(n * 0.5 + 0.5, 2.0); // Sharpen beam contrast
}

void main()
{
    vec2 uv = openfl_TextureCoordv;

    // ----------------------------------------------------------------------
    // Pixelation Logic
    // ----------------------------------------------------------------------
    if (pixelSize > 1.0)
    {
        vec2 grid = openfl_TextureSize / pixelSize;
        uv = floor(uv * grid) / grid;
    }

    // 1. Sample background graphics with quantized UVs
    vec4 col = flixel_texture2D(bitmap, uv);

    // 2. Sun Position
    vec2 sunPos = vec2(0.44, 0.48);
    vec2 delta = uv - sunPos;
    float dist = length(delta);
    float angle = atan(delta.y, delta.x);

    // 3. Obvious Atmospheric Breathing Pulse
    float pulse = 0.75 + 0.5 * sin(time * 2.0);

    float rays = rayNoise(angle, time);

    // Distance attenuation & Sky mask
    float rayFade = 1.0 - smoothstep(0.0, 1.2, dist);
    float skyMask = smoothstep(0.2, -0.3, delta.y);

    float finalRays = rays * rayFade * skyMask;

    // 4. Sunset Colors
    vec3 sunCoreColor = vec3(1.0, 0.90, 0.70);
    vec3 rayColor     = vec3(1.0, 0.55, 0.20);
    vec3 horizonGlow  = vec3(0.9, 0.30, 0.15);

    // Sun disc and atmospheric halo glow
    float sunDisc = 1.0 - smoothstep(0.01, 0.06, dist);
    float sunGlow = 1.0 - smoothstep(0.0, 0.45, dist);

    // 5. Apply pulse to both rays and halo glow
    vec3 lightComposite = (rayColor * finalRays * 0.40 * pulse) 
                        + (sunCoreColor * sunGlow * 0.20 * pulse) 
                        + (sunCoreColor * sunDisc * 0.40);

    // Blend rays over background
    vec3 color = col.rgb + (lightComposite * rayIntensity);

    // Ambient warm tint
    vec3 warmTint = mix(vec3(1.0), horizonGlow * 1.05, (1.0 - uv.y) * 0.15);
    color *= warmTint;

    gl_FragColor = vec4(color, col.a);
}
')

    public function new(intensity:Float = 0.35, pixelFactor:Float = 4.0)
    {
        super();
        if (data != null)
        {
            if (data.time != null) data.time.value = [0.0];
            if (data.rayIntensity != null) data.rayIntensity.value = [intensity];
            if (data.pixelSize != null) data.pixelSize.value = [pixelFactor];
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