extends Control
## Manual testing scene that compares a delta-based stopwatch vs a timestamp-based stopwatch


# delay values for frame lag simulation
var lower_delay: int = 150  # in ms
var upper_delay: int = 200  # in ms


@export_group("Node Exports")
@export var timestamp_stopwatch_label: Label
@export var delta_stopwatch_label: Label
@export var difference_label: Label

@export var timestamp_stopwatch: TimestampStopwatch
@export var delta_stopwatch: DeltaStopwatch


var induce_lag := false


func _process(delta: float) -> void:
	# Display the current stopwatch values in milliseconds
	timestamp_stopwatch_label.text = "Timestamp stopwatch time: " + str(timestamp_stopwatch.total_time_msec) + " ms"
	delta_stopwatch_label.text = "Delta stopwatch time: " + str(delta_stopwatch.accumulated_time_msec) + " ms"
	difference_label.text = "Difference: " + str(delta_stopwatch.accumulated_time_msec - timestamp_stopwatch.total_time_msec) + " ms"
	
	if induce_lag:
		OS.delay_msec(randi_range(lower_delay, upper_delay))   # Adds a random delay in this range each frame to simulate lag


func _on_start_button_pressed() -> void:
	timestamp_stopwatch.start()
	delta_stopwatch.start()


func _on_stop_button_pressed() -> void:
	timestamp_stopwatch.stop()
	delta_stopwatch.stop()


func _on_reset_button_pressed() -> void:
	timestamp_stopwatch.reset()
	delta_stopwatch.reset()


func _on_toggle_frame_lag_button_toggled(toggled_on: bool) -> void:
	induce_lag = toggled_on


func _on_lower_delay_line_edit_text_changed(new_text: String) -> void:
	if new_text.is_valid_int():
		lower_delay = new_text.to_int()
	elif new_text.is_valid_float():
		lower_delay = floor(new_text.to_float())


func _on_upper_delay_line_edit_text_changed(new_text: String) -> void:
	if new_text.is_valid_int():
		upper_delay = new_text.to_int()
	elif new_text.is_valid_float():
		upper_delay = floor(new_text.to_float())
