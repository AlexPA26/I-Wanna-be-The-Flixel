package shaders;

import flixel.system.FlxAssets.FlxShader;

class RainbowCrazy extends FlxShader
{
    @:glFragmentSource('
#pragma header

uniform float time;

void main()
{
    vec2 uv = openfl_TextureCoordv;

    // ===================================
    // 1. Background Deformation & Warping
    // ===================================

    // Continuous diagonal wave distortion
    uv.x += sin(uv.y * 14.0 + time * 3.5) * 0.02;
    uv.y += cos(uv.x * 10.0 + time * 2.8) * 0.02;

    // Row-based Earthbound-style horizontal jitter
    float row = floor(uv.y * 36.0);
    uv.x += sin(row * 0.25 + time * 6.0) * 0.025;

    // Pulse row scale stretch
    float rowScale = 1.0 + sin(row * 0.15 + time * 4.0) * 0.25;
    uv.x = 0.5 + (uv.x - 0.5) * rowScale;

    // ===================================
    // 2. Texture Sample & Black/White (B&W)
    // ===================================
    vec4 texColor = flixel_texture2D(bitmap, uv);

    // Standard NTSC Grayscale / Luminance formula
    float gray = dot(texColor.rgb, vec3(0.299, 0.587, 0.114));

    // ===================================
    // 3. Dynamic Animated Rainbow Spectrum
    // ===================================
    vec3 rainbow = 0.5 + 0.5 * cos(time * 3.0 + uv.xyx * 4.0 + vec3(0.0, 2.0, 4.0));

    // ===================================
    // 4. Color Multiplication
    // ===================================
    vec3 finalColor = vec3(gray) * rainbow * 1.75;

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