shader_type canvas_item;

uniform float brightness;
uniform vec3 color;

void fragment(){
	vec4 tex = texture(TEXTURE, UV);
	vec3 grayscale = vec3(dot(tex.rgb, vec3(brightness)));
	COLOR = vec4(grayscale * color, tex.a);
}


