class environment extends uvm_env;

    `uvm_component_utils(environment)

     ahblite_agent ahb_agent_h;
     apb_agent     apb_agent_h;
     scoreboard    scb_h;
     coverage      cov_h;

     function new(string name, uvm_component parent);
         super.new(name,parent);
     endfunction

     virtual function void build_phase(uvm_phase phase);
         super.build_phase(phase);
         ahb_agent_h = ahblite_agent::type_id::create("ahb_agent_h",this);
         apb_agent_h = apb_agent::type_id::create("apb_agent_h",this);
         scb_h       = scoreboard::type_id::create("scb_h",this);
         cov_h       = coverage::type_id::create("cov_h",this);
     endfunction

  virtual function void connect_phase(uvm_phase phase);
       ahb_agent_h.ahb_mon_h.ahb_item_collected_port.connect(scb_h.ahb_item_collected_export);
       apb_agent_h.apb_mon_h.apb_item_collected_port.connect(scb_h.apb_item_collected_export);
       ahb_agent_h.ahb_mon_h.ahb_item_collected_port.connect(cov_h.ahb_cov_item_collected_export);
       apb_agent_h.apb_mon_h.apb_item_collected_port.connect(cov_h.apb_cov_item_collected_export);
     endfunction

endclass
