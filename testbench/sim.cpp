#include "Vout.h"
#include <stdlib.h>
#include <verilated_fst_c.h>
#include <verilated_vcd_c.h>

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);

  Vout top_module;

  Verilated::traceEverOn(true);
  VerilatedFstC vcd;
  top_module.trace(&vcd, 99);
  vcd.open("out1.vcd");

  vluint64_t vtime = 0;
  int clock = 0;

  int uart_rx = 1;

  while (!Verilated::gotFinish()) {
    vtime += 1;
    if (vtime % 1 == 0)
      clock ^= 1;

    if (vtime == 7) {
      uart_rx = 0;
    } else if (vtime == 20) {
      uart_rx = 1;
    }
    // switch (vtime) {
    //   case 7: {
    //     uart_rx = 0;
    //   }
    //   case 11: {
    //     uart_rx = 1;
    //   }
    // }
    top_module.i_clk = clock;
    top_module.uart_rx = uart_rx;
    top_module.eval();
    vcd.dump(vtime);
    if (vtime > 5500)
      break;
  }
  top_module.final();
  vcd.close();
  exit(EXIT_SUCCESS);
}
