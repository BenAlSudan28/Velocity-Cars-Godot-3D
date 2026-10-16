extends RefCounted
class_name ScoreSystem

var score: int = 0
var pickup_count: int = 0
var collision_count: int = 0
var near_miss_count: int = 0
var distance_m: float = 0.0
var pickup_score: int = 0

func reset() -> void:
	score = 0
	pickup_count = 0
	collision_count = 0
	near_miss_count = 0
	distance_m = 0.0
	pickup_score = 0

func add_pickup(value: int = RaceConfig.PICKUP_SCORE) -> void:
	pickup_count += 1
	pickup_score += value
	_recalculate()

func add_collision() -> void:
	collision_count += 1
	_recalculate()

func add_near_miss() -> void:
	near_miss_count += 1
	_recalculate()

func update_distance(distance_m: float) -> void:
	self.distance_m = maxf(0.0, distance_m)
	_recalculate()

func _recalculate() -> void:
	var distance_score := roundi(distance_m * RaceConfig.DISTANCE_SCORE_PER_METER)
	score = maxi(0, distance_score + pickup_score + near_miss_count * 45 - collision_count * RaceConfig.COLLISION_PENALTY)
