extends RefCounted
class_name DifficultyManager

var difficulty: float = 0.0
var stage: int = 1

func reset() -> void:
	difficulty = 0.0
	stage = 1

func update(elapsed_seconds: float) -> void:
	difficulty = clampf(elapsed_seconds / 72.0, 0.0, 1.0)
	stage = 1 + int(floor(elapsed_seconds / 24.0))

func rival_speed_multiplier(rival_index: int) -> float:
	var personality: float = float([0.94, 0.98, 1.02, 0.96][posmod(rival_index, 4)])
	return personality + difficulty * 0.075
