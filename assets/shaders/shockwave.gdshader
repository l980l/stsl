shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float strength : hint_range(0.0, 0.15) = 0.05;
uniform float thickness : hint_range(0.0, 0.5) = 0.03;
uniform vec2 center = vec2(0.5, 0.5);
uniform float aspect_ratio = 1.777;
uniform float max_progress = 0.15;

void fragment() {
	vec2 dir = SCREEN_UV - center;
	dir.x *= aspect_ratio;
	float dist = length(dir);
	dir.x /= aspect_ratio;

	// 비대칭 프로파일: 앞날은 날카롭게, 뒷날은 부드럽게 페이드
	float leading = 1.0 - smoothstep(progress - thickness * 0.2, progress, dist);
	float trailing = smoothstep(progress - thickness, progress - thickness * 0.5, dist);
	float ring = leading * trailing;

	float fade = clamp(1.0 - (progress / max_progress), 0.0, 1.0);

	// 화면 왜곡
	vec2 offset = normalize(dir + vec2(0.0001)) * ring * strength * fade;
	vec3 distorted = texture(screen_tex, SCREEN_UV + offset).rgb;

	// 가시적인 림 글로우 (흰->청백 그라디언트)
	float rim = ring * fade * fade * 6.0;
	vec3 rim_color = mix(vec3(0.5, 0.75, 1.0), vec3(1.0, 1.0, 1.0), leading) * rim;

	COLOR = vec4(distorted + rim_color, 1.0);
}
