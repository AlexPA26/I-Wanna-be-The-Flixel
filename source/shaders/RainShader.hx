package shaders;

import flixel.system.FlxAssets.FlxShader;

class RainShader extends FlxShader
{
    @:glFragmentSource('
#pragma header

uniform float time;
uniform float desaturationAmount;

void main()
{
    vec2 uv = openfl_TextureCoordv;

    vec4 col = flixel_texture2D(bitmap, uv);

    // 2. Lower Saturation (Convert RGB to Grayscale & Mix)
    float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    vec3 color = mix(col.rgb, vec3(gray), desaturationAmount);

    // 3. Grim Cold Color Tint (Slightly push blues/cyans, cool down reds)
    vec3 coldTint = vec3(0.85, 0.92, 1.05);
    color *= coldTint;

    // 4. Contrast Shift (Slightly crush shadows for a harsher grim look)
    color = pow(color, vec3(1.05));

    gl_FragColor = vec4(color, col.a);
}
')

    public function new(desat:Float = 0.65)
    {
        super();
        if (data != null)
        {
            if (data.time != null) data.time.value = [0.0];
            if (data.desaturationAmount != null) data.desaturationAmount.value = [desat];
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