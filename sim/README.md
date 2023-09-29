# Testbench

The testbench for AnTiQ is designed for randomized input testing within the context of the targetted timer queue use case. The test can be configured with the parameters defined in AnTiQ/src/array_pq/pq_pkg.svh.

- QUEUE_DEPTH: Depth of the queue, default 8. Larger values are supported, but the current printouts are best suited for this depth.

- TIME_WIDTH: Number of bits used for time representation. The test case implements a monotonic (increasing) base time combined with a constrained randomized delta time for randomized input generation.

- TEST_OPS: Number of test operations to run. Selection of the operation is randomized with the op_t enumerator.

- DELTA_MAX: The maximum value for the delta time. Larger values will give better input randomization, but can result in the test case completing prematurely if an overflow of TIME_WIDTH is detected. 

# RTL Simulation Build Instructions

The RTL simulation of AnTiQ is handled with the Makefile in this directory.

The design is compiled with

```make compile elaboration```

A sanity test (0-ns simulation) can be run with  ```make sanity```


The simulation can then be run with the GUI with  ```make run``` or in batch mode with ```make batch```.
The randomized test routine for the design is automatically initiated when the simulation is run.
