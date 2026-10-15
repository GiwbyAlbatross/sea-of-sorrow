shader_type canvas_item;

uniform sampler2D perlin;
uniform float threshold: hint_range(0.0, 1.0, 0.001);

void fragment() {
	//COLOR = texture(perlin, UV);
	COLOR.rgb = vec3(1.0 -
		pow(
			abs(
				threshold-texture(perlin, UV).r
				),
				1. / 10.1
			) * 1.5
		);
}
