extends Node
class_name TimestampStopwatch
## Timestamp-based stopwatch approach: using the Time singleton's timestamps (microsecond precision)
## usec = microseconds, msec = milliseconds


var is_running := false

var time_before_last_unpause_usec: int = 0
var last_unpause_timestamp_usec: int = 0

var total_time_msec: float = 0:   # in milliseconds
	get = get_total_time_msec



func start() -> void:
	is_running = true
	last_unpause_timestamp_usec = Time.get_ticks_usec()


func stop() -> void:
	if is_running:
		# Add elapsed time since last unpause - only if going from unpaused to paused state
		time_before_last_unpause_usec += Time.get_ticks_usec() - last_unpause_timestamp_usec
	
	is_running = false


func reset() -> void:
	time_before_last_unpause_usec = 0
	last_unpause_timestamp_usec = 0
	total_time_msec = 0


func get_total_time_msec() -> float:
	var time_before_last_unpause_msec: float = time_before_last_unpause_usec / 1000.0
	
	if is_running:
		var time_elapsed_since_last_unpause_usec: int = Time.get_ticks_usec() - last_unpause_timestamp_usec
		var time_elapsed_since_last_unpause_msec: float = time_elapsed_since_last_unpause_usec / 1000.0
		
		total_time_msec = time_before_last_unpause_msec + time_elapsed_since_last_unpause_msec
	else:
		total_time_msec = time_before_last_unpause_msec
	
	return total_time_msec
