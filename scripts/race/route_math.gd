extends RefCounted
class_name RouteMath

static func catmull_rom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)

static func wrapped_distance(a: float, b: float, loop_length: float) -> float:
	if loop_length <= 0.001:
		return absf(a - b)
	var gap := absf(fposmod(a - b, loop_length))
	return minf(gap, loop_length - gap)

static func wrap_distance(distance: float, loop_length: float) -> float:
	if loop_length <= 0.001:
		return 0.0
	return fposmod(distance, loop_length)
