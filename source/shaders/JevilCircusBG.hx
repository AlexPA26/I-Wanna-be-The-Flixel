package shaders;

import flixel.system.FlxAssets.FlxShader;

class JevilCircusBG extends FlxShader
{

	public function new()
	{
		super();

		data.time.value = [0.0];
		data.tint.value = [0.075, 0.08, 0.25];
	}

@:glFragmentSource('
#pragma header

uniform float time;
uniform vec3 tint;

void main()
{
    vec2 uv = openfl_TextureCoordv;

    // ==========================
    // Reverse fisheye
    // ==========================

    vec2 p = uv - 0.5;

    float strength = -4;
    float r = length(p);

    p *= 1.0 + strength * pow(r, 4.0);

    uv = p + 0.5;

    // ==========================
    // EarthBound row stretching
    // ==========================

    float row = floor(uv.y * 32.0);

    float rowScale = 1.0 +
        sin(row * 0.22 + time * 3.5) * 0.60;

    uv.x = 0.5 + (uv.x - 0.5) * rowScale;

    // ==========================
    // Row wobble
    // ==========================

    uv.x += sin(row * 0.13 + time * 5.0) * 0.04;

    // ==========================
    // Vertical wave
    // ==========================

    uv.y += sin(uv.x * 15.0 + time * 8.0) * 0.05;

    // ==========================
    // Pixel wobble
    // ==========================

    uv += vec2(
        sin(uv.y * 140.0 + time * 18.0),
        cos(uv.x * 120.0 + time * 16.0)
    ) * 0.002;

    // ==========================
    // Rotate panorama (Moved to the end)
    // ==========================

    uv.x += time;

    // ==========================
    // Wrap X
    // ==========================

    uv.x = fract(uv.x);

    // ==========================
    // Sample texture
    // ==========================

    vec4 color = flixel_texture2D(bitmap, uv);
    color.rgb *= tint;

    gl_FragColor = color;
}
')
	public var speed:Float = 0.1;

	public function update(elapsed:Float)
	{
		this.data.time.value = [this.data.time.value[0] + elapsed * speed];
	}
}
