shader_type canvas_item;
render_mode unshaded;

uniform sampler2D gradient: hint_default_white;
uniform float alpha_factor=1.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	COLOR.a = COLOR.r*alpha_factor;
	COLOR.rgb = texture(gradient, COLOR.rg).rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
