extends RefCounted
class_name RaceConfig

const LAP_COUNT: int = 3
const TRACK_WIDTH: float = 18.0
const PICKUP_SCORE: int = 180
const COLLISION_PENALTY: int = 80
const DISTANCE_SCORE_PER_METER: float = 3.0
const PLAYER_LATERAL_LIMIT: float = 6.7
const NITRO_CAPACITY: float = 100.0
const NITRO_DRAIN_PER_SECOND: float = 28.0
const NITRO_RECHARGE_PER_SECOND: float = 7.0
const COLLISION_GAP_METERS: float = 4.5
const COLLISION_LATERAL_METERS: float = 2.35
const RACE_RIVAL_COUNT: int = 4

static func format_kmh(speed_mps: float) -> String:
	return "%03d" % roundi(speed_mps * 3.6)

static func format_distance(meters: float) -> String:
	if meters >= 1000.0:
		return "%.2f كم" % (meters / 1000.0)
	return "%d م" % roundi(meters)
