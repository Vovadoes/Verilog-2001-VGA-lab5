`timescale 1ns / 1ps

`define CHAR_WIDTH	9 			// Ширина буквы (в пикселях)
`define CHAR_HEIGHT	12  		// Высота буквы (в пикселях)

`define SPACE_HOR	12			// Размер отступа для вывода по горизонтали в пикселях
`define SPACE_VER	9			// Размер отступа для начального вывода по вертикали в пикселях
`define KERNING		3			// Размер отступа между строками и символами в строке в пикселях

`define A 5'd10					// Адрес, по которому в памяти алфавита расположен символ "A"
`define B 5'd11					// Адрес, по которому в памяти алфавита расположен символ "B"
`define C 5'd12					// Адрес, по которому в памяти алфавита расположен символ "C"
`define D 5'd13					// Адрес, по которому в памяти алфавита расположен символ "D"
`define E 5'd14					// Адрес, по которому в памяти алфавита расположен символ "E"
`define F 5'd15					// Адрес, по которому в памяти алфавита расположен символ "F"
`define L 5'd16					// Адрес, по которому в памяти алфавита расположен символ "L"
`define O 5'd17					// Адрес, по которому в памяти алфавита расположен символ "O"
`define R 5'd18					// Адрес, по которому в памяти алфавита расположен символ "R"
`define S 5'd19					// Адрес, по которому в памяти алфавита расположен символ "S"
`define T 5'd20					// Адрес, по которому в памяти алфавита расположен символ "T"
`define S0 4'd0
`define U 5'd21					// Адрес, по которому в памяти алфавита расположен символ "U"
`define COLON 5'd22				// Адрес, по которому в памяти алфавита расположен символ ":"
`define SCREAMER 5'd23			// Адрес, по которому в памяти алфавита расположен символ восклицательного знака
`define SPACE 5'd24 			// Адрес, по которому в памяти алфавита расположен символ пробела

`define RESULT_VGA_STR_SIZE 12	// Размер строки (в количестве символов) в случае вывода результата
`define ERROR_VGA_STR_SIZE 8	// Размер строки (в количестве символов) в случае вывода ошибки
`define MAX_STRING_SIZE 15		// Максимальный размер строки (в количестве символов)

`define S0 4'd0
`define S1 4'd1
`define S2 4'd2
`define S3 4'd3
`define S4 4'd4
`define S5 4'd5
`define S6 4'd6
`define S7 4'd7

`define SHIFT_1 4'd9
`define SHIFT_2 4'd10
`define SHIFT_3 4'd11
`define SHIFT_4 4'd12
`define SHIFT_5 4'd13
`define CLEAR_1 4'd14
`define CLEAR_2 4'd15

module VGA_Manager
#(
	parameter ALPHABET_SIZE = 25,						// Количество символов в алфавите по умолчанию
	parameter COLOR_COUNT = 4							// Количество цветов по умолчанию для отображения 
)
(
	input clk,	// Синхросигнал
	input [15:0] result_in,	 // Шина для получения результата с выхода основного автомата
	input [$clog2(COLOR_COUNT)-1:0] error_in,			// Шина для получения ошибки с выхода основного автомата
	input ready_to_change,								// Сигнал о том, что на вход пришли новые данные, которые следует отобразить
	
	input vgaBegin,										// Вход для сигнала о начале отрисовки кадра
	input vgaEnd,										// Вход для сигнала об окончании отрисовки кадра
 
	input [$clog2(`WIDTH * `HEIGHT)-1:0] mem_addr_in,	// Вход для адреса ячейки памяти, из которой будет осуществляться чтение
	output [`COLOR_BIT_SIZE-1:0] mem_data_out			// Выход, на который будет подано значение из ячейки памяти (цвет пикселя по запрошенному адресу)
);

reg [3:0] state;	// Регистр состояния
parameter MAX_PIXEL_COUNT = `WIDTH * `HEIGHT;									// Общее количество пикселей на экране
parameter STR_WITH_KERNING_PIXEL_COUNT = `WIDTH * (`CHAR_HEIGHT + `KERNING);	// Количество пикселей, на которое необходимо сдвинуть кадр

reg [15:0] 						result_reg;										// Внутренний регистр для хранения результата с выхода основного автомата
reg [$clog2(COLOR_COUNT)-1:0] 	error_reg;										// Внутренний регистр для хранения ошибки с выхода основного автомата

reg [$clog2(`WIDTH)-1:0] 		x0;												// Регистр для хранения координаты (по оси абсцисс) начала размещения очередного символа строки
reg [$clog2(`HEIGHT)-1:0] 		y0;												// Регистр для хранения координаты (по оси ординат) начала размещения очередного символа строки
reg [$clog2(`CHAR_WIDTH)-1:0] 	x_char;											// Координата (по оси абсцисс) пикселя внутри символа при размещении одного символа
reg [$clog2(`CHAR_HEIGHT)-1:0] 	y_char;											// Координата (по оси ординат) пикселя внутри символа при размещении одного символа

reg [$clog2(`MAX_STRING_SIZE)-1:0] 	char_counter;								// Счётчик символов в строке
reg [0:$clog2(ALPHABET_SIZE)-1] 	string_reg [0:`MAX_STRING_SIZE-1];			// Регистр для хранения размещаемой в памяти строки
reg [`COLOR_BIT_SIZE-1:0] 			char_color_list [0:`MAX_STRING_SIZE-1];		// Регистр для хранения цветов символов в размещаемой строке (в порядке их следования в строке)
reg [$clog2(`MAX_STRING_SIZE)-1:0] 	string_size;								// Регистр для хранения размера текущей размещаемой строки

reg [0:`CHAR_WIDTH-1] 				char_reg [0:`CHAR_HEIGHT-1];				// Регистр для хранения текущего размещаемого символа
reg [`COLOR_BIT_SIZE-1:0] 			color_reg;									// Регистр для хранения цвета текущего размещаемого символа

reg [`COLOR_BIT_SIZE-1:0] 	color_arr [0:COLOR_COUNT-1];						// Регистр для хранения всех возможных цветов для отображения
reg [0:`CHAR_WIDTH-1] 		alphabet [0:`CHAR_HEIGHT-1] [0:ALPHABET_SIZE-1];	// Регистр для хранения всех символов, из которых может состоять строка для отображения

reg [$clog2(MAX_PIXEL_COUNT)-1:0] 	frame_buf_addr;								// Регистр для хранения адреса ячейки памяти, из которой производится чтение
reg [`COLOR_BIT_SIZE-1:0] 			frame_buf_data_in;							// Регистр для хранения данных, которые требуют записи в память
wire [`COLOR_BIT_SIZE-1:0] 			frame_buf_data_out;							// Шина для выходного значения, считанного из памяти
reg frame_buf_we;																// Регистр сигнала, разрешающего запись в память

reg [$clog2(MAX_PIXEL_COUNT):0] 	pixel_counter;								// Счётчик пикселей

reg  [0:`WIDTH-1] bitmap [`HEIGHT-1:0];        // битмап рисунка
// Экземпляр True Dual Port BRAM
blk_mem_gen_0 frame_buf 
(
	// Порт А используется для работы с текущем модулем
	.clka(clk),					// синхросигнал для порта А
	.wea(frame_buf_we),			// сигнал, разрешающий запись в память и чтение из памяти по порту А
	.addra(frame_buf_addr),		// адрес для работы с портом А
	.dina(frame_buf_data_in),	// значение для загрузки в память по порту А
	.douta(frame_buf_data_out),	// значение из памяти по порту А
	
	// Порт В используется для работы с модулем VGA
	.clkb(clk),					// синхросигнал для порта В
	.web(1'b0),					// сигнал, разрешающий чтение из памяти по порту В
	.addrb(mem_addr_in),		// адрес для работы с портом В
	.dinb(0),					// значение для загрузки в память по порту В
	.doutb(mem_data_out)		// значение из памяти по порту В
);

integer i, j, k; // 32-разрядные регистры для хранения переменных

initial 
begin
	// Заполнение памяти путем чтения из соответствующих файлов (чтение бинарное)
	$readmemb("colors.mem", color_arr);
	$readmemb("alphabet.mem", alphabet);
	$readmemb("image_1.mem", bitmap);	
		
	// Сброс памяти для строки (string_reg) и цветов символов (char_color_list)		
	for (i = 0; i < `MAX_STRING_SIZE; i = i + 1)
		begin
			string_reg[i] <= 0;
			char_color_list[i] <= 0;
		end
		
	// Сброс памяти для символа	(char_reg)
	for (j = 0; j < `CHAR_HEIGHT; j = j + 1)
		char_reg[j] <= 0;	
	color_reg <= 0;
	
	result_reg <= 0;
	error_reg <= 0;
	
	x0 <= `SPACE_HOR;
	y0 <= `SPACE_VER;
	
	frame_buf_addr <= 0;
	frame_buf_data_in <= 0;
	frame_buf_we <= 0;
	
	state <= `S0;
end

// Основной блок
always@(posedge clk)
begin: main
	case(state)		
		`S0:
		  if (ready_to_change) begin
		      y0 <= 0;
		      x0 <= 0;
		      pixel_counter <= 0;
		      state <= `S1;
		  end
		
		`S1:
		  begin
		    begin
              frame_buf_we <= 1;
              frame_buf_data_in <= {bitmap[y0][x0], bitmap[y0][x0], bitmap[y0][x0]};
              frame_buf_addr <= pixel_counter;
              state <= `S2;
			end
		  end
		
		`S2:
          begin
            frame_buf_we <= 0;
			x0 <= x0 + 1;
			pixel_counter <= pixel_counter + 1;
			state <= `S3;
		  end
		
		`S3:
          begin
			if (x0 == `WIDTH)
			begin
		      if (y0 == `HEIGHT - 1)
		      begin
		        state <= `S6;
		      end else
		      begin
		        y0 <= y0 + 1;
		        x0 <= 0;
		        state <= `S1;
		      end
		    end else
		    begin
		      state <= `S1;
		    end
		  end
		
		// Состояние ожидания прихода сигнала о начале отрисовки одного кадра	
		`S6:
			if (vgaBegin)
				state <= `S7;
		
		// Состояние ожидания прихода сигнала об окончании отрисовки одного кадра		
		`S7:
			if (vgaEnd)
				state <= `S0;					
	endcase
end

vio_1 vio1(
.clk(clk),
.probe_in0(string_reg[0]),
.probe_in1(string_reg[1]),
.probe_in2(string_reg[2]),
.probe_in3(string_reg[3]),
.probe_in4(string_reg[4]),
.probe_in5(string_reg[5]),
.probe_in6(string_reg[6]),
.probe_in7(string_reg[7]),
.probe_in8(string_reg[8]),
.probe_in9(string_reg[9]),
.probe_in10(string_reg[10]),
.probe_in11(string_reg[11]),
.probe_in12(color_reg),
.probe_in13(result_reg),
.probe_in14(error_reg),
.probe_in15(char_counter)
);

endmodule