interface intf(input logic HCLK,PCLK);

  logic               HRESETn;
  logic               HSEL;
  logic      [31:0]   HADDR;
  logic      [31:0]   HWDATA;
  logic               HWRITE;
  logic      [2:0]    HSIZE;
  logic      [2:0]    HBURST;
  logic      [3:0]    HPROT;
  logic      [1:0]    HTRANS;
  logic               HMASTERLOCK;
  logic               HREADYIN;
  logic               HREADYOUT;
  logic   [31:0]      HRDATA;
  logic               HRESP;

  logic               PRESETn;
  logic               PSEL;
  logic               PENABLE;
  logic     [2:0]     PROT;
  logic               PWRITE;
  logic   [3:0]       PSTRB;
  logic   [31:0]      PADDR;
  logic   [31:0]      PWDATA;
  logic      [31:0]   PRDATA;
  logic               PREADY;
  logic               PSLVERR;
  
 endinterface:intf

