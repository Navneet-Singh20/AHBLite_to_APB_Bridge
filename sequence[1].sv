
class base_sequence extends uvm_sequence #(seq_item);

    `uvm_object_utils(base_sequence)

    function new (string name = "base_sequence");
        super.new(name);
    endfunction

    `uvm_declare_p_sequencer (ahblite_sequencer)
    // `uvm_declare_p_sequencer (apb_sequencer)

    //create, randomize and send the packet to driver
    virtual task body();
            req = seq_item::type_id::create("req");
            wait_for_grant();
            req.randomize();
            send_request(req);
            wait_for_item_done();
    endtask

endclass:base_sequence


class write_sequence extends uvm_sequence #(seq_item);

    `uvm_object_utils(write_sequence)

    function new (string name = "write_sequence");
        super.new(name);
    endfunction

    virtual task body();
      repeat(10) begin
        `uvm_do_with(req,{req.operation == WRITE; req.burst == SINGLE;})  //WRITE means packet with write operation
      end
    endtask

endclass:write_sequence


class read_sequence extends uvm_sequence #(seq_item);

    `uvm_object_utils(read_sequence)

    function new (string name = "read_sequence");
        super.new(name);
    endfunction

    virtual task body();
      `uvm_do_with(req,{req.operation == READ; req.burst == SINGLE;}) //READ means packet with read operation
    endtask

endclass:read_sequence



class write_read_sequence extends uvm_sequence #(seq_item);

    `uvm_object_utils (write_read_sequence)

    function new(string name = "write_read_sequence");
        super.new(name);
    endfunction

    virtual task body();
      repeat(100)
         begin
            `uvm_do_with(req,{req.burst == SINGLE; })
         end
        /* repeat(50)
         begin
            `uvm_do_with(req,{req.operation == READ;  req.burst == SINGLE;req.addr[7:0] == 0; })
         end*/
       
    endtask

endclass:write_read_sequence
