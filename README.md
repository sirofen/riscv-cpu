# RISC-V 5-Stage Pipeline CPU
## Overview

This repository contains implementation of a 5-stage RISC-V pipeline CPU described in `Computer Organization and Design RISC-V Edition" by David A. Patterson and John L. Hennessy.` implemented in SystemVerilog for educational purposes.\
This project features register forwarding to enhance data flow and reduce pipeline stalls, along with MMIO for device interfacing.

## Components
- Instruction Handling: Manages the fetching, decoding, and execution of instructions, including direct hardware interactions through MMIO for I/O operations.
- Execution Control: Incorporates arithmetic and logical operations, and dynamic decision-making based on instruction type and data dependencies.
- Memory Management: Handles interactions with data memory and external interfaces, providing a framework for data storage and retrieval.
- Pipeline Optimization: Utilizes forwarding to address data hazards and stalling mechanisms to manage dependencies and execution flow effectively.

## Datapath
![image](https://github.com/sirofen/riscv_cpu/assets/68060514/fb0ded1f-41d8-49dd-9f97-3cb96f73e9ec)

## License
This project is released under the MIT License, which permits modification, distribution, and private use under the condition that the license and copyright notice are included in all copies or substantial portions of the software.
