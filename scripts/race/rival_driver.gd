extends Racer
class_name RivalDriver

var rival_index: int = 0
var _phase: float = 0.0
var _base_speed: float = 0.0
var _base_lane: float = 0.0

func _ready() -> void:
	super._ready()
	is_player = false

func configure_rival(track_ref: RaceTrack, style: int, index: int, lane: float, start_speed_kmh: float, start_progress_m: float = 0.0) -> void:
	rival_index = index
	_base_lane = lane
	_phase = float(index) * 1.73
	configure(track_ref, style, start_progress_m, lane, start_speed_kmh)
	total_distance_m = maxf(0.0, start_progress_m)
	_base_speed = top_speed_mps * (0.77 + float(index % 3) * 0.015)

func tick_ai(delta: float, race_time: float, difficulty: float) -> void:
	var lane_target := _base_lane + sin(race_time * (0.45 + float(rival_index) * 0.035) + _phase) * 1.15
	var speed_wave := sin(race_time * 0.17 + _phase) * 1.8
	var speed_target := minf(top_speed_mps * 0.96, _base_speed + speed_wave + difficulty * top_speed_mps * 0.08)
	advance_ai(delta, speed_target, lane_target)
