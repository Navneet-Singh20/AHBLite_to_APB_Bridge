`uvm_analysis_imp_decl(_ahb_cov)
`uvm_analysis_imp_decl(_apb_cov)

class coverage extends uvm_component;
  
    `uvm_component_utils(coverage)
  
    uvm_analysis_imp_ahb_cov #(seq_item,coverage) ahb_cov_item_collected_export;
    uvm_analysis_imp_apb_cov #(seq_item,coverage) apb_cov_item_collected_export;
  
    seq_item pkt1,pkt2;
  
    // Coverage
  
    covergroup ahblite_cov ;
      coverpoint  pkt1.addr {option.auto_bin_max = 100;} 
      coverpoint  pkt1.operation;
    endgroup
        
    covergroup apb_cov ;
      coverpoint pkt2.addr {option.auto_bin_max = 100;}
      coverpoint pkt2.operation;
    endgroup
    
    function new(string name, uvm_component parent );
        super.new(name,parent);
        ahblite_cov  = new(); 
        apb_cov      = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb_cov_item_collected_export = new("ahb_item_collected_export",this);
        apb_cov_item_collected_export = new("apb_item_collected_export",this); 
    endfunction

    virtual function void write_ahb_cov(seq_item pkt);
        pkt1 = pkt;
        ahblite_cov.sample();
      `uvm_info(get_type_name(), $sformatf("AHB_lite Coverage Report %f % achieved",ahblite_cov.get_coverage()),UVM_LOW);
    endfunction

    virtual function void write_apb_cov(seq_item pkt);
       pkt2 = pkt;
       apb_cov.sample();
      `uvm_info(get_type_name(), $sformatf("AHB_lite Coverage Report %f % achieved",apb_cov.get_coverage()),UVM_LOW);  
    endfunction
  
endclass
  
  