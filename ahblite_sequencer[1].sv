class ahblite_sequencer extends uvm_sequencer #(seq_item);

    `uvm_component_utils(ahblite_sequencer);

    function new (string name,uvm_component parent);
        super.new(name,parent);
    endfunction

endclass:ahblite_sequencer
