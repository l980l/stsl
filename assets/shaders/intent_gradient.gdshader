// 인텐트/시그니처/승패 아이콘 — 2색 세로 그라데이션(흰색 SVG 알파 = 글리프·링). 배경 원반은 별도 노드(_disc_icon).
shader_type canvas_item;

uniform vec4 grad_top : source_color = vec4(1.0);
uniform vec4 grad_bot : source_color = vec4(1.0);

void fragment() {
	float a = texture(TEXTURE, UV).a;
	vec3 c = mix(grad_top.rgb, grad_bot.rgb, clamp(UV.y, 0.0, 1.0));
	COLOR = vec4(c, a) * COLOR;  // 입력 COLOR = 노드 modulate(틴트·페이드) 보존
}
