shader_type canvas_item;
// 화면을 회색조로 변환 — counter major freeze postprocess.
// Godot 4 — SCREEN_TEXTURE 키워드 폐기됨. hint_screen_texture uniform 으로 받아야 함.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec4 c = textureLod(screen_tex, SCREEN_UV, 0.0);
    float gray = dot(c.rgb, vec3(0.299, 0.587, 0.114));
    vec3 mixed = mix(c.rgb, vec3(gray), strength) * tint.rgb;
    COLOR = vec4(mixed, 1.0);
}
