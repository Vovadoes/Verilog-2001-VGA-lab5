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

reg [`HEIGHT-1:0] bitmap [0:`WIDTH-1];        // битмап рисунка
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
	$readmemb("alphabet.mem", bitmap);	
		
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
		// Сброс
//		`S0:
//			begin
//				char_counter <= 0;
//				x0 <= `SPACE_HOR;
				
//				state <= `S1;
//			end
		
//		// Ожидание прихода новых данных с выхода основного автомата
//		`S1:
//			// Если пришли
//			if (ready_to_change)
//				begin
//					// Запись результата и ошибки на внутренние регистры
//					result_reg <= result_in;
//					error_reg <= error_in; 
					
//					state <= `S2;
//				end
				
//		// 	Состояние формирования выходной строки
//		`S2:
//			begin
//				// Если в результате работы основного автомата была сформирована ошибка на выходе
//				if (error_reg != 0)
//					begin
//						// Формирование регистра, хранящего строку (хранятся адреса символов из алфавита)
//						string_reg[0] <= `E;
//						string_reg[1] <= `R;
//						string_reg[2] <= `R;
//						string_reg[3] <= `O;
//						string_reg[4] <= `R;
//						string_reg[5] <= `SPACE;
//						string_reg[6] <= error_reg;
//						string_reg[7] <= `SCREAMER;
						
//						// Запись размера строки в регистр
//						string_size <= `ERROR_VGA_STR_SIZE;
						
//						// Цикл формирования регистра цветов символов в строке
//						for (i = 0; i < `ERROR_VGA_STR_SIZE; i = i + 1)
//							// Если текущий символ - номер ошибки
//							if (i == 6)
//								char_color_list[6] = color_arr[error_reg]; // формируется цвет согласно номеру ошибки
//							// Стандартный текст выводится белым цветом
//							else
//								char_color_list[i] = color_arr[0]; // соответствующий цвет лежит под индексом 0 в массиве цветов
//					end
//				else
//					// Аналогично строке ошибки
//					begin
//						string_reg[0] <= `R;
//						string_reg[1] <= `E;
//						string_reg[2] <= `S;
//						string_reg[3] <= `U;
//						string_reg[4] <= `L;
//						string_reg[5] <= `T;
//						string_reg[6] <= `COLON;
//						string_reg[7] <= `SPACE;
//						string_reg[8] <= result_reg[15-:4];
//						string_reg[9] <= result_reg[11-:4];
//						string_reg[10] <= result_reg[7-:4];
//						string_reg[11] <= result_reg[3-:4];
//						string_size <= `RESULT_VGA_STR_SIZE;
						
//						for (k = 0; k < `RESULT_VGA_STR_SIZE; k = k + 1)
//							char_color_list[k] = color_arr[0];
//					end
//				state <= `S3;
//			end
			
//		// Состояние-менеджер подготовки кадра к отрисовке
//		`S3:
//			// Если все символы строки были размещены в памяти кадра
//			if (char_counter == string_size)
//				begin
//					y0 <= y0 + `CHAR_HEIGHT + `KERNING; // подсчёт новой координаты по оси ординат для следующей строки
//					state <= `S6;
//				end
//			else				// Если требуется сдвиг (Строка не может быть размещена в памяти кадра по текущим координатам)
//				if (y0 + `CHAR_HEIGHT >= `HEIGHT)
//					begin
//						y0 <= y0 - `CHAR_HEIGHT - `KERNING; 			// Возвращаемся по оси ординат на одну строку наверх
//						frame_buf_addr <= STR_WITH_KERNING_PIXEL_COUNT; // Подготовка адреса первого пикселя, который будет сдвинут
//						pixel_counter <= STR_WITH_KERNING_PIXEL_COUNT;	// В счётчик пикселей (которые будут сдвинуты) заносится номер пикселя, который будет сдвинут первым
//						state <= `SHIFT_1;
//					end
//				// Иначе происходит подготовка к размещению в память очередного символа в строке 
//				else
//					begin
//						// Для символа формируется его очертание (из алфавита)
//						for (i = 0; i < `CHAR_HEIGHT; i = i + 1)
//							char_reg[i] <= alphabet[i][string_reg[char_counter]];
						
//						// Установка цвета для отрисовки символа
//						color_reg <= char_color_list[char_counter];
						
//					// Сброс координат пикселей внутри символа в ноль
//						x_char <= 0; y_char <= 0;
						
//						// Счётчик пикселей определяется порядковым номером стартового пикселя текущего символа (при размещении в памяти кадра)
//						pixel_counter <= y0 * `WIDTH + x0;

//						state <= `S4;
//					end
		
//		// Состояние сдвига 1
//		`SHIFT_1:
//			// Если ещё не все пиксели сдвинуты
//			if (pixel_counter < MAX_PIXEL_COUNT)	
//				state <= `SHIFT_2;
//			// Если все пиксели сдвинуты
//			else
//				begin
//					frame_buf_we <= 1; 														// Разрешение записи в память по порту А (для очистки пикселей внизу экрана)
//					frame_buf_addr <= MAX_PIXEL_COUNT - STR_WITH_KERNING_PIXEL_COUNT - 1;	// Рассчёт адреса первого пикселя, который должен быть очищен
//					state <= `CLEAR_1;
//				end
				
//		// Состояние сдвига 2	
//		`SHIFT_2:
//			begin
//				frame_buf_data_in <= frame_buf_data_out;						// На вход для записи в память подаётся значение с выхода памяти
				
//				frame_buf_we <= 1;												// Разрешается запись в память по порту А
//				frame_buf_addr <= pixel_counter - STR_WITH_KERNING_PIXEL_COUNT;	// Рассчитывается адрес, куда пиксель следует перенести при сдвиге 
//				pixel_counter <= pixel_counter + 1;								// Инкремент счётчика пикселей

//				state <= `SHIFT_3;
//			end
		
//		// Состояние сдвига 3
//		`SHIFT_3:
//			begin
//				frame_buf_we <= 0; // Запрет записи в память по порту А
//				state <= `SHIFT_4;
//			end
		
//		// Состояние сдвига 4
//		`SHIFT_4:
//			begin
//				frame_buf_addr <= pixel_counter; // Определение адреса следующего пикселя (ячейки памяти), который следует сдвинуть
//				state <= `SHIFT_1;
//			end
		
//		// Состояние очистки пикселей 1	
//		`CLEAR_1:
//			begin
//				// Если сброшены в ноль не все нужные пиксели (ячейки памяти)
//				if (frame_buf_addr < MAX_PIXEL_COUNT-1)
//					begin
//						frame_buf_data_in <= 0;	// На вход для записи подается ноль
//						frame_buf_we <= 0;		// Запрет записи по порту А
//						state <= `CLEAR_2;
//					end
//				// Все нужные пиксели были сброшены в ноль
//				else
//					begin
//						frame_buf_we <= 0;	// Запрет записи по порту А
//						state <= `S3;
//					end
//			end
		
//		// Состояние очистки пикселей 2
//		`CLEAR_2:
//			begin
//				frame_buf_addr <= frame_buf_addr + 1;	// Переход к следующему пикселю (адресу в памяти)
//				frame_buf_we <= 1;						// Разрешение записи в память по порту А
//				state <= `CLEAR_1;
//			end
		
//		// Состояние размещения символа в памяти	
//		`S4:
//			// Если символ был размещён в памяти
//			if (y_char == `CHAR_HEIGHT)
//				begin
//					frame_buf_we <= 0; 					// Запрет записи по порту А в память
//					char_counter <= char_counter + 1; 	// Увеличение счётчика символов (номер текущего символа) в строке на единицу
//					x0 <= x0 + `CHAR_WIDTH + `KERNING;	// Определение новой координаты по оси абсцисс для следующего символа
//					state <= `S3;
//				end
//			// Символ ещё не полностью размещён в памяти
//			else
//				// Если полностью размещена в памяти текущая строка пикселей в текущем символе
//				if (x_char == `CHAR_WIDTH)
//					begin
//						frame_buf_we <= 0;										// Запрет записи по порту А в память
//						y_char <= y_char + 1;									// Переход к следующей строке пикселей в текущем символе
//						x_char <= 0;											// Координата по оси абсцисс в рамках символа сбрасывается в ноль (размещение идёт слева направо)
//						pixel_counter <= pixel_counter + `WIDTH - `CHAR_WIDTH;	// Расчёт координаты следующей ячейки памяти для заполнения
//					end
//				else
//					begin
//						frame_buf_we <= 1;												// Разрешение записи по порту А в память
//						frame_buf_data_in <= char_reg[y_char][x_char] ? color_reg : 0;	// В зависимости от очертания символа: если текущий пиксель не должен быть закрашен, то заносится 0, иначе заносится цвет текущего символа
//						frame_buf_addr <= pixel_counter;								// Подготовка адреса для записи
//						state <= `S5;
//					end
		
//		// Состояние переход к следующему пикселю
//		`S5:
//			begin
//				x_char <= x_char + 1;				// Переход к следующему пикселю в текущей строке в текущем символе
//				pixel_counter <= pixel_counter + 1;	// Расчёт следующего адреса в памяти для записи
//				state <= `S4;
//			end	
		
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