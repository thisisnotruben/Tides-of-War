shader_type canvas_item;

uniform vec2 region;

void fragment(){
	vec4 tex = texture(TEXTURE, UV);
	vec3 color = vec3(0.0);
	vec2 tex_size = vec2(textureSize(TEXTURE, 0));
	vec2 xy = vec2(region.x, region.y + 0.0) / tex_size, wh = vec2(region.x + 16.0 , region.y + 16.0) / tex_size;
	float x = step(xy.x, UV.x), y = step(xy.y, UV.y), w = step(1.0 - wh.x, 1.0 - UV.x), h = step(1.0 - wh.y, 1.0 - UV.y);
	color = vec3(x * y * w * h);
	if (color == vec3(0.0)){
		COLOR = vec4(0.0);
	} else {
		COLOR = vec4(color * tex.rgb, tex.a);
	}
}