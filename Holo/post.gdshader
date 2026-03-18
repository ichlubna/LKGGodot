shader_type spatial;
render_mode unshaded, fog_disabled;
uniform sampler2D screen_tex : hint_screen_texture;
uniform sampler2D depth_tex : hint_depth_texture;

void vertex() {
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
    vec4 color = texture(screen_tex, SCREEN_UV);
	float depth = texture(depth_tex, SCREEN_UV).r;
	color.rgb = vec3(depth);
    ALBEDO.rgb = color.rgb;
	
}