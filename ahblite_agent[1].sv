 class ahblite_agent extends uvm_agent;
  
    `uvm_component_utils(ahblite_agent)
  
      ahblite_monitor    ahb_mon_h;
      ahblite_sequencer  ahb_seqr_h;
      ahblite_driver     ahb_driv_h;
  
  
     function new (string name, uvm_component parent);
         super.new(name,parent);
     endfunction
 
     function void build_phase(uvm_phase phase);
         super.build_phase(phase);
         ahb_mon_h = ahblite_monitor::type_id::create("ahb_mon_h",this);
         if(get_is_active() == UVM_ACTIVE) begin
              ahb_seqr_h = ahblite_sequencer::type_id::create("ahb_seqr_h",this);
              ahb_driv_h = ahblite_driver::type_id::create("ahb_driv_h",this);
         end
     endfunction
 
     function void connect_phase(uvm_phase phase);
         if(get_is_active() == UVM_ACTIVE) begin
           ahb_driv_h.seq_item_port.connect(ahb_seqr_h.seq_item_export);
         end
     endfunction
 
  endclass

