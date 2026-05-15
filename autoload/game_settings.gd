# autoload/game_settings.gd
# 게임 속도 / 그래픽 옵션 — 향후 settings_overlay 의 graphics·gameplay 탭에서 조정.
# 이번 단계는 hook 만 — default 값 = 기존 동작 유지. UI/save·load 는 추후 PR.
#
# 의도된 옵션 단계 (UI 연결 시):
#   vfx_speed_multiplier:
#     아주빠르게=0.5, 빠르게=0.75, 보통=1.0(default), 느리게=1.5
#   monster_interval_multiplier (battle_manager.turn_interval 배수):
#     아주빠르게=0.5, 빠르게=1.0(default), 보통=1.5, 느리게=2.0
#   anim_speed_multiplier (AnimationPlayer.speed_scale):
#     아주빠르게=1.5, 빠르게=1.0(default), 보통=0.7, 느리게=0.5
#   particle_quality:
#     하=0, 중=1, 상=2(default)
extends Node

var vfx_speed_multiplier: float = 1.0
var monster_interval_multiplier: float = 1.0
var anim_speed_multiplier: float = 1.0
var particle_quality: int = 2

const _PARTICLE_SCALES := [0.25, 0.5, 1.0]

# VFX 차지·비행 시간에 적용 — battle_manager 의 _execute_intent await 시
func get_vfx_delay(base: float) -> float:
	return base * vfx_speed_multiplier

# 적 인텐트 사이 인터벌 (turn_interval) 배수
func get_monster_interval(base: float) -> float:
	return base * monster_interval_multiplier

# AnimationPlayer.speed_scale 에 직접 대입
func get_anim_scale() -> float:
	return anim_speed_multiplier

# 파티클 spawn 갯수 곱셈 — VFX 의 burst/ambient 카운트에 적용
func particle_count_scale() -> float:
	return _PARTICLE_SCALES[particle_quality]
