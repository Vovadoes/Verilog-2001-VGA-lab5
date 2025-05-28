`timescale 1ns / 1ns

module UART #
(
    localparam CLOCK_RATE = 100_000_000, // Частота ПЛИС XC7A100T-1CSG324 семейства Artix-7 (в Гц)
    localparam BAUD_RATE = 9600,	// Скорость передачи данных по UART (в бод)
    localparam ERROR_COUNT = 3, // Количество возможных ошибок основного автомата
    localparam DIGIT_COUNT = 4, // Разрядность входных данных, представленных в 16-ричном виде
    localparam MOD_DELITEL = 16000
)
(
	input clk,		// Синхросигнал
	input RsRx,	 	// Бит принимаемых данных (UART_RX)
	output RsTx, 	// Бит отправляемых данных (UART_TX)	
	output [7:0] AN,
    output [6:0] SEG,
    
    output [3:0] vgaRed,	// Глубина красного цвета, закодированного четырьмя битами
	output [3:0] vgaGreen,  // Глубина зелёного цвета, закодированного четырьмя битами
	output [3:0] vgaBlue,	// Глубина синего цвета, закодированного четырьмя битами
	
	output  Hsync,	// Выход для сигнала горизонтальной синхронизации
	output  Vsync	// Выход для сигнала вертикальной синхронизации		

);

// FSM
wire [15:0] FSM_Data_Input;	  // Шина входных данных автомата
wire FSM_Ready_Input;		  // Сигнал о том, что данные на входе автомата сформированы
wire FSM_Ready_Output;		  // Сигнал о том, что данные на выходе автомата сформированы
wire [15:0] FSM_Data_Output;  // Шина выходных данных автомата
wire [1:0] FSM_Error_Output;  // Шина ошибок на выходе автомата

reg CLOCK_ENABLE = 0;
always @(posedge clk)
    CLOCK_ENABLE <= ~CLOCK_ENABLE;

reg [31:0] shift_register;
reg [7:0] an_mask;

wire clk_div_out;

reg [1:0] R_E;
reg [6:0] cnt;
wire vga_clk;
wire [$clog2(`WIDTH * `HEIGHT)-1:0] mem_addr;
wire [`COLOR_BIT_SIZE-1:0] mem_data;
wire vgaBegin;
wire vgaEnd;


initial
begin
    R_E <= 0;
    an_mask <= 8'b00000000;
end

always@(posedge clk)
begin
    if (FSM_Ready_Input) begin
        shift_register <= FSM_Data_Input;
    end
end

delitel #(.mod(MOD_DELITEL)) clk_div1 ( // 8192
    .clk(clk),
    .out(clk_div_out)
);

SevenSegmentLED seg(
    .clk(clk_div_out),
    .RESET(1'b0),
    .NUMBER(shift_register),
    .AN_MASK(an_mask),
    .AN(AN),
    .SEG(SEG)
);

// Автомат, занимающийся менеджментом входных данных с UART
UART_Input_Manager #(.DIGIT_COUNT(DIGIT_COUNT)) uart_input_manager 
(
	.clk(clk), 		// Вход синхросигнала
	.reset(reset),
	.RsRx(RsRx),
	.out(FSM_Data_Input),// Выход со значением для входа основного автомата
	.ready_out(FSM_Ready_Input)	// Выход - сигнал о том, что данные на выходе <number_out> сформированы
);
// Автомат, занимающийся менеджментом выходных данных на UART
UART_Output_Manager #(.ERROR_COUNT(ERROR_COUNT)) uart_output_manager 
(
	.clk(clk), // Вход: Синхросигнал
	.reset(reset),
	.ready_in(FSM_Ready_Output), // Вход: сигнал о том, что данные для отправки по UART сформированы
	.data_in(FSM_Data_Output),   // Вход: данные для отправки по UART
	.error_in(FSM_Error_Output), // Вход: данные об ошибках для отправки по UART
	.RsTx(RsTx)
);

wire [3:0] VGA_M_state = manager.state;

VGA_Manager manager(
    .clk(vga_clk),
    .result_in(shift_register),
    .error_in(R_E),
    .ready_to_change(FSM_Ready_Input),
    .vgaBegin(vgaBegin),
    .vgaEnd(vgaEnd),
    .mem_addr_in(mem_addr),
    .mem_data_out(mem_data)
);

wire [1:0] VGA_state = vga.state;

VGA vga(
    .clk(vga_clk),
    .mem_data(mem_data),
    .mem_addr(mem_addr),
    .vgaRed(vgaRed),
	.vgaGreen(vgaGreen),
	.vgaBlue(vgaBlue),
	.Hsync(Hsync),
	.Vsync(Vsync),	
	.vgaBegin(vgaBegin),
	.vgaEnd(vgaEnd)
);

clk_wiz_0(
    .clk_in1(clk),
    .clk_out1(vga_clk)
);

//fsm #(
//    .DIGIT_COUNT(DIGIT_COUNT),
//    .ERROR_COUNT(ERROR_COUNT)
//) FSM(
//	.clk(clk),
//	.R_I(FSM_Ready_Input),
//	.reset(0),
//	.R_O(FSM_Ready_Output),
//	.dataIn(FSM_Data_Input),
//	.dataOut(FSM_Data_Output),
//	.error(FSM_Error_Output)
//);

//main main(
//    .clk(clk),
//    input PS2_clk,
//    input PS2_dat,
//    output [7:0] AN,
//    output [6:0] SEG
//);
vio_0 vio0(
    .clk(clk),
    .probe_in0(vgaRed),
    .probe_in1(vgaGreen),
    .probe_in2(vgaBlue),
    .probe_in3(Hsync),
    .probe_in4(Vsync),
    .probe_in5(FSM_Ready_Output),
    .probe_in6(FSM_Data_Output),
    .probe_in7(VGA_M_state),
    .probe_in8(VGA_state)
);
endmodule
