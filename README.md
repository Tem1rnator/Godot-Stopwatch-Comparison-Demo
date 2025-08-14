
# Godot Stopwatch Comparison Demo

*Central Problem: Why do some stopwatch implementations in Godot significantly deviate from real-world time when the framerate drops below ~7.5 FPS — losing anywhere from 3% to 60% of real time? And how could that be beneficial?*

This project compares two common ways of implementing a stopwatch in Godot — the **delta-based** approach and the **timestamp-based** approach — and demonstrates how each behaves under low framerate conditions. A test scene is included with adjustable lag simulation to see the differences in action.



## Table of contents

1. [How To Run](#how-to-run)
2. [The Two Approaches](#the-two-approaches)
3. [Delta-based Approach](#delta-based-approach)
4. [Timestamp-based Approach](#timestamp-based-approach)
5. [Why Delta Deviation Can Be Useful](#why-delta-deviation)
6. [Data and Testing](#data-and-testing)
7. [Conclusion](#conclusion)

  

## How To Run <a name="how-to-run"></a>

1. Download or clone this repository
2. Open this project in Godot 4
3. Run the `manual_testing.tscn` scene in the `stopwatches_comparison` folder
4. Press "Start" button to start both stopwatches
5. Press "Toggle Frame Lag Simulation" to impose simulated lag and observe the time difference between the stopwatches grow.
6. Use the two `LineEdit` fields at the bottom of the screen to adjust the delay range for the lag simulation. Higher values in the range will increase lag and lower values will decrease lag. To see the stopwatches start to diverge, set the lower value in the range to at least ~140ms.

Alternatively, if you want to see the difference between the two stopwatches in action, there is a small game scene called `game_example.tscn` that allows you to test the two stopwatches under lag in a game environment:
1. Run the `game_example.tscn` scene in the `game_example` folder.
2. Control your character with WASD keys.
3. Cross the green start line.
4. Move right and cross the green finish line. The game will then record the completion time using both stopwatches.
5.  Go back to the start line and repeat the process but with the "Simulate lag during next race" button switched on.
6. Observe that, under the "Lag differences" section, the "For delta:" value should be closer to zero (i.e., more consistent) than the "For timestamp" value. This means that the delta-based approach showed a smaller time difference between lag and no-lag runs than the timestamp-based approach, which means that the delta-based approach is better for tracking in-game time, even if it means it deviates from real-world time during severe FPS drops.



## The Two Approaches <a name="the-two-approaches"></a>

### Delta-based Approach <a name="delta-based-approach"></a>

The most common stopwatch implementation looks something like this:

```csharp
var stopwatch_time := 0.0

func _process(delta: float):
	stopwatch_time += delta
```

This is the **delta-based approach**, but while it's simple and intuitive, this approach to timekeeping is not accurate to real-world time when experiencing severe FPS drops. Even Godot's official documentation for Node's `_process()` method explicitly recommends against using `delta` for this purpose:

>  **Note:**  `delta` will be larger than expected if running at a framerate lower than `Engine.physics_ticks_per_second` / `Engine.max_physics_steps_per_frame` FPS. This is done to avoid "spiral of death" scenarios where performance would plummet due to an ever-increasing number of physics steps per frame. This behavior affects both `_process()` and `_physics_process()`. **As a result, avoid using `delta` for time measurements in real-world seconds**. Use the `Time` singleton's methods for this purpose instead, such as `Time.get_ticks_usec()`."
  

In other words, players who experience framerates that dip below 7.5 FPS will see stopwatches in their game lose some real-world time (potential 3-60% loss of time; more on that later in [Data and Testing](#data-and-testing) section) because the engine is skipping frames to avoid a "spiral of death". However, while this loss of time doesn't reflect *real-world* time, it does reflect the time that has passed *in-game*. At these low FPS, the physics simulation slows down, and so the delta-based approach manages to match that slowdown, which is actually beneficial if you don't want the game to punish players during framerate drops.

The 7.5 FPS number comes from the equation: `Engine.physics_ticks_per_second / Engine.max_physics_steps_per_frame`, where the default values for these values in Project Settings are:
*  `Engine.physics_ticks_per_second` = 60
*  `Engine.max_physics_steps_per_frame` = 8


So the resulting equation with default settings is 60 / 8 = 7.5

These values can be found and changed under `Project` > `Project Settings` > `Physics (section)` > `Common (subsection)` > `Physics Ticks per Second` and `Max Physics Steps per Frame`

**IMPORTANT:** If you've changed these values in Project Settings, your game's FPS threshold for this may be different.

Sidenote: exploring the inner workings of physics simulation, what the "spiral of death" is, and the reasoning behind unexpected `delta` values is outside the scope of this demo's README, but if you want to explore this further, I recommend other resources like this article on physics timestep: [Fix Your Timestep! | Gaffer On Games](https://gafferongames.com/post/fix_your_timestep/)

  

### Timestamp-based Approach <a name="timestamp-based-approach"></a>

The alternative approach to stopwatches is the **timestamp-based approach**. Here is an example of an oversimplified version of this approach (it only tells you microseconds since start):

```csharp
# usec = microseconds
var start_timestamp_usec := 0

func start():
	start_timestamp_usec = Time.get_ticks_usec()

func get_elapsed_time_usec() -> int:
	return Time.get_ticks_usec() - start_timestamp_usec
```

This approach saves a "timestamp" (i.e. the value returned by `Time.get_ticks_usec()`) at the starting moment and then subtracts the current time from the starting timestamp to get how many microseconds have elapsed since the start of the stopwatch. This time can then be converted to something more useful like milliseconds, seconds, minutes, etc. This approach ensures that low framerate will not affect the accuracy of stopwatches, so it'll always be accurate to real time.


## Why Delta Deviation Can Be Useful <a name="why-delta-deviation"></a>
When the framerate dips below Engine.physics_ticks_per_second / Engine.max_physics_steps_per_frame (which, with default physics project settings, is 60 / 8 = 7.5 FPS), Godot caps how many physics steps run per frame to avoid a "spiral of death". As a result, some frames are skipped and thus some real time may not be simulated. The consequences are:
-   **Delta-based approach:**  
	Since it relies on **simulated** time, when the game “slows down” due to capped physics steps, the stopwatch slows too. This makes it match the in-game time. If a player experiences FPS drops, the game will run slower, but this stopwatch approach will match the slowed game simulation to ensure that the game doesn't punish the player (by making it seem like the player took longer to complete a level, for example).
	
-   **Timestamp-based stopwatch (real/world time):**  
	Advances by **wall-clock** time via `Time.get_ticks_usec()`. It remains accurate even when frames are dropped, so it reflects actual elapsed real time. But if used for in-game time, it has the potential of punishing players during severe FPS drops (e.g., by making it look like the player took longer to complete the level, even though the slowdown of the game is at fault)


## Data and Testing <a name="data-and-testing"></a>

In this demo, I simulated lag using `OS.delay_msec(randi_range(lower_delay, upper_delay))` to delay each frame by a random delay value — thus, lowering the FPS. When FPS drops below 7.5, you'll observe:

* Delta-based stopwatch starts quickly falling behind real-time — the lower the FPS, the faster it falls behind
* Timestamp-based stopwatch continues tracking real time accurately

  
I ran some tests on my machine with different framerates to get a ballpark estimate of how significant the time deviation is for the delta-based stopwatch at low FPS. I ran the stopwatch for 60 seconds for different delay ranges and calculated how much delta-based stopwatches lose time by dividing the time difference by how much real-time passed (~60 seconds each time).

  
| Delay Range (ms) | Approximate FPS | Loss of Time for Delta-based Stopwatch |
| ------------- | ------------- | ------------- |
| 130-140 | 7 | 3.33% |
| 150-160 | 6 | 15.45% |
| 170-200 | 5 | 29.20% |
| 210-240 | 4 | 41.41% |
| 260-330 | 3 | 55.37% |

  

**Note:** Using `OS.delay_msec()` is a simplified way to simulate lag, and while not identical to real-world causes of low FPS, it should highlight the inaccuracy of the delta-based approach faithfully.


## Conclusion <a name="conclusion"></a>

-   **Delta-based approach** → Accurate to in-game time. Will deviate from real-world time during significant FPS drops to match the slowed in-game simulation.
-   **Timestamp-based approach** → Always accurate to real-world time.

Choose the approach based on whether you want to track in-game time or real-world time. With this repo, I hope to have shined a light onto this underreported but important distinction.

If you find mistakes in this README or the demo, feel free to open an issue on this repository or create a pull request.
