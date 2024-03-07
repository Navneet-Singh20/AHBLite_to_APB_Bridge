class apb_agent extends uvm_agent;     // defining the apb_agent

   `uvm_component_utils(apb_agent)    //registering in the factory

    apb_monitor apb_mon_h;            //creating the handle for apb_monitor
    apb_sequencer   apb_seqr_h;               //creating the handle for sequencer
    apb_driver  apb_driv_h;          //creating the handle for apb_driver

    function new (string name, uvm_component parent);   //constructor function new
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);         //build_phase
        super.build_phase(phase);
        apb_mon_h       = apb_monitor::type_id::create("apb_mon_h",this);  //creaing the type_id create memory
        if(get_is_active() == UVM_ACTIVE) begin                           //writing agent is in active
            apb_seqr_h  = apb_sequencer::type_id::create("apb_seqr_h",this);       //creating the type_id create memory
            apb_driv_h  = apb_driver::type_id::create("apb_driv_h",this);  //
        end
    endfunction

    function void connect_phase(uvm_phase phase);    //connect phase to the scoreboard
        if(get_is_active() == UVM_ACTIVE) begin    //super.connect_phase(phase)
            apb_driv_h.seq_item_port.connect(apb_seqr_h.seq_item_export); //export the packet to the scoreboard
        end
    endfunction

endclass:apb_agent
