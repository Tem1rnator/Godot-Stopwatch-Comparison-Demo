extends Node2D
class_name DeltaStopwatch
## Delta-based stopwatch approach: using delta time accumulated via _process()
## Subject to inaccuracies if framerate drops significantly.


var is_running := false

var accumulated_time_msec: float = 0   # in milliseconds


func _process(delta: float) -> void:
	if is_running:
		accumulated_time_msec += delta * 1000   # converting delta to milliseconds


func start() -> void:
	is_running = true


func stop() -> void:
	is_running = false


func reset() -> void:
	accumulated_time_msec = 0
