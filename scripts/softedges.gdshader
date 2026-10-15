shader_type canvas_item;
render_mode blend_mix;

uniform float soft_edge_size: hint_range(0.0, 0.5, 0.001) = 0.1;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float x = pow((UV.x-0.5)*2.0, 2.0);
	float y = pow((UV.y-0.5)*2.0, 2.0);
	COLOR.a *= (1.0 - soft_edge_size) - mix(x,y,0.5);
	//COLOR.a = 1.0;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
