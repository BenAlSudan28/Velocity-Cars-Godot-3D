extends RefCounted
class_name CityConfig

const ROAD_CENTERS: Array[float] = [-150.0, -75.0, 0.0, 75.0, 150.0]
const CITY_HALF_EXTENT: float = 188.0
const CITY_SPAN: float = CITY_HALF_EXTENT * 2.0
const ROAD_WIDTH: float = 24.0
const ROAD_HALF_WIDTH: float = ROAD_WIDTH * 0.5
const SIDEWALK_WIDTH: float = 2.8
const TRAFFIC_COUNT: int = 8

static func is_drivable_position(position: Vector3, edge_margin: float = 1.2) -> bool:
	if absf(position.x) > CITY_HALF_EXTENT or absf(position.z) > CITY_HALF_EXTENT:
		return false
	var driveable_half_width := ROAD_HALF_WIDTH - edge_margin
	for center_value in ROAD_CENTERS:
		var center := float(center_value)
		if absf(position.x - center) <= driveable_half_width or absf(position.z - center) <= driveable_half_width:
			return true
	return false
