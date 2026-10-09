package shaders;

import flixel.system.FlxAssets.FlxShader;

class VHSShader extends FlxShader
{
    @:glFragmentSource('
        #pragma header
        
        uniform float uTime;

        // Generates pseudo-random static noise
        float rand(vec2 co) 
        {
            return fract(sin(dot(co.xy ,vec2(12.9898, 78.233))) * 43758.5453);
        }

        void main()
        {
            vec2 uv = openfl_TextureCoordv;
            
            // 1. Tape Tracking & Wobble Distortion
            // float wobble = sin(uv.y * 50.0 + uTime * 2.0) * 0.001;
            // float tracking = (sin(uv.y * 10.0 + uTime * 15.0) > 0.95) ? 0.015 : 0.0;
            // uv.x += wobble + tracking;

            // 2. Chromatic Aberration (RGB Color Bleed)
            float r = flixel_texture2D(bitmap, vec2(uv.x + 0.001, uv.y)).r;
            float g = flixel_texture2D(bitmap, uv).g;
            float b = flixel_texture2D(bitmap, vec2(uv.x - 0.001, uv.y)).b;
            float a = flixel_texture2D(bitmap, uv).a;

            vec3 color = vec3(r, g, b);

            // 3. Horizontal CRT Scanlines
            color -= sin(uv.y * 600.0) * 0.04;

            // 4. Granny / Static TV Noise
            // We multiply uv by uTime so the static changes every frame
            float noise = rand(uv * uTime) * 0.02;
            color += noise;

            gl_FragColor = vec4(color, a);
        }
    ')

    public function new()
    {
        super();
        // Initialize the time uniform as an array of 1 float
        uTime.value = [0.0]; 
    }

    public function update(elapsed:Float):Void
    {
        // Increment the shader time to animate the noise and wobble
        uTime.value[0] += elapsed;
    }
}