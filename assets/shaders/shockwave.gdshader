shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float strength : hint_range(0.0, 0.15) = 0.05;
uniform float thickness : hint_range(0.0, 0.5) = 0.18;
uniform vec2 center = vec2(0.5, 0.5);

void fragment() {
	vec2 dir = SCREEN_UV - center;
	float dist = length(dir);
	float ring = smoothstep(progress - thickness, progress, dist)
			   * smoothstep(progress + thickness, progress, dist);
	vec2 offset = normalize(dir + vec2(0.0001)) * ring * strength * (1.0 - progress);
	COLOR = texture(screen_tex, SCREEN_UV + offset);
}
