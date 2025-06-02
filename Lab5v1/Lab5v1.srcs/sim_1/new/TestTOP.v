`timescale 1ns / 1ps


module TestTOP();

localparam CLOCK_RATE = 100_000_000;
//localparam BAUD_RATE = 9600;
localparam BAUD_RATE = 115200;
localparam ERROR_COUNT = 3;
localparam DIGIT_COUNT = 4;
localparam MOD_DELITEL = 16000;

reg clk;

wire RsTx;
wire [7:0] AN;
wire [6:0] SEG;
wire [3:0] vgaRed;
wire [3:0] vgaGreen;
wire [3:0] vgaBlue;
wire Hsync;
wire Vsync;

localparam LENGHT_ARR = 14;

reg clk;
always #(10) clk <= ~clk;

wire RsRx;
wire RsTx;

reg [7:0] UART_TX_Data_In;
reg UART_TX_Ready_In;
wire tx;
wire idle;

reg [7:0] UART_TX_Data_Arr [0:LENGHT_ARR - 1];

reg [0:2] state;

integer iter;

assign RsRx = tx;

initial clk = 0;
always #5 clk = ~clk;

initial
begin
    clk = 0;
    state = 0;
    UART_TX_Data_In = 0;
    UART_TX_Ready_In = 0;
    iter = 0;
    
    UART_TX_Data_Arr[0] = 8'h32;
    UART_TX_Data_Arr[1] = 8'h41;
    UART_TX_Data_Arr[2] = 8'h36;
    UART_TX_Data_Arr[3] = 8'h36;
    UART_TX_Data_Arr[4] = 8'h0D;
    UART_TX_Data_Arr[5] = 8'h43;
    UART_TX_Data_Arr[6] = 8'h30;
    UART_TX_Data_Arr[7] = 8'h30;
    UART_TX_Data_Arr[8] = 8'h30;
    UART_TX_Data_Arr[9] = 8'h0D;
    UART_TX_Data_Arr[10] = 8'h43;
    UART_TX_Data_Arr[11] = 8'h30;
    UART_TX_Data_Arr[12] = 8'h30;
    UART_TX_Data_Arr[13] = 8'h30;
    UART_TX_Data_Arr[14] = 8'h0D;
end

always@ (posedge clk)
begin
    case(state)
        (0): 
        begin
            if (iter == LENGHT_ARR)
            begin
                state <= 2;
            end
            else if (idle)
            begin
                UART_TX_Data_In <= UART_TX_Data_Arr[iter];
                UART_TX_Ready_In <= 1;
                state <= 1;
            end
        end
        
        
        (1): 
        begin
            UART_TX_Ready_In <= 0;
            state <= 0;
            iter <= iter + 1;
        end
        
        
        (2):
        begin
            
        end
        
    endcase
end


UART_TX #(
    .CLOCK_RATE(CLOCK_RATE),
    .BAUD_RATE(BAUD_RATE)
) uartTx1 (
    .clk(clk),
    .UART_TX_Data_In(UART_TX_Data_In),
    .UART_TX_Ready_In(UART_TX_Ready_In),
    .tx(tx),
    .idle(idle)
);

UART #(
    .CLOCK_RATE(CLOCK_RATE),
    .BAUD_RATE(BAUD_RATE),
    .ERROR_COUNT(ERROR_COUNT),
    .DIGIT_COUNT(DIGIT_COUNT),
    .MOD_DELITEL(MOD_DELITEL)
) UART1 (
    .clk(clk),
    .RsRx(RsRx),
    .RsTx(RsTx),
    .AN(AN),
    .SEG(SEG),
    .vgaRed(vgaRed),
    .vgaGreen(vgaGreen),
    .vgaBlue(vgaBlue),
    .Hsync(Hsync),
    .Vsync(Vsync)
  );

endmodule
