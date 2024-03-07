 package ahblite_ahb ;

    `include "uvm_macros.svh"
    import uvm_pkg::*;
   // `include "interface.sv"          // path
    //`include "dut.sv"          // path

    `include "seq_item.sv"
    `include "ahblite_sequencer.sv"
    `include "apb_sequencer.sv"
    `include "sequence.sv"

    `include "ahblite_driver.sv"
    `include "ahblite_monitor.sv"
    `include "ahblite_agent.sv"

    `include "apb_driver.sv"
    `include "apb_monitor.sv"
    `include "apb_agent.sv"

    `include "scoreboard.sv"
    `include "Coverage.sv"
    `include "env.sv"
    `include "base_test.sv"

endpackage
