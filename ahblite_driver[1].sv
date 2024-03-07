class ahblite_driver extends uvm_driver #(seq_item);//ahblite_driver will extends from the uvm_driver

    `uvm_component_utils(ahblite_driver) // component registration

    virtual intf vif; //Creating virtual interface handle

    int count;

    function new (string name,uvm_component parent); //Constructor
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase); //build phase
        super.build_phase(phase);
        if(!uvm_config_db#(virtual intf)::get(this,"","vif",vif)) //get virtual interface handle
            `uvm_fatal("no_vif",{"virtual interface must be set for",get_full_name(),".vif"});
    endfunction

    virtual task reset_t(); //Reset phase
        vif.HRESETn     = 0;
        vif.HSEL        = 0;
        vif.HREADYIN    = 0;
        vif.HADDR       = 32'h0000_0000;
        vif.HPROT       = 4'b0011;
        vif.HBURST      = 3'b000;
        vif.HTRANS      = 2'b10;
        vif.HSIZE       = 3'b010;
        vif.HMASTERLOCK = 1'b0;
        vif.HWDATA      = 32'h0000_0000;
        vif.HWRITE      = 0;
        repeat(5) begin
            @(posedge vif.HCLK);
        end
        vif.HRESETn = 1;
    endtask

    virtual task run_phase(uvm_phase phase);    // main phase
      reset_t();  
      forever begin
                seq_item_port.get_next_item(req);// get the next data item from the sequencer
                drive();                         // calling drive task
                seq_item_port.item_done();       // Indicate to the sequencer that the data item has been driven 
        end
     endtask
  
    virtual task drive();
        vif.HSEL        = 1;
        vif.HREADYIN    = 1;
        vif.HPROT       = 4'b0011;
        vif.HBURST      = req.burst;
        vif.HTRANS      = 2'b10;           //NONSEQ type i.e First or single transfer
        vif.HSIZE       = 3'b010;          //Word type(32bit) i.e Indicate the size of data transfer
        vif.HMASTERLOCK = 1'b0;
        vif.HADDR       = req.addr;
        vif.HWRITE      = req.operation;

        @(posedge vif.HCLK);

       if(req.operation == 1) begin  // write operation
            vif.HWDATA = {req.data[3],req.data[2],req.data[1],req.data[0]};
            @(posedge vif.HCLK);
      
            fork
                begin
                
                    wait (vif.HREADYOUT == 1);
                   
                end
                begin
                  repeat(20) begin
                      @(posedge vif.HCLK);
                        count=count+1;
                    end
                end
            join_any
            if(count == 20 ) begin
                `uvm_error("NO_HRADYOUT","HREADYOUT is not set")
            end
            disable fork;
            end
        else begin         // checking HREADYOUT for Read operation
             @(posedge vif.HCLK); 
                 fork
                    begin
                        wait(vif.HREADYOUT == 1);
                    end
                    begin
                      repeat(20) begin
                            @(posedge vif.HCLK);
                            count = count+1;
                        end
                    end
                 join_any
                 disable fork;
                 if(count == 20 )
                    `uvm_error("NO_READYOUT","HREADYOUT is not set")
                 else begin
                    req.data[3] = vif.HRDATA[31:24];
                    req.data[2] = vif.HRDATA[23:16];
                    req.data[1] = vif.HRDATA[15:8];
                    req.data[0] = vif.HRDATA[7:0];
                 end
           // rsp.set_id_info(req);
           // seq_item_port.put(rsp);

        end
           vif.HSEL     = 0;
           vif.HREADYIN = 0;

        // else
       // rest of burst logic yet to be create

   endtask

  endclass:ahblite_driver

