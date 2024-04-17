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
  
  while (!Verilated::gotFinish()) {
    vtime += 1;
    if (vtime % 1 == 0)
      clock ^= 1;
    top_module.i_clk = clock;
    top_module.eval();
    vcd.dump(vtime);
    if (vtime > 500)
      break;
  }
  top_module.final();
  vcd.close();
  exit(EXIT_SUCCESS);
}
