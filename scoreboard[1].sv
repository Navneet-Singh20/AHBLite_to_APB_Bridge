`uvm_analysis_imp_decl(_ahb)
`uvm_analysis_imp_decl(_apb)

class scoreboard extends uvm_scoreboard;

    `uvm_component_utils(scoreboard)

    uvm_analysis_imp_ahb #(seq_item,scoreboard) ahb_item_collected_export;
    uvm_analysis_imp_apb #(seq_item,scoreboard) apb_item_collected_export;

    seq_item ahb_queue[$];
    seq_item apb_queue[$];
    seq_item pkt1,pkt2;

  function new(string name, uvm_component parent );
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb_item_collected_export = new("ahb_item_collected_export",this);
        apb_item_collected_export = new("apb_item_collected_export",this);
        
    endfunction

    virtual function void write_ahb(seq_item pkt);
        ahb_queue.push_back(pkt);
    endfunction

    virtual function void write_apb(seq_item pkt);
        apb_queue.push_back(pkt);
    endfunction

    virtual task run_phase(uvm_phase phase);
        bit flag = 1'b0;
        forever begin
            wait((ahb_queue.size() && apb_queue.size()) > 0);
            pkt1 = ahb_queue.pop_front();
            pkt2 = apb_queue.pop_front();
         
           `uvm_info(get_type_name(),$sformatf("contents pkt1 ::%s",pkt1.convert2string()),UVM_LOW)
           `uvm_info(get_type_name(),$sformatf("contents pkt2 ::%s",pkt2.convert2string()),UVM_LOW)

            if(pkt1.addr != pkt2.addr) begin
                `uvm_info(get_type_name(),"address not matched",UVM_LOW);
                flag = 1'b1;
            end

            if(pkt1.operation != pkt2.operation) begin
                `uvm_info(get_type_name(),"operation not matched",UVM_LOW);
                flag = 1'b1;
            end

            for(int i=0; i<4 ;i++) begin
              if(pkt1.data[i] != pkt2.data[i]) begin
                   `uvm_info(get_type_name(),"data not matched",UVM_LOW);
                   flag = 1'b1;
               end
            end

            if(flag == 0) begin
              `uvm_info(get_type_name(),"-------------------------------------------------::Succesful match::----------------------------------------------",UVM_LOW);
            end
            else begin
              `uvm_error(get_type_name(),"-----::Failed match::-----");
            end
        end
    endtask

endclass:scoreboard
