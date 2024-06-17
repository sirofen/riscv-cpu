# RISC-V 5-Stage Pipeline CPU

## Overview

This repository contains the implementation of a 5-stage RISC-V pipeline CPU described in "Computer Organization and Design RISC-V Edition" by David A. Patterson and John L. Hennessy. It is implemented in SystemVerilog for educational purposes. This project features register forwarding to enhance data flow and reduce pipeline stalls, along with MMIO for device interfacing.

## Components

- **Instruction Handling**: Manages the fetching, decoding, and execution of instructions.
- **Execution Control**: Incorporates arithmetic and logical operations and dynamic decision-making based on instruction type and data dependencies.
- **Memory Management**: Handles interactions with data memory and external interfaces, providing a framework for data storage and retrieval.
- **Pipeline Optimization**: Utilizes forwarding to address data hazards and stalling mechanisms to manage dependencies and execution flow effectively.

## MMIO Interfaces and Memory

- **DDR3 Memory**
- **PCIe DMA to DDR3**
- **Ethernet(UDP) MMIO Interface**
- **UART MMIO Interface**
- **GPIO MMIO Interface**

## Datapath
![Datapath](https://github.com/sirofen/riscv_cpu/assets/68060514/fb0ded1f-41d8-49dd-9f97-3cb96f73e9ec)

## Example Projects

Example projects demonstrating the use of the CPU with various peripherals are available in the `rtl/bin/` directory. These include:

- **led_blink**: Simple program to blink LEDs.
- **uart_test**: UART communication test program.
- **udp_receive**: Program to receive UDP packets.
- **udp_send**: Program to send UDP packets.

## License

This project is released under the MIT License, which permits modification, distribution, and private use under the condition that the license and copyright notice are included in all copies or substantial portions of the software.

Note: This Software includes TCL scripts that generate IP blocks using Xilinx tools. Users must comply with the Xilinx End User License Agreement (EULA) when using these tools. Generated IP blocks are subject to the Xilinx EULA and are not covered by this MIT License.
