module uart_tx (
reset          ,
txclk          ,
ld_tx_data     ,
tx_data        ,
tx_enable      ,
tx_out         ,
tx_empty       
);
// Port declarations
input        reset          ;
input        txclk          ;
input        ld_tx_data     ;
input  [7:0] tx_data        ;
input        tx_enable      ;
output       tx_out         ;
output       tx_empty       ;

// Internal Variables 
reg [7:0]    tx_reg         ;
reg          tx_empty       ;
reg          tx_over_run    ;
reg [3:0]    tx_cnt         ;
reg          tx_out         ;
reg [7:0]    rx_reg         ;

// UART TX Logic

always begin @ (posedge txclk or posedge reset)
if (reset) begin
  tx_reg        <= 0;
  tx_empty      <= 1;
  tx_over_run   <= 0;
  tx_out        <= 1;
  tx_cnt        <= 0;
end else begin
   if (ld_tx_data) begin
      if (!tx_empty) begin
        tx_over_run <= 0;
      end else begin
        tx_reg   <= tx_data;
        tx_empty <= 0;
      end
   end
   if (tx_enable && !tx_empty) begin
     if (tx_cnt == 0) begin
       tx_out <= 0;
     end
     if (tx_cnt > 0 && tx_cnt < 9) begin
        tx_out <= tx_reg[tx_cnt -1];
     end
     if (tx_cnt == 9) begin
       tx_out <= 1;
       tx_cnt <= 0;
       tx_empty <= 1;
     end
     tx_cnt <= tx_cnt + 1;

   end
   if (!tx_enable) begin
     tx_cnt <= 0;
   end
end
  end
endmodule
