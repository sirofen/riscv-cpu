#!/bin/bash

docker run -ti -v ${PWD}:/work verilator/verilator:latest --timing -Wno-WIDTH -Wno-MULTIDRIVEN -Wno-LATCH --cc --exe --trace --trace-fst --trace-structs --trace-params --build out.sv sim.cpp 
