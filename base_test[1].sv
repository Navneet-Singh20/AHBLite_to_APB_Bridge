class base_test extends uvm_test;

  `uvm_component_utils(base_test)

    environment env_h;
    write_read_sequence  seqnce_h;
    
  
    function new(string name, uvm_component parent = null);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env_h    = environment::type_id::create("env_h",this);
        seqnce_h =  write_read_sequence::type_id::create("seqnce_h");
    endfunction

    virtual function void end_of_elaboration();
        print();
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seqnce_h.start(env_h.ahb_agent_h.ahb_seqr_h);
        phase.phase_done.set_drain_time(this,50);
        phase.drop_objection(this);
    endtask


    function void report_phase(uvm_phase phase);
        uvm_report_server svr;
        super.report_phase(phase);
        svr = uvm_report_server::get_server();

        if(svr.get_severity_count(UVM_ERROR) > 0 )
            `uvm_info(get_type_name(),"------Test Fail-----",UVM_NONE)
        else
          `uvm_info(get_type_name(),"-----------------------------------------------------------------Test Pass------------------------------------------------------",UVM_NONE)
    endfunction

endclass
