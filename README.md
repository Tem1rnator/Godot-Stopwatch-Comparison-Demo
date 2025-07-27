# Godot Stopwatch Comparison Demo
*Central Problem: Why do some stopwatch implementations in Godot significantly deviate from real-world time when the framerate drops below ~7.5 FPS — losing anywhere from 3% to 60% of real time?*

This is a small demo project meant to bring light to the inaccuracy of a popular delta-based approach to implementing stopwatches in Godot and compare it to a preferred timestamp-based approach, particularly under low framerate conditions. This demo includes a testing scene comparing the two stopwatch approaches with adjustable lag simulation.

## Table of contents
1. [How To Run](#how-to-run)
2. [The Two Approaches](#the-two-approaches)
    1. [Delta-based Approach](#delta-based-approach)
    2. [Timestamp-based Approach](#timestamp-based-approach)
3. [Data and Testing](#data-and-testing)
4. [Conclusion](#conclusion)

 
## How To Run <a name="how-to-run"></a>
 1. Download or clone this repository
 2. Open this project in Godot 4
 3. Run the `manual_testing.tscn` scene
 4. Press "Start" button to start both stopwatches
 5. Press "Toggle Frame Lag Simulation" to impose simulated lag and observe the time difference between the stopwatches grow.
 6. Use the two `LineEdit` fields at the bottom of the screen to adjust the delay range for the lag simulation. Higher values in the range will increase lag and lower values will decrease lag. To see the stopwatches start to diverge, set the lower value in the range to at least ~140ms.

 

## The Two Approaches <a name="the-two-approaches"></a>

### Delta-based Approach <a name="delta-based-approach"></a>

Many Godot developers implement stopwatch functionality using a pattern similar to this:

```
var stopwatch_time := 0.0

func _process(delta: float):
	stopwatch_time += delta
```

This is the **delta-based approach**, but while this seems simple and intuitive, this approach to timekeeping is not exactly accurate, particularly when experiencing lag spikes. Even Godot's official documentation for Node's `_process()` method explicitly recommends against using `delta` for keeping time:

> **Note:** `delta` will be larger than expected if running at a framerate lower than `Engine.physics_ticks_per_second` / `Engine.max_physics_steps_per_frame` FPS. This is done to avoid "spiral of death" scenarios where performance would plummet due to an ever-increasing number of physics steps per frame. This behavior affects both `_process()` and `_physics_process()`. **As a result, avoid using `delta` for time measurements in real-world seconds**. Use the `Time` singleton's methods for this purpose instead, such as `Time.get_ticks_usec()`."

*What this means to you, the developer:* players who experience lag spikes that lower their framerate to 7.5 FPS or lower — even if the FPS drops only momentarily — will see stopwatches in their game significantly deviate from real-world time (deviation can vary wildly: potential 3-60% loss of time — more on that later in [Data and Testing](#data-and-testing) section). The 7.5 number comes from the equation: `Engine.physics_ticks_per_second / Engine.max_physics_steps_per_frame`, where the default values for these values in Project Settings are:
* `Engine.physics_ticks_per_second` = 60
* `Engine.max_physics_steps_per_frame` = 8

So the resulting equation with default settings is 60 / 8 = 7.5
These values can be found and changed under `Project` > `Project Settings` > `Physics (section)` > `Common (subsection)` > `Physics Ticks per Second` and `Max Physics Steps per Frame`

**IMPORTANT:** If you've changed these values in Project Settings, your game's FPS threshold for inaccurate stopwatches may be different — but it will still exist, as long as you use this delta-based approach to implement stopwatches.

Sidenote: exploring the inner workings of physics simulation, what the "spiral of death" is, and the reasoning behind unexpected `delta` values is outside the scope of this demo's README, but if you want to explore this further, I recommend other resources like this article on physics timestep: [Fix Your Timestep! | Gaffer On Games](https://gafferongames.com/post/fix_your_timestep/)


### Timestamp-based Approach <a name="timestamp-based-approach"></a>
The alternative (and preferred) approach to stopwatches is the **timestamp-based approach**. Here is an example of an oversimplified version of this approach (only tells you microseconds since start):
```
# usec = microseconds
var start_timestamp_usec := 0

func start():
	start_timestamp_usec = Time.get_ticks_usec()

func get_elapsed_time_usec() -> int:
	return Time.get_ticks_usec() - start_timestamp_usec
```

**Why is this the preferred approach to implementing stopwatches in Godot?**
Unlike the delta-based stopwatches, this approach doesn't rely on the faulty assumption that the `delta` parameter supplied by Godot to `_process()` or `_physics_process()` methods will always perfectly reflect real-world time when accumulated over many frames — that's not the case in reality, especially at low framerates as we already discussed above.

Instead, we save a "timestamp"  (i.e. the value returned by `Time.get_ticks_usec()`) at the starting moment and then subtract the current timestamp from the starting timestamp to get how many microseconds have elapsed since the start of the stopwatch. This time can then be converted to something more useful like milliseconds, seconds, minutes, etc. This approach ensures that low framerate will not affect the accuracy of stopwatches.

You can check out this project's `TimestampStopwatch` class for a slightly more complete example of how to implement a stopwatch using this approach that can be started/paused/unpaused/reset — though there are other, more complete and polished implementations available online.


## Data and Testing <a name="data-and-testing"></a>

In this demo, I simulated lag using `OS.delay_msec(randi_range(lower_delay, upper_delay))` to delay each frame by a random delay value — thus, lowering the FPS. When FPS drops below 7.5, you'll observe:
* Delta-based stopwatch starts quickly falling behind real-time — the lower the FPS, the faster it falls behind
* Timestamp-based stopwatch continues tracking time accurately

I ran some tests on my machine with different framerates to get a ballpark estimate of how significant the time deviation is for the delta-based stopwatch at low FPS. I ran the stopwatch for 60 seconds for different delay ranges and calculated how much delta-based stopwatches lose time by dividing the time difference by how much real-time passed (~60 seconds each time).

| Delay Range (ms) | Approximate FPS | Loss of Time for Delta-based Stopwatch |
| ------------- | ------------- | ------------- |
| 130-140 | 7 | 3.33% |
| 150-160 | 6 | 15.45% |
| 170-200 | 5 | 29.20% |
| 210-240 | 4 | 41.41% |
| 260-330 | 3 | 55.37% |

**Note:** Using `OS.delay_msec()` is a simplified way to simulate lag, and while not identical to real-world causes of low FPS, it should highlight the core issue with the delta-based approach faithfully.

While this test is not rigorously scientific by any means, it's meant to provide a rough estimate of the scale of the problem. Even differences on the order of tenths of a percent can be problematic for certain games where even a 100ms deviation can be a deal breaker. This test demonstrates that if the player's game reaches this FPS range *even for a second* (during loading of a new area, for example), a delta-based stopwatch can lose hundreds of milliseconds of time.


## Conclusion <a name="conclusion"></a>
I hope to have convinced you to avoid the delta-based approach to implementing stopwatches in favor of the timestamp-based approach and illuminated a previously underreported issue.

If you find inaccuracies in this README or the demo, feel free to open an issue on this repository or create a pull request.
