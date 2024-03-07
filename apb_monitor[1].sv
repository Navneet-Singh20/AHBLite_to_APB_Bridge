class apb_monitor extends uvm_monitor #(seq_item);

  `uvm_component_utils(apb_monitor)

   virtual intf vif;

   uvm_analysis_port#(seq_item) apb_item_collected_port;
 
   seq_item trans_collected;

   function void build_phase(uvm_phase phase);
       super.build_phase(phase);
     if(!uvm_config_db #(virtual intf)::get(this,"","vif",vif))
           `uvm_fatal("NOVIF",{"virtual interface must be set for:",get_full_name(),".vif"});
   endfunction
  
  function new (string name, uvm_component parent);
       super.new(name,parent);
     apb_item_collected_port = new("apb_item_collected_port",this);
     
   endfunction

   virtual task run_phase(uvm_phase phase);
       forever begin
           if(vif.PSEL && vif.PENABLE && vif.PREADY) begin
             
               trans_collected   = new();
               
               $cast(trans_collected.operation, vif.PWRITE);
               trans_collected.addr      = vif.PADDR;
               trans_collected.data      = new[4];
               
               if(vif.PWRITE == 1) begin
                   trans_collected.data [3] = vif.PWDATA [31:24];
                   trans_collected.data [2] = vif.PWDATA [23:16];
                   trans_collected.data [1] = vif.PWDATA [15:8];
                   trans_collected.data [0] = vif.PWDATA [7:0];
               end
               else begin
                   trans_collected.data [3] = vif.PRDATA [31:24];
                   trans_collected.data [2] = vif.PRDATA [23:16];
                   trans_collected.data [1] = vif.PRDATA [15:8];
                   trans_collected.data [0] = vif.PRDATA [7:0];
               end
               if(vif.PSLVERR ==0) begin
                   apb_item_collected_port.write(trans_collected);
           end
           else begin
                  `uvm_error(get_type_name(),"----:: PLSVERR ERROR IS ASSERTED ::----");
           end
           @(posedge vif.PCLK);
           end
           else begin
               @(posedge vif.PCLK);
           end
       end
       
   endtask
  
      
endclass
