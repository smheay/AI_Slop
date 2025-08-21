extends Node
class_name Logger


signal log(message: String, level: String)

enum Level { DEBUG, INFO, WARN, ERROR }

func info(message: String) -> void:
	emit_signal("log", message, "INFO")

func warn(message: String) -> void:
	emit_signal("log", message, "WARN")

func error(message: String) -> void:
	emit_signal("log", message, "ERROR")
