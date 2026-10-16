extends RefCounted
class_name CollisionManager

static func resolve_racer_contacts(player: PlayerDriver, rivals: Array[RivalDriver], track_length: float) -> bool:
	if player == null or not player.can_collide():
		return false
	for rival in rivals:
		if rival == null or not rival.can_collide():
			continue
		var longitudinal_gap := RouteMath.wrapped_distance(player.progress_m, rival.progress_m, track_length)
		var lateral_gap := absf(player.lane_offset - rival.lane_offset)
		if longitudinal_gap < RaceConfig.COLLISION_GAP_METERS and lateral_gap < RaceConfig.COLLISION_LATERAL_METERS:
			player.register_collision()
			rival.register_collision()
			return true
	return false

static func overlaps_track_object(progress_m: float, lane_offset: float, object_progress_m: float, object_lane: float, track_length: float, longitudinal_radius: float = 2.8, lateral_radius: float = 1.65) -> bool:
	return RouteMath.wrapped_distance(progress_m, object_progress_m, track_length) <= longitudinal_radius and absf(lane_offset - object_lane) <= lateral_radius
