// Code your design here
module AHBLite_APB_Bridge #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32
)
(
  input                           HRESETn,                      //AHB Reset Active Low                                                                          *form reset controller to Bridge*
  input                           HCLK,                         //AHB Clock                                                                                     *from Clock Source to Bridge*
  input                           HSEL,                         //AHB Slave Select                                                                              *form AHB Decoder to AHB Slave*
  input      [ADDR_WIDTH-1:0]     HADDR,                        //AHB Address                                                                                   *from AHB Master to Bridge (AHB Slave)*
  input      [DATA_WIDTH-1:0]     HWDATA,                       //AHB Write Data                                                                                *from AHB Master to Bridge (AHB Slave)*
  input                           HWRITE,                       //AHB Write/Read 1/0 Control                                                                    *form AHB Master to Bridge (AHB Slave)*
  input      [2:0]                HSIZE,                        //AHB Transfer Size (0 - 8bit, 1 - 16bit, 2 - 32bit) (Max Value  depends on Bus Width)          *from AHB Master to Bridge (AHB Slave)*
  input      [2:0]                HBURST,//Not used
  input      [3:0]                HPROT,//Not used
  input      [1:0]                HTRANS,                       //AHB Master Transfer Mode (0 - IDLE, 1 - BUSY, 2 - NONSEQ, 3 - SEQ)                            *from AHB Master to Bridge (AHB Slave)*
  input                           HMASTERLOCK,//Not used
  input                           HREADYIN,                     //Slave Ready Signal from Mux in AHB Bus to AHB Master and AHB Slave                            *from Multiplexer to AHB Master and Bridge (AHB Slave)*
  output reg                      HREADYOUT,                    //Slave Ready Signal from AHB Slave to AHB Mux                                                  *from Bridge (AHB Slave) to the Multiplexer*
  output reg [DATA_WIDTH-1:0]     HRDATA,                       //AHB Read Data                                                                                 *from Bridge (AHB Slave) to Mux to AHB Master*
  output reg                      HRESP,                        //AHB Slave Response                                                                            *from Bridge (AHB Slave) to Mux to AHB Master*

  input                           PRESETn,                      //APB Reset Active Low                                                                          *from Reset controller to Bridge (APB Master)*
  input                           PCLK,                         //APB Clock                                                                                     *from clock source to Bridge (APB Master)*
  output reg                      PSEL,                         //APB Slave Select                                                                              *from Bridge (APB Master) to APB Slaves*
  output reg                      PENABLE,                      //APB Slave Enable                                                                              *from Bridge (APB Master) to APB Slaves*
 output     [2:0]                PROT,
  output reg                      PWRITE,                       //APB Write/Read 1/0 Control                                                                    *from Bridge (APB Master) to APB Slaves*
  output reg [(DATA_WIDTH/8)-1:0] PSTRB,                        //APB Strobe Signal to Slaves                                                                   *from Bridge (APB Master) to APB Slaves*
  output reg [ADDR_WIDTH-1:0]     PADDR,                        //APB Address
  output reg [DATA_WIDTH-1:0]     PWDATA,                       //APB Write Data
  input      [DATA_WIDTH-1:0]     PRDATA,                       //APB Read Data                                                                                 *from APB Slave to Bridge (APB Master)*
  input                           PREADY,                       //APB Slave Ready                                                                               *from APB Slave to Bridge (APB Master)*
  input                           PSLVERR                       //APB Slave Error                                                                               *from APB Slave to Bridge (APB Master)*
);
  

parameter ST_AHB_IDLE     = 2'b00,
          ST_AHB_TRANSFER = 2'b01,
          ST_AHB_ERROR    = 2'b10;

reg  [1:0]            ahb_state;                //State Register of AHB state Machine
wire                  ahb_transfer;
reg                   apb_treq;
reg                   apb_treq_toggle;
reg  [2:0]            apb_treq_sync;
wire                  apb_treq_pulse;

reg                   apb_tack;
reg                   apb_tack_toggle;
reg  [2:0]            apb_tack_sync;
wire                  apb_tack_pulse;
reg                   apb_tack_pulse_Q1;
reg  [ADDR_WIDTH-1:0] ahb_HADDR;
reg                   ahb_HWRITE;
reg  [2:0]            ahb_HSIZE;
reg  [DATA_WIDTH-1:0] ahb_HWDATA;
reg                   latch_HWDATA;
reg  [DATA_WIDTH-1:0] apb_PRDATA;
reg                   apb_PSLVERR;
reg  [DATA_WIDTH-1:0] apb_PRDATA_HCLK;
reg                   apb_PSLVERR_HCLK;

assign ahb_transfer = (HSEL & HREADYIN & (HTRANS == 2'b10 || HTRANS == 2'b11)) ? 1'b1 : 1'b0;           //if slave is ready and master is ready for next transfer initiate transfer from AHB to APB
//Block 1
//AHB Side State Machine
//Captures Data and Control from the AHB Bus
always@(posedge HCLK or negedge HRESETn)begin                                   //Single always block Melay State Machine
  if(!HRESETn)begin
    HREADYOUT  <= 1'b1;                                                         //Initial Reset
    HRESP      <= 1'b0;
    HRDATA     <=  'd0;
    ahb_HADDR  <=  'd0;
    ahb_HWRITE <= 1'b0;
    ahb_HSIZE  <=  'd0;
    ahb_state  <= ST_AHB_IDLE;
    apb_treq   <= 1'b0;
  end else begin
    apb_treq   <= 1'b0;
    case (ahb_state)
      ST_AHB_IDLE : begin                               //AHB IDLE STATE
        HREADYOUT  <= 1'b1;                             //Bridge (AHB Slave) is ready when in IDLE state
        HRESP      <= 1'b0;                             //Bridge (AHB Slave) Responds Ok when IDLE
        ahb_HADDR  <= HADDR;                            //Latch the AHB Address and Control signals from AHB Bus in IDLE State
        ahb_HWRITE <= HWRITE;                           //Reading AHB Bus Control Signals
        ahb_HSIZE  <= HSIZE;
        if(ahb_transfer)begin                           //if slave and master is ready for transfer
          ahb_state <= ST_AHB_TRANSFER;                 //state change to transfer
          HREADYOUT <= 1'b0;                            //Bridge (AHB Slave) enters transaction and pulls down hreadyout to say not ready for next transfer until i complete this transfer
          apb_treq  <= 1'b1;                            //Initiate transfer request to APB State Machine of Bridge (AHB Slave - APB Master)
        end
      end
      ST_AHB_TRANSFER : begin                           //AHB TRANSFER STATE
        HREADYOUT <= 1'b0;                              //Bridge not ready to make another transfer while it is transfering one transaction
        if(apb_tack_pulse_Q1)begin                      //if acknowledgement is recived from the AHB state machine for the transfer
          HRDATA <= apb_PRDATA_HCLK;                    //Read data from the Slave
                if(apb_PSLVERR_HCLK)begin                       //If Slave has error
                  HRESP     <= 1'b1;                            //Respond to AHB Master with a Not Ok response
                  ahb_state <= ST_AHB_ERROR;                    //And Enter Error State
                end else begin                                  //If there is no Error
                  HREADYOUT <= 1'b1;                            //Bridge says I am ready with hreadyout 1
                  HRESP     <= 1'b0;                            //And I am OK with the transfer
                  ahb_state <= ST_AHB_IDLE;                     //Then Enter IDLE State
                end
        end                                             //if no acknowledgement is received then remain in the transfer state
      end
 ST_AHB_ERROR : begin                              //AHB ERROR STATE
        HREADYOUT <= 1'b1;                              //Bridge ready to receive
        ahb_state <= ST_AHB_IDLE;                       //Enter State Idle
      end
      default: begin
        ahb_state <= ST_AHB_IDLE;
      end
    endcase
  end
end

//Block 2
//Data Latch from AHB Bus Based on Previous Control Signals
always@(posedge HCLK or negedge HRESETn)begin
  if(!HRESETn)begin
    ahb_HWDATA   <=  'd0;
    latch_HWDATA <= 1'b0;
  end else begin
    if(ahb_transfer && HWRITE) latch_HWDATA <= 1'b1;
    else                       latch_HWDATA <= 1'b0;
    if(latch_HWDATA)begin
      ahb_HWDATA <= HWDATA;
    end
  end
end


//Block 3
//Treq to Synchronize the transaction between the AHB Bus and APB Bus
always@(posedge HCLK or negedge HRESETn)begin
  if(!HRESETn)begin
    apb_treq_toggle <= 1'b0;
  end else begin
    if(apb_treq) apb_treq_toggle <= ~apb_treq_toggle;   //Toggle whenever an Transaction is initiated
  end
end

//Block 4
//Synchronizer to Transfer the Treq Signal to the APB state machine
always@(posedge PCLK or negedge PRESETn)begin
  if(!PRESETn)begin
     apb_treq_sync  <=  'd0;
  end else begin
 apb_treq_sync <= {apb_treq_sync[1:0], apb_treq_toggle};
  end
end

//Exor Gate produces the actual treq pulse that reaches the Latches
assign apb_treq_pulse = apb_treq_sync[2] ^ apb_treq_sync[1];


reg                   apb_treq_pulse_Q1;
reg  [ADDR_WIDTH-1:0] ahb_HADDR_PCLK;
reg                   ahb_HWRITE_PCLK;
reg  [2:0]            ahb_HSIZE_PCLK;
reg  [DATA_WIDTH-1:0] ahb_HWDATA_PCLK;

//Block 5 HCLK Latch Address and Control Signals
//The treq pulse acts as a validation signal for data being transfered from
//AHB state machine to HCLK Latch
always@(posedge PCLK or negedge PRESETn)begin
  if(!PRESETn)begin
    apb_treq_pulse_Q1 <= 0;
    ahb_HADDR_PCLK    <= 0;
    ahb_HWRITE_PCLK   <= 0;
    ahb_HSIZE_PCLK    <= 0;
    ahb_HWDATA_PCLK   <= 0;
  end else begin
    apb_treq_pulse_Q1 <= apb_treq_pulse;
    if(apb_treq_pulse)begin
      ahb_HADDR_PCLK  <= ahb_HADDR;
      ahb_HWRITE_PCLK <= ahb_HWRITE;
      ahb_HSIZE_PCLK  <= ahb_HSIZE;
      ahb_HWDATA_PCLK <= ahb_HWDATA;
    end
  end
end


reg [(DATA_WIDTH/8)-1:0] lcl_PSTRB;

reg [1:0] apb_state;
parameter ST_APB_IDLE   = 2'b00,
          ST_APB_START  = 2'b01,
          ST_APB_ACCESS = 2'b10;
//Block 6
//APB Side State Machine
//Transfers AHB side Data and Control to the APB Bus
always@(posedge PCLK or negedge PRESETn)begin
  if(!PRESETn)begin                                             //Initial Reset
    apb_state   <= ST_APB_IDLE;
    PADDR       <=  'd0;
    PSEL        <=  'b0;
    PENABLE     <=  'b0;
    PWRITE      <=  'b0;
    PWDATA      <=  'b0;
    PSTRB       <=  'd0;
    apb_PSLVERR <= 1'b0;
    apb_tack    <= 1'b0;
    apb_PRDATA  <=  'd0;
  end else begin
    apb_tack    <= 1'b0;
    case (apb_state)
      ST_APB_IDLE: begin                                        //APB SATE IDLE
        PSEL    <= 'b0;                                         //Select no slave when Idle
        PENABLE <= 'b0;
        PWRITE  <= 'b0;
        if(apb_treq_pulse_Q1)begin                                                                      //If received a request pulse from AHB side
          apb_state <= ST_APB_START;
          PADDR     <= {ahb_HADDR_PCLK[ADDR_WIDTH-1:DATA_WIDTH/8], {{(DATA_WIDTH/8)}{1'b0}}};        //load PADDR by masking lsb bits according to Data Width
          PSTRB     <= lcl_PSTRB;                                                                       //PSTRB to select the slave
          PSEL      <= 'b1;                                                                             //select slave
          PWRITE    <= ahb_HWRITE_PCLK;                                                                 //Read the control signals Hwrite and Hwdata from the AHB side through the synchronizer
          PWDATA    <= ahb_HWDATA_PCLK;
        end
      end                                                       //If there is no transaction request from AHB State Machine Remain Idle

      ST_APB_START: begin                                                                               //APB STATE START
        apb_state <= ST_APB_ACCESS;                                                                     //Salve Select
        PSEL      <= 'b1;
        PENABLE   <= 'b1;                                                                               //Enable the validity
      end

      ST_APB_ACCESS: begin                                                                              //APB STATE ACCESS
        PENABLE <= PENABLE;                                                                             //Hold Penable
        PWRITE  <= PWRITE; 
         if(PREADY)begin                                                                                 //If APB slave is ready
          apb_state   <= ST_APB_IDLE;                                                                   //go idle
          apb_tack    <= 1'b1;                                                                          //acknowledge the transaction is sucess to the AHB State Machine
          apb_PRDATA  <= PRDATA;
          PSEL        <= 'b0;
          PENABLE     <= 'b0;
          apb_PSLVERR <= PSLVERR;
        end
      end
    endcase
  end                                                           //If slave is not ready remain in this state until slave responds with Pready
end

//Block 7
//Tack Pulse from APB to AHB
always@(posedge PCLK or negedge PRESETn)begin
  if(!PRESETn)begin
    apb_tack_toggle <= 1'b0;
  end else begin
    if(apb_tack) apb_tack_toggle <= ~apb_tack_toggle;   //Toggle whenever a transaction is complete
  end
end

//Block 8
//Synchronize the tack pulse with HCLK
always@(posedge HCLK or negedge HRESETn)begin
  if(!HRESETn)begin
    apb_tack_sync <= 'd0;
  end else begin
    apb_tack_sync <= {apb_tack_sync[1:0], apb_tack_toggle};
  end
end

//tack pulse generated with HCLK
assign apb_tack_pulse = apb_tack_sync[2] ^ apb_tack_sync[1];

//Block 9
//APB to AHB response
always@(posedge HCLK or negedge HRESETn)begin
  if(!HRESETn)begin
    apb_tack_pulse_Q1 <= 0;
    apb_PRDATA_HCLK   <= 0;
    apb_PSLVERR_HCLK  <= 0;
  end else begin
    apb_tack_pulse_Q1 <= apb_tack_pulse;
    if(apb_tack_pulse)begin
      apb_PRDATA_HCLK  <= apb_PRDATA;
      apb_PSLVERR_HCLK <= apb_PSLVERR;
    end
  end
end

//All for Byte Aligned Bus and Address
reg [127:0] pstrb;              //strb to specify upto 128 byte lanes (i.e max data bus size of AHB Bus)
reg [6:0]   addr_mask;          //addr mask size is wrong for max 1024 bits we need to mask 10 bits
always@(*)begin
  case(DATA_WIDTH/8)            //Address Mask                                  //I felt section has wrong code for address mask
    'd0: addr_mask <= 'h00;
    'd1: addr_mask <= 'h01;     //Mask no bits of address if 8 bits of data
    'd2: addr_mask <= 'h03;     //Mask 1 bit for 16 bits
    'd3: addr_mask <= 'h07;     //Mask 2 bits for 24 bits
    'd4: addr_mask <= 'h0f;     //Mask 2 bits for 32 bits
    'd5: addr_mask <= 'h1f;     //Mask 3 bits for 40 bits
    'd6: addr_mask <= 'h3f;     //Mask 3 bits for 48 bits
    'd7: addr_mask <= 'h7f;     //Mask 3 bits for 56 bits

                                //for 1024 bits of bus we need to mask 10 bits
  endcase

  case(ahb_HSIZE)                       //for upto 32 bit data bus only 1 and 2 are valid
    'd1:     pstrb <= 'h3;              //if HSIZE is 1 then the data bus contains 2 bytes of data in two byte lanes (using 16 bits of 32 bit bus)
    'd2:     pstrb <= 'hf;              //if HSIZE is 2 then the data bus contains 4 bytes of data in four byte lanes (using 32 bits of 32 bit bus)
    'd3:     pstrb <= 'hff;             //if HSIZE is 3 then the data bus contains 8 bytes of data in eight byte lanes (using 64 bits of 64 bit bus)
    'd4:     pstrb <= 'hffff;
    'd5:     pstrb <= 'hffff_ffff;
    'd6:     pstrb <= 'hffff_ffff_ffff_ffff;
    'd7:     pstrb <= 'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;        //specified upto 1024 bit bus for parameterized design (128 bits of 1)
    default: pstrb <= 'h1;
  endcase
end
//Block 10
//Strobe signal for the slaves
////strb signal indicates which part of data bus has valid data
always@(posedge HCLK or negedge HRESETn)begin
  if(!HRESETn)begin
    lcl_PSTRB <= 0;
  end else begin
    lcl_PSTRB <= pstrb[DATA_WIDTH/8-1:0] << (ahb_HADDR & addr_mask);
  end
end 
 /* always@(posedge HCLK or negedge HRESETn)
    begin
      if(HRESETn == 0) begin
       HREADYOUT <= 0;
        HRDATA   <= 0;
        HRESP    <= 0;
    end
    else begin
    if(HSEL) begin
      
       HREADYOUT <= 1;
    end
    end
    end
  always@(posedge PCLK or negedge PRESETn)
    begin
      if(PRESETn == 0) begin
        
    end
    else begin
    if(HSEL) begin
       @(posedge HCLK);
       HREADYOUT <= 1;
    end
    end
    end*/
endmodule