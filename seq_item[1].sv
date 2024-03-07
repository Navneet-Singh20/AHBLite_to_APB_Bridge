`define MAX_DATA 100

class seq_item extends uvm_sequence_item;

    typedef enum {SINGLE,INCR,WRAP4,INCR4,WRAP8,INCR8,WRAP16,INCR16} burst_mode;
    typedef enum {READ,WRITE} op_type;

    rand bit [31:0] addr;
    rand bit [7:0]  data[];
    rand op_type    operation;
    rand burst_mode burst;

    `uvm_object_utils_begin(seq_item)
        `uvm_field_int(addr,UVM_ALL_ON)
        `uvm_field_array_int(data,UVM_ALL_ON)
        `uvm_field_enum(op_type,operation,UVM_ALL_ON)
    `uvm_object_utils_end
  
     //uvm_line_printer uvm_default_line_printer = new();
     // uvm_printer uvm_default_printer = uvm_default_line_printer;

     // This data_limit constraint is w.r.t 32 bit data size

    constraint data_limit { if(burst == SINGLE) data.size()==4;
                            if(burst == INCR)   (data.size()>4 && data.size()<`MAX_DATA);
                            if(burst == WRAP4)  data.size()== 16;
                            if(burst == INCR4)  data.size()== 16;
                            if(burst == WRAP8)  data.size()== 32;
                            if(burst == INCR8)  data.size()== 32;
                            if(burst == WRAP16) data.size()== 64;
                            if(burst == INCR16) data.size()== 64;
                           }
  
    constraint addr_limit  { addr % 16 == 0;} 

    function new (string name = "seq_item");
        super.new(name);
    endfunction
  
    virtual function string convert2string();
      string contents = "";
      $sformat(contents,"%s addr=0x%0h",contents,addr);
      $sformat(contents,"%s operation=%s",contents,operation);
      $sformat(contents,"%s burst=%s",contents,burst);
      $sformat(contents,"%s data[0]=0x%0h",contents,data[0]);
      $sformat(contents,"%s data[1]=0x%0h",contents,data[1]);
      $sformat(contents,"%s data[2]=0x%0h",contents,data[2]);
      $sformat(contents,"%s data[3]=0x%0h",contents,data[3]);
      return contents;
    endfunction
    
     /*function void print( uvm_printer printer = uvm_default_line_printer );
       if(printer == null)
            printer = uvm_default_printer;
       endfunction*/
    

endclass:seq_item


