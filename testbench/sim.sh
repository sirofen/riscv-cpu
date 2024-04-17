#!/bin/bash

#cd ../
#iverilog -o testbench/out.sv -E $1
#cd testbench
docker run -ti -v ${PWD}:/work verilator/verilator:latest --timing -Wno-WIDTH -Wno-MULTIDRIVEN -Wno-LATCH --cc --exe --trace --trace-fst --trace-structs --trace-params --build out.sv sim.cpp 
#./obj_dir/Vout
