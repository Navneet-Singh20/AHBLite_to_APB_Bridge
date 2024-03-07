class ahblite_monitor extends uvm_monitor#(seq_item); //ahb_monitor is user given class has been derived from uvm_monitor

   `uvm_component_utils(ahblite_monitor)       //registering component

    virtual intf vif;   //declare the virtual intf handle
     
    uvm_analysis_port #(seq_item) ahb_item_collected_port;  //declare a analysis port

    seq_item trans_collected;  // declare the handle for seq_item

    int count;         // taking count signal
    
    
    function void build_phase(uvm_phase phase);  //build phase
        super.build_phase(phase);
        if(!uvm_config_db#(virtual intf)::get(this,"","vif",vif)) // get interface handle from the conflig db
            `uvm_fatal("NOVIF",{"virtual interface must be set for:",get_full_name(),".vif"});
    endfunction

    function new(string name, uvm_component parent);// component constructor
        super.new(name,parent);
        ahb_item_collected_port = new("ahb_item_collected_port",this); // creating the instance for the analysis port     
    endfunction
          
    virtual task run_phase(uvm_phase phase);// run_phase
        forever begin
            if(vif.HREADYIN == 1) begin
                trans_collected       = new();//creating instance for the seq_item
               
                trans_collected.data  = new[4];
                count           = 0;

                trans_collected.addr = vif.HADDR;
                #1;
                $cast( trans_collected.operation ,  vif.HWRITE);
              
                @(posedge vif.HCLK);

              if( vif.HWRITE == 1 ) begin //write operation
                    trans_collected.data[3] = vif.HWDATA[31:24];
                    trans_collected.data[2] = vif.HWDATA[23:16];
                    trans_collected.data[1] = vif.HWDATA[15:8];
                    trans_collected.data[0] = vif.HWDATA[7:0];
                    fork
                        begin
                            wait(vif.HREADYOUT == 1);  //waiting for the response
                        end
                        begin
                          repeat(20) begin
                                @(posedge vif.HCLK);
                                count = count + 1;
                            end
                        end
                    join_any
                    if(count == 20 ) //count 5 face the error
                       `uvm_error("NO_HREADYOUT","HREADYOUT is not set");
                    disable fork;
                    end
                else begin
                     fork
                        begin
                            wait(vif.HREADYOUT == 1);
                        end
                        begin
                          repeat(20) begin
                                @(posedge vif.HCLK);
                                count=count+1;
                            end
                        end
                    join_any
                    disable fork;
                      if(count == 20 ) begin
                        `uvm_error(get_type_name(),"HREADYOUT is not set");
                      end
                      else begin
                        trans_collected.data[3] = vif.HRDATA[31:24]; //reading operation
                        trans_collected.data[2] = vif.HRDATA[23:16];
                        trans_collected.data[1] = vif.HRDATA[15:8];
                        trans_collected.data[0] = vif.HRDATA[7:0];
                      end
                end
                if (vif.HRESP == 0 && vif.HREADYOUT == 1) begin
                    ahb_item_collected_port.write(trans_collected);
                  
                end
                else begin
                    `uvm_error(get_type_name(),"-----::ERROR IN TRANSMISSION FROM AHB SIDE::-----");
                end
            end
            else begin
                @(posedge vif.HCLK);
            end
           end
        
    endtask
              
                       
endclass
                      
