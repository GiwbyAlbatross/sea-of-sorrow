shader_type canvas_item;
render_mode unshaded;

uniform sampler2D scr: hint_screen_texture, filter_linear_mipmap;
uniform float desat: hint_range(0.0, 1.0, 0.001);

uniform float bloomThreshold: hint_range(0.0, 2.0, 0.001) = 1.0;
uniform float bloom_radius = 4.0;
uniform float bloomIntensity=1.0;
uniform float bloom2ratio=4.0;

//uniform float dreamyness: hint_range(0.0, 1.0, 0.001);

uniform float bloom_lod_level;

// stolen from https://godotshaders.com/shader/bloom-post-processing-for-viewports/
vec3 GetBloomPixel(sampler2D tex, vec2 uv, vec2 texPixelSize) {
	vec2 uv2 = floor(uv / texPixelSize) * texPixelSize;
	uv2 += texPixelSize * .001;
	vec3 tl = max(textureLod(tex, uv2, bloom_lod_level).rgb - bloomThreshold, 0.0);
	vec3 tr = max(textureLod(tex, uv2 + vec2(texPixelSize.x, 0.0), bloom_lod_level).rgb - bloomThreshold, 0.0);
	vec3 bl = max(textureLod(tex, uv2 + vec2(0.0, texPixelSize.y), bloom_lod_level).rgb - bloomThreshold, 0.0);
	vec3 br = max(textureLod(tex, uv2 + vec2(texPixelSize.x, texPixelSize.y), bloom_lod_level).rgb - bloomThreshold, 0.0);
	vec2 f = fract( uv / texPixelSize );

	vec3 tA = mix( tl, tr, f.x );
	vec3 tB = mix( bl, br, f.x );

	return mix( tA, tB, f.y );
}
vec3 GetBloom(sampler2D tex, vec2 uv, vec2 texPixelSize, float bloomRadius) {
	vec3 bloom = vec3(0.0);
	vec2 off = vec2(1) * texPixelSize * bloomRadius;
	bloom += GetBloomPixel(tex, uv + off * vec2(-1, -1), texPixelSize * bloomRadius) * 0.292893;
	bloom += GetBloomPixel(tex, uv + off * vec2(-1, 0), texPixelSize * bloomRadius) * 0.5;
	bloom += GetBloomPixel(tex, uv + off * vec2(-1, 1), texPixelSize * bloomRadius) * 0.292893;
	bloom += GetBloomPixel(tex, uv + off * vec2(0, -1), texPixelSize * bloomRadius) * 0.5;
	bloom += GetBloomPixel(tex, uv + off * vec2(0, 0), texPixelSize * bloomRadius) * 1.0;
	bloom += GetBloomPixel(tex, uv + off * vec2(0, 1), texPixelSize * bloomRadius) * 0.5;
	bloom += GetBloomPixel(tex, uv + off * vec2(1, -1), texPixelSize * bloomRadius) * 0.292893;
	bloom += GetBloomPixel(tex, uv + off * vec2(1, 0), texPixelSize * bloomRadius) * 0.5;
	bloom += GetBloomPixel(tex, uv + off * vec2(1, 1), texPixelSize * bloomRadius) * 0.292893;
	bloom /= 4.171573f;
	return bloom;
}

void fragment() {
	vec3 colour = texture(scr, SCREEN_UV).rgb;

	float lumi = length(colour) / 1.8;
	vec3 tone = vec3(lumi);


	vec3 bloom1 = GetBloom(scr, SCREEN_UV, SCREEN_PIXEL_SIZE, bloom_radius);
	vec3 bloom2 = GetBloom(scr, SCREEN_UV, SCREEN_PIXEL_SIZE, bloom_radius * bloom2ratio);
	colour.rgb += bloom1 * bloomIntensity;
	colour.rgb += bloom2 * bloomIntensity / sqrt(bloom2ratio);

	colour = mix(colour, tone, desat);

	COLOR.rgb = colour;
}
