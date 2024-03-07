class apb_driver extends uvm_driver #(seq_item);

    `uvm_component_utils(apb_driver)

    bit [31:0] mem [int];

    function new (string name,uvm_component parent);
        super.new(name,parent);
    endfunction

    virtual intf vif ;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual intf)::get(this,"","vif",vif))
            `uvm_fatal("NO_VIF",{"virtul interface must be set for",get_full_name(),".vif"})
    endfunction

   
     virtual task reset_t();
        vif.PRESETn = 0;
        vif.PREADY  = 0;
        vif.PSLVERR = 0;
        vif.PRDATA  = 32'h0000_0000;

        repeat(5) begin
          @(posedge vif.PCLK);
        end
        vif.PRESETn = 1;

    endtask 

    virtual task run_phase (uvm_phase phase);
      reset_t();
        forever begin
            if(vif.PSEL) begin
                if(vif.PENABLE) begin
                    if(vif.PWRITE) begin
                        mem[vif.PADDR] = vif.PWDATA;
                        vif.PREADY = 1;
                        vif.PSLVERR = 0;
                  
                        @(posedge vif.PCLK);
                        vif.PREADY = 0;
                    end
                    else begin
                        vif.PRDATA = mem[vif.PADDR];
                        vif.PREADY = 1;
                        vif.PSLVERR = 0;
                        @(posedge vif.PCLK);
                        vif.PREADY = 0;
                    end
                end
                else begin
                    vif.PREADY = 0;
                  @(posedge vif.PCLK);
                end
            end
            else begin
                 vif.PREADY = 0;
                 vif.PSLVERR = 0;
                 vif.PRDATA = 0;
                 @(posedge vif.PCLK);
            end
        end

    endtask

endclass:apb_driver

