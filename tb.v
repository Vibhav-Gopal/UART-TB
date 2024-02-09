module tb();
  integer seedTx = 69; //Seed for Random TX data
  
  integer i;
  integer framesSent=0;
  integer correctFrames = 0;
  
  // Declarations for TX module
  reg txreset;
  reg txclk;
  reg ldtx;
  reg [7:0] tx_data;
  reg tx_en;
  wire tx_out;
  wire tx_empty;
  
  reg [9:0] actualtxout = 0;
  integer tx_index_var;
  integer loop_var;
  
  // Declarations for RX Module
  reg rxreset;
  reg rxclk;
  reg uldrx;
  wire [7:0] rx_data;
  wire rx_en;
  wire rx_in;
  wire rx_empty;
  
  // UART TX instantiation
  uart_tx mytx(
    reset,
    txclk,
    ldtx,
    tx_data,
    tx_en,
    tx_out,
    tx_empty
  );
  
  //UART RX instantiation
  uart_rx myrx(
    rxreset,
    rxclk,
    uldrx,
    rx_data,
    rx_en,
    rx_in,
    rx_empty
  );
  

  //TX Clock
  initial
    txclk=0;
  always begin
    #32 txclk = !txclk;
  end
  
  //RX Clock
  initial rxclk=0;
  always begin
    #2 rxclk = !rxclk;
  end
  
  initial begin
    rxreset = 0;
    txreset = 0;
    ldtx=0;
    
  end


  assign rx_en = tx_en;
  assign rx_in = tx_out;
  
  //Task to send random data using TX module
  task sendTx();
    begin
      tx_en =0;
      txreset =0;
      @(posedge txclk);
      txreset =1; // Reset module
      @(posedge txclk);
      txreset=0;
      @(posedge txclk);
      
      tx_data = $random(seedTx); // Get random data

      @(posedge txclk);
      ldtx=1; // Load into internal registers
      tx_en=1;
      @(posedge txclk);
      ldtx=0;
      
      for (i =0 ;i<9;i= i+1)begin // wait until all 10 bits are transmitted
        @(posedge txclk);
      end
      @(posedge txclk);
      tx_en=0;  // Disable TX
      for(i=0 ;i<7;i=i+1) @(posedge txclk); // Wait for 8 pulses to let RX module catch up
    end
  endtask

  //Task to check if frame sent is sent correctly
  task checkCurrentFrame;
    begin
      framesSent = framesSent + 1;
      if ( actualtxout[0] == 0 && actualtxout[9] == 1 && actualtxout[8:1] == tx_data) // Check for start, stop bits and actual content
        begin
        $display("Transmission check passed for %h",tx_data);
        end
        else 
          begin
          $display("Transmission check failed for %h",tx_data);
          end
        // Check if RX module received data correctly
      if(rx_data == tx_data) 
        begin
        $display("Reception check passed for %h",tx_data);
        end
      else 
        begin
        $display("Reception check failed for %h, received %h",tx_data,rx_data);
        end
      
        if(actualtxout[0] == 0 && actualtxout[9] == 1 && actualtxout[8:1] == tx_data && rx_data == tx_data) // increment correct frame counter
          correctFrames = correctFrames+1;
    end
  endtask
  
  initial begin
    tx_en = 0;
    uldrx=0;
    
    $random(seedTx);
    $dumpfile("dump.vcd"); // for EPWave
  $dumpvars;

    #500
    //Send 20 frames to check
    for(loop_var=0;loop_var<20;loop_var=loop_var+1)begin
      sendTx();#500;
    end
    #500
    $display("CHECKER STATS\nFRAMES SENT = %d, CORRECT FRAMES = %d\n",framesSent,correctFrames);
    $finish;
  end
  always begin
    //Unload data as soon as rx_en is de-asserted
        wait (!rx_empty);
    @(posedge rxclk);
    uldrx = 1;
    @(posedge rxclk);
    uldrx = 0;
    @(posedge rxclk);
  end
  
  always begin
    @(posedge txreset)
    actualtxout =0;
    tx_index_var = 0;
  end
  always begin
    @(posedge tx_en)
    @(negedge tx_out);
    while (tx_en) begin
      //Store tx_out as it is output
      @(posedge txclk);
      actualtxout[tx_index_var] = tx_out;
      tx_index_var = tx_index_var + 1;
    end
    // check each frame as soon as it is sent
    checkCurrentFrame;
  end
endmodule