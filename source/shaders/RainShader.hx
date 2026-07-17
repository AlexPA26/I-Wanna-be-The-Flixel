package shaders;

import flixel.system.FlxAssets.FlxShader;

class RainShader extends FlxShader
{
    @:glFragmentSource('
#pragma header

uniform float time;
uniform float desaturationAmount;

// Pseudo-random helper functions
float hash12(vec2 p)
{
    vec3 p3 = fract(p.xyx * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p)
{
    vec3 a = fract(p.xyx * vec3(123.34, 234.34, 345.65));
    a += dot(a, a + 34.45);
    return fract(vec2(a.x * a.y, a.y * a.z));
}

// -------------------------------------------------------------
// Stationary Micro-Droplet Generator (Stuck on Lens)
// Returns vec3(offsetX, offsetY, blurMask)
// -------------------------------------------------------------
vec4 getStationaryDrops(vec2 uv, float t)
{
    // High grid density = much smaller droplets
    vec2 gridScale = vec2(19.0, 19.0);
    vec2 st = uv * gridScale;
    vec2 id = floor(st);
    vec2 cellUv = fract(st) - 0.5;

    vec2 rand = hash22(id);

    // Only spawn droplets in ~40% of the grid cells
    if (rand.x < 0.2) return vec4(0.0);

    // Fixed center position inside its cell (does NOT fall)
    vec2 center = (rand - 0.5) * 0.6;
    vec2 p = cellUv - center;

    float dist = length(p);

    // Small droplet radius (varied per drop)
    float radius = 0.08 + rand.y * 0.08;

    // Lifetime from 0 to 1
    float speed = 0.15 + rand.x * 0.25;
    float life = fract(t * speed + rand.y);

    // Fade in
    float fadeIn = smoothstep(0.0, 0.15, life);

    // Fade out
    float fadeOut = 1.0 - smoothstep(0.75, 1.0, life);

    float fade = fadeIn * fadeOut;

    // Shape mask
    float shape = 1.0 - smoothstep(radius * 0.2, radius, dist);
    float dropMask = shape * fade;

    // Subtle 3D lens refraction
    vec2 norm = normalize(p + vec2(0.0001));
    vec2 offset = norm * dropMask * 0.018;

    // Specular highlight glisten
    vec3 lightDir = normalize(vec3(-0.4, 0.6, 0.7));
    vec3 dropNormal = normalize(vec3(p.x * dropMask, p.y * dropMask, 0.1));
    float spec = pow(max(0.0, dot(dropNormal, lightDir)), 10.0) * dropMask * 1.2;

    return vec4(offset.x, offset.y, dropMask, spec);
}

// Micro Condensation Layer (Fine mist beads)
float getMicroMist(vec2 uv)
{
    vec2 st = uv * vec2(50.0, 25.0);
    vec2 id = floor(st);
    vec2 cell = fract(st) - 0.5;
    
    float rand = hash12(id);
    if (rand < 0.70) return 0.0;

    float d = length(cell);
    return (1.0 - smoothstep(0.02, 0.2, d)) * 0.35;
}

void main()
{
    vec2 uv = openfl_TextureCoordv;

    // 1. Calculate Stationary Lens Droplets & Micro Mist
    vec4 dropData = getStationaryDrops(uv, time);
    vec2 dropOffset = dropData.xy;
    float dropMask = dropData.z;
    float specHighlight = dropData.w;

    float mist = getMicroMist(uv);
    dropMask = max(dropMask, mist * 0.4);

    vec2 waterUv = uv - dropOffset;

    // 2. Sample Texture with Localized Liquid Blur inside small droplets
    vec4 col;
    if (dropMask > 0.01)
    {
        float blurRadius = 0.0025 * dropMask;
        vec4 s1 = flixel_texture2D(bitmap, waterUv + vec2( blurRadius,  blurRadius));
        vec4 s2 = flixel_texture2D(bitmap, waterUv + vec2(-blurRadius,  blurRadius));
        vec4 s3 = flixel_texture2D(bitmap, waterUv + vec2( blurRadius, -blurRadius));
        vec4 s4 = flixel_texture2D(bitmap, waterUv + vec2(-blurRadius, -blurRadius));
        col = (s1 + s2 + s3 + s4) * 0.25;
    }
    else
    {
        col = flixel_texture2D(bitmap, waterUv);
    }

    // 3. Add Specular Highlights on Droplet Rims
    col.rgb += vec3(0.85, 0.95, 1.0) * specHighlight;

    // 4. Lower Saturation
    float gray = dot(col.rgb, vec3(0.4, 0.6, 0.2));
    vec3 color = mix(col.rgb, vec3(gray), desaturationAmount);

    // 5. Grim Cold Color Tint
    vec3 coldTint = vec3(1, 1, 1.1);
    color *= coldTint;

    // 6. Contrast Shift (Crush shadows)
    color = pow(color, vec3(1.15));

    // 7. Camera Lens Vignette
    float dist = length(uv - vec2(0.5));
    float vignette = smoothstep(0.85, 0.15, dist);
    color *= vignette;

    gl_FragColor = vec4(color, col.a);
}
')

    public function new(desat:Float = 0.2)
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