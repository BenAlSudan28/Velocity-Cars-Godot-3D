extends RefCounted
class_name RaceMaterials

const ASPHALT_SHADER: Shader = preload("res://shaders/asphalt.gdshader")

static func surface(color: Color, roughness: float = 0.72, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

static func glow(color: Color, energy: float = 1.3) -> StandardMaterial3D:
	var material := surface(color, 0.28, 0.12)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material

static func painted_road(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = ASPHALT_SHADER
	material.set_shader_parameter("base_color", color)
	return material
