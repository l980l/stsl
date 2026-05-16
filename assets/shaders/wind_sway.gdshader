// 바람 sway — UV.y 작을수록(위쪽) 더 많이 흔들림. 줄기/발은 정지, 잎/꽃은 움직임.
shader_type canvas_item;

uniform float amplitude = 4.0;  // 최대 변위 (local pixel)
uniform float speed = 1.0;
uniform float phase = 0.0;

void vertex() {
	float sway = sin(TIME * speed + phase) * amplitude * (1.0 - UV.y);
	VERTEX.x += sway;
}
