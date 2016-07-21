# Profiling 

### Rails Console Approach 

Inspecting GTFSGraph For imports (specifically level 1) 
- GC::Profiler.enable 
- GC::Profiler.clear 
- graph = GTFSGraph.new(feed, feed_version) 
- graph.cleanup 
- graph.create_change_osr 
- GC::Profiler.report  

This will generate something like:

````
GC 356 invokes.
Index    Invoke Time(sec)       Use Size(byte)     Total Size(byte)         Total Object                    GC Time(ms)
    1               3.130             10915080             22309440               557736        45.38900000000101186970
    2               3.292              6758680             22309440               557736        25.92400000000694149094
    3               3.490              6967960             22309440               557736        23.29300000000422699031
    4               3.751             12324600             22309440               557736        29.06400000001418959528
    5               3.895             12336840             22309440               557736        29.70399999998463158590
    6               4.240             14631160             22309440               557736        39.10299999999278242058
    7               4.418             15535360             22309440               557736        26.44100000000193517735
    8               4.534             16335440             22309440               557736        31.37299999998166555315
````

Run a few times to establish a baseline. Make optimization changes and compare.
