extends Node
class_name ServiceLocator

var services: Dictionary = {}

func register(name: StringName, service: Object) -> void:
	services[name] = service

func resolve(name: StringName) -> Object:
	return services.get(name)

func unregister(name: StringName) -> void:
	services.erase(name)
