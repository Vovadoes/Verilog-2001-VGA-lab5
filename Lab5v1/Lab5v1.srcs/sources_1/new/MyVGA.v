`timescale 1ns / 1ps

`define WIDTH 800 				// ширина экрана в пикселях
`define H_FRONT_PORCH 56 		// число тактов FRONT_PORCH по горизонтали
`define H_BACK_PORCH 64 		// число тактов BACK_PORCH по горизонтали
`define H_SYNC 120 				// число тактов импульса сигнала синхронизации по горизонтали

`define HEIGHT 600 				// высота экрана в пикселях
`define V_FRONT_PORCH 37 		// число тактов FRONT_PORCH по вертикали
`define V_BACK_PORCH 23 		// число тактов BACK_PORCH по вертикали
`define V_SYNC 6 				// число тактов импульса сигнала синхронизации по вертикали

`define RESET 				4'd0
`define HOR_PERIOD			4'd1
`define H_NOT_ACTIVE_PERIOD 4'd2
`define V_NOT_ACTIVE_PERIOD 4'd3

`define COLOR_BIT_SIZE 3		// Число бит, требуемых для кодирования цвета 

module MyVGA(
	input clk, // Синхросигнал
	
	input [`COLOR_BIT_SIZE-1:0] mem_data,				// Цвет текущего пикселя, который приходит из памяти
	output reg [$clog2(`WIDTH * `HEIGHT)-1:0] mem_addr, // Адрес для взятия пикселя из памяти
	
	output [3:0] vgaRed,	// Глубина красного цвета, закодированного четырьмя битами
	output [3:0] vgaGreen,  // Глубина зелёного цвета, закодированного четырьмя битами
	output [3:0] vgaBlue,	// Глубина синего цвета, закодированного четырьмя битами
	
	output reg Hsync,	// Выход для сигнала горизонтальной синхронизации
	output reg Vsync,	// Выход для сигнала вертикальной синхронизации		

	output reg vgaBegin, // Сигнал о начале отрисовки кадра
	output reg vgaEnd	 // Сигнал об окончании отрисовки кадра
);
reg [`COLOR_BIT_SIZE-1:0] vgaColor;	// Цвет, считанный из памяти

// Блок перевода однобитного цвета в четырёхбитный
assign   vgaRed = vgaColor[2] ? 4'hF : 0;
assign vgaGreen = vgaColor[1] ? 4'hF : 0;
assign  vgaBlue = vgaColor[0] ? 4'hF : 0;

reg vga_clk; // Синхросигнал VGA

reg [$clog2(`WIDTH + `H_FRONT_PORCH + `H_SYNC + `H_BACK_PORCH)-1:0] H_counter; // Счётчик сигнала синхронизации по горизонтали
reg [$clog2(`HEIGHT + `V_FRONT_PORCH + `V_SYNC + `V_BACK_PORCH)-1:0] V_counter; // Счётчик сигнала синхронизации по вертикали

reg [1:0] state; // Регистр состояния
	
// T-триггер, осуществляющий деление частоты синхросигнала	
always@(posedge clk)
begin
	vga_clk <= ~vga_clk;
end
// Блок инициализации
initial 
begin
	vga_clk <= 0;
	vgaColor <= 0;
	V_counter <= 0;
	H_counter <= 0;
	mem_addr <= 0;
	state <= `RESET;
	Hsync <= 1;
	Vsync <= 1;
end
// Основной блок
always@(posedge vga_clk)
begin
    if (H_counter < `WIDTH && V_counter < `HEIGHT)
    begin
        Hsync <= 1;
        Vsync <= 1;
        vgaColor <= mem_data;
        mem_addr <= mem_addr + 1;
        H_counter <= H_counter + 1;
    end
    else if (H_counter == (`WIDTH + `H_FRONT_PORCH + `H_SYNC + `H_BACK_PORCH - 1) && V_counter == (`HEIGHT + `V_FRONT_PORCH + `V_SYNC + `V_BACK_PORCH - 1))
    begin
        Hsync <= 1;
        Vsync <= 1;
        H_counter <= 0;
        V_counter <= 0;
        vgaColor <= 0;
        mem_addr <= 0;
    end
    else if (H_counter == (`WIDTH + `H_FRONT_PORCH + `H_SYNC + `H_BACK_PORCH - 1))
    begin
        Hsync <= 1;
        Vsync <= 1;
        H_counter <= 0;
        V_counter <= V_counter + 1;
        vgaColor <= 0;
        mem_addr <= mem_addr + 1;
    end
    else if (H_counter > (`HEIGHT - 1) && H_counter < (`WIDTH + `H_FRONT_PORCH))
    begin
        Hsync <= ~(H_counter > (`WIDTH + `H_FRONT_PORCH) && H_counter < (`WIDTH + `H_FRONT_PORCH + `H_SYNC));
    end
end
endmodule