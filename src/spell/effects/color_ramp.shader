shader_type canvas_item;
render_mode unshaded;

uniform sampler2D gradient;
uniform float color_speed = 1.0;
uniform float scale_speed = 1.0;
uniform float energy = 1.0;
uniform vec2 scale;

void fragment(){
	vec3 color = texture(gradient, vec2(abs(sin(TIME * color_speed)), UV.y)).rgb;
	float alpha = texture(TEXTURE, UV).a * energy;
	COLOR = vec4(color, alpha);
}

void vertex(){
	float map = scale.x + abs(sin(TIME * scale_speed)) * (scale.y - scale.x);
	VERTEX *= vec2(map);
}



