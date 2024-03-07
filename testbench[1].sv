`include "pkg.sv"
`include "interface.sv"

module top();

    logic HCLK;
    logic PCLK;

    intf vif(HCLK,PCLK);

    AHBLite_APB_Bridge dut (.HCLK(vif.HCLK),.PCLK(vif.PCLK),.HSEL(vif.HSEL),.HADDR(vif.HADDR),.HWDATA(vif.HWDATA),.HWRITE(vif.HWRITE),.HRESETn(vif.HRESETn),.HSIZE(vif.HSIZE),.HBURST(vif.HBURST),.HPROT(vif.HPROT),.HTRANS(vif.HTRANS),.HMASTERLOCK(vif.HMASTERLOCK),.HREADYIN(vif.HREADYIN),.HREADYOUT(vif.HREADYOUT),.HRDATA(vif.HRDATA),.HRESP(vif.HRESP),.PRESETn(vif.PRESETn),.PSEL(vif.PSEL),.PENABLE(vif.PENABLE),.PROT(vif.PROT),.PWRITE(vif.PWRITE),.PSTRB(vif.PSTRB),.PADDR(vif.PADDR),.PWDATA(vif.PWDATA),.PRDATA(vif.PRDATA),.PREADY(vif.PREADY),.PSLVERR(vif.PSLVERR)); 
    initial begin
        HCLK = 0;
        forever
            #5 HCLK = ~HCLK;
    end

    initial begin
        PCLK = 0;
        forever
            #5 PCLK = ~PCLK;
    end

    initial begin
      uvm_config_db#(virtual   intf)::set(uvm_root::get(),"*","vif",vif);
        $dumpfile("dump.vcd");
        $dumpvars();
    end

    initial begin
      run_test();
    end
  
    initial begin
      #20000 $finish;
    end
endmodule