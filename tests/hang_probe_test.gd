extends GameTestSuite
## Throwaway: never finishes, to check CI prints a backtrace when Godot hangs.


func test_never_finishes() -> void:
	while true:
		OS.delay_msec(1000)
