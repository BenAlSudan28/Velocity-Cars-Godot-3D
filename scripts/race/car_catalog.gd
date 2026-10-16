extends RefCounted
class_name CarCatalog

const CARS: Array[Dictionary] = [
	{
			"name": "AERION GT-R",
			"subtitle": "كوبيه رياضية أنيقة",
			"model": "res://assets/race/models/AerionGT.glb",
			"top_speed_kmh": 322.0,
			"acceleration": 27.0,
			"handling": 1.10,
			"paint": "#d64356",
			"scale": 1.0,
			"yaw_degrees": 90.0
	},
	{
			"name": "VORTEX SV-X",
			"subtitle": "هايبركار حادة وسريعة",
			"model": "res://assets/race/models/VortexSVX.glb",
			"top_speed_kmh": 344.0,
			"acceleration": 30.0,
			"handling": 0.96,
			"paint": "#ef7d2b",
			"scale": 1.0,
			"yaw_degrees": 90.0
	},
	{
			"name": "TERRA RALLY S",
			"subtitle": "كوبيه أداء متوازنة",
			"model": "res://assets/race/models/TerraRallyS.glb",
			"top_speed_kmh": 305.0,
			"acceleration": 25.0,
			"handling": 1.22,
			"paint": "#238ab8",
			"scale": 1.0,
			"yaw_degrees": 90.0
	}
]

static func count() -> int:
	return CARS.size()

static func get_car(index: int) -> Dictionary:
	return CARS[posmod(index, CARS.size())]
