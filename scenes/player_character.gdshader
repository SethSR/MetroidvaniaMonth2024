shader_type canvas_item;

uniform vec2 speed = vec2(0.0);
uniform vec2 offset = vec2(0.0);

void vertex() {
	UV = (VERTEX + offset + TIME * speed) * TEXTURE_PIXEL_SIZE;
}

void fragment() {
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
