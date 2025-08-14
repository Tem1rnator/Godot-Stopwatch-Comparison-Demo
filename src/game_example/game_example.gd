extends Node2D

@export_group("Nodes Exports")
@export var timestamp_stopwatch: TimestampStopwatch
@export var delta_stopwatch: DeltaStopwatch

@export var without_lag_timestamp_label: Label
@export var without_lag_delta_label: Label

@export var with_lag_timestamp_label: Label
@export var with_lag_delta_label: Label

@export var lag_difference_timestamp_label: Label
@export var lag_difference_delta_label: Label

var is_lag_next_race := false
var is_lag_currently_on := false
var is_race_running := false

var without_lag_timestamp_saved_time := -1
var without_lag_delta_saved_time := -1
var with_lag_timestamp_saved_time := -1
var with_lag_delta_saved_time := -1


func _process(delta: float) -> void:
	if is_race_running:
		if is_lag_currently_on:
			with_lag_timestamp_label.text = str(round_to_nearest_hundredth(timestamp_stopwatch.get_total_time_msec())) + " ms"
			with_lag_delta_label.text = str(round_to_nearest_hundredth(delta_stopwatch.accumulated_time_msec)) + " ms"
		else:
			without_lag_timestamp_label.text = str(round_to_nearest_hundredth(timestamp_stopwatch.get_total_time_msec())) + " ms"
			without_lag_delta_label.text = str(round_to_nearest_hundredth(delta_stopwatch.accumulated_time_msec)) + " ms"
	
	if is_lag_currently_on:
		OS.delay_msec(230)
	
	#print(delta)


func _on_start_line_body_entered(body: Node2D) -> void:
	is_race_running = true
	
	if is_lag_next_race:
		is_lag_currently_on = true
	
	timestamp_stopwatch.reset()
	delta_stopwatch.reset()
	
	timestamp_stopwatch.start()
	delta_stopwatch.start()
	
	print("Started race!")


func _on_finish_line_body_entered(body: Node2D) -> void:
	if is_race_running:
		is_race_running = false
		
		if is_lag_currently_on:
			is_lag_currently_on = false
			
			with_lag_timestamp_saved_time = timestamp_stopwatch.get_total_time_msec()
			with_lag_delta_saved_time = delta_stopwatch.accumulated_time_msec
		else:
			without_lag_timestamp_saved_time = timestamp_stopwatch.get_total_time_msec()
			without_lag_delta_saved_time = delta_stopwatch.accumulated_time_msec
		
		delta_stopwatch.stop()
		timestamp_stopwatch.stop()
		
		if without_lag_timestamp_saved_time != -1 and with_lag_timestamp_saved_time != -1:    # ensuring both have been run before calculating difference
			lag_difference_timestamp_label.text = str(round_to_nearest_hundredth(with_lag_timestamp_saved_time - without_lag_timestamp_saved_time)) + " ms"
			lag_difference_delta_label.text = str(round_to_nearest_hundredth(with_lag_delta_saved_time - without_lag_delta_saved_time)) + " ms"
		
		print("Finished race!")


func round_to_nearest_hundredth(number: float) -> float:
	return roundf(number * 100) / 100


func _on_simulate_lag_check_button_toggled(toggled_on: bool) -> void:
	is_lag_next_race = toggled_on
