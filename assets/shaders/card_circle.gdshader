// 카드 cost circle / rarity gem 전용 셰이더.
// 정확한 원형 + 좌상단 off-center highlight + 외곽 ring + anti-alias edge.
// ColorRect 위에 적용. uniform default 제거 — _build() 에서 set_shader_parameter 로 모두 명시.
shader_type canvas_item;

uniform vec4 hi_color: source_color;
uniform vec4 mid_color: source_color;
uniform vec4 lo_color: source_color;
uniform vec4 ring_color: source_color;
uniform vec2 highlight_pos;
uniform float ring_width;
uniform float aa_edge;

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	float d_center = distance(UV, center);

	if (d_center > 0.5) {
		COLOR = vec4(0.0);
		return;
	}

	float edge_alpha = smoothstep(0.5, 0.5 - aa_edge, d_center);

	float inner_edge = 0.5 - ring_width;
	if (d_center > inner_edge) {
		COLOR = vec4(ring_color.rgb, ring_color.a * edge_alpha);
		return;
	}

	float d_hi = distance(UV, highlight_pos);
	float max_d = inner_edge + distance(highlight_pos, center);
	float t = clamp(d_hi / max_d, 0.0, 1.0);

	vec3 col;
	if (t < 0.5) {
		col = mix(hi_color.rgb, mid_color.rgb, t / 0.5);
	} else {
		col = mix(mid_color.rgb, lo_color.rgb, (t - 0.5) / 0.5);
	}

	COLOR = vec4(col, edge_alpha);
}
