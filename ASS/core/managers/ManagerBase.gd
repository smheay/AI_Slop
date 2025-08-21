extends Node
class_name ManagerBase

signal initialized()
signal shutdown()

var _is_initialized := false

func initialize() -> void:
	# TODO: Initialize resources/services
	_is_initialized = true
	emit_signal("initialized")

func teardown() -> void:
	# TODO: Release resources
	_is_initialized = false
	emit_signal("shutdown")


