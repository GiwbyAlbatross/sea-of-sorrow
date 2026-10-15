shader_type canvas_item;
//render_mode unshaded;

#define logn(x) log(x) / log(50)
// log10(x) = (1 / log(10)) * log(x)

//in float TIME;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
uniform sampler2D reflectionnormals: filter_linear_mipmap; // should basically just be an ordinary *perlin* normal map for 3D
uniform float offset = 0;
uniform float scale: hint_range(0.05, 2.0, 0.01) = 1.0;
uniform float wave_amount: hint_range(0.0, 0.05, 0.0001);
uniform float speed: hint_range(-0.2, 0.2, 0.0001) = 0.025;
uniform float lod_level = 1.0;
uniform float color_affect: hint_range(0.0, 1.0, 0.0001) = 1.0;
uniform float reflect_refract_ratio: hint_range(0.0, 1.0, 0.0001) = 0.5;

uniform vec3 surface_colour = vec3(0.5, 0.7, 0.8);

varying float screen_baseY;

void vertex() {
	// from godotshaders.com
    // uv to screen_uv for getting top screen_uv.y when uv.y==0
    // firstly uv to local then local to screen_uv, local coordinate is center based so we should convert (0,1) to (-1, 1) mulity with pixels distance
	mat4 t = mat4(vec4(2.0, 0, 0, 0), vec4(0, 2.0, 0, 0), vec4(0, 0, 1.0, 0), vec4(-1.0, -1.0, 0, 1.0));
	screen_baseY = (inverse(t)*SCREEN_MATRIX*CANVAS_MATRIX * (MODEL_MATRIX)*vec4(-1.0/TEXTURE_PIXEL_SIZE.x/2.0,  -1.0/TEXTURE_PIXEL_SIZE.y/2.0, 0, 1.0)).y;
}

void fragment() {
	vec2 uv =  SCREEN_UV;
	//vec2 uv2 = SCREEN_UV;
	uv.y -= screen_baseY;
	uv.y *= scale;
	uv.y += screen_baseY;

	vec2 t = (texture(reflectionnormals, fract(vec2(UV.x + TIME*speed, UV.y * 2.2))).xz);
	uv += vec2(t.x - 0.5, t.y) * 2.0 * wave_amount * UV;
	uv = vec2(uv.x, (screen_baseY*2.0- (uv.y-offset)));

	float nearsurface = clamp(sqrt((UV.y + t.y*wave_amount)/0.1), 0.0, 1.0);
	vec4 reflection = mix(
		textureLod(
			SCREEN_TEXTURE,
			uv, lod_level),
		COLOR,
		color_affect
	); //clamp(1.0 - (uv.y), 0.2, 1.0) * color_affect);

	/* UNUSED
	uv2.y -= screen_baseY;
	uv2.y *= -4.4 * (UV.y - 0.02);

	uv2 += vec2(t.x - 0.5, t.y) * wave_amount * 0.15;

	uv2.y = abs(uv2.y);
	uv2.y += screen_baseY;
	*/


	vec4 refraction = mix(
		texture(
			SCREEN_TEXTURE,
			SCREEN_UV + vec2(t.x - 0.5, t.y) * wave_amount * 0.15 // refractive waves
		),
		COLOR, color_affect);

	COLOR = mix(refraction, reflection, reflect_refract_ratio * uv.y);

	COLOR.rgb = mix(surface_colour, COLOR.rgb, nearsurface);

	COLOR.a = 1.0 - pow(UV.y, 2.0);
	//COLOR.r = nearsurface;
}
