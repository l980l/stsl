// 아이콘 외곽 글로우 셰이더 — 7×7 박스 블러 + additive 블렌드.
// 호버 시 button 뒤 glow_rect 에 적용해 화살표/아이콘 형태 따라 황금 빛이 퍼지는 효과.
shader_type canvas_item;
render_mode blend_add;

uniform float blur_radius: hint_range(0.0, 12.0) = 5.0;
uniform vec4 glow_tint: source_color = vec4(1.0, 0.85, 0.45, 1.0);

void fragment() {
	vec4 acc = vec4(0.0);
	float total = 0.0;
	for (int x = -3; x <= 3; x++) {
		for (int y = -3; y <= 3; y++) {
			vec2 off = vec2(float(x), float(y)) * blur_radius * TEXTURE_PIXEL_SIZE;
			acc += texture(TEXTURE, UV + off);
			total += 1.0;
		}
	}
	vec4 blurred = acc / total;
	COLOR = vec4(glow_tint.rgb, blurred.a * COLOR.a) * blurred.a;
}
