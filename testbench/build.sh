#!/bin/bash

cd ../rtl
iverilog -E -o ../testbench/out.sv ../testbench/cpu_testbench.sv

#cd testbench

