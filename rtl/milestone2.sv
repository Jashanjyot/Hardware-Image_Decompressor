/* M1LESTONE 2
Copyright by Group 34
McMaster University
Ontario, Canada
*/


`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"
`include "RAM0_init.v"
`include "RAM1_init.v"

module milestone2(
		input logic CLOCK_50_I,							//50 MHz Clock
		input logic resetn,								// reset
		input logic M2_start,
		// SRAM //
		input logic [15:0] SRAM_read_data,
		output logic [15:0] SRAM_write_data,
		output logic [17:0] SRAM_address,
		output logic SRAM_we_n,
		output logic M2_finish
		
);

logic [6:0] RAM0_address_a;
logic [6:0] RAM0_address_b;
logic RAM0_wren_a, RAM0_wren_b;
logic [31:0] RAM0_read_data_a, RAM0_read_data_b;
logic [31:0] RAM0_write_data_a, RAM0_write_data_b;

logic [6:0] RAM1_address_a;
logic [6:0] RAM1_address_b;
logic RAM1_wren_a, RAM1_wren_b;
logic [31:0] RAM1_read_data_a, RAM1_read_data_b;
logic [31:0] RAM1_write_data_a, RAM1_write_data_b;

// DP RAM INSTANTIATION // 
RAM0_init RAM_inst0 (
	.address_a ( RAM0_address_a ),
	.address_b ( RAM0_address_b ),
	.clock ( CLOCK_50_I ),
	.data_a ( RAM0_write_data_a ),
	.data_b ( RAM0_write_data_b ),
	.wren_a ( RAM0_wren_a),
	.wren_b ( RAM0_wren_b ),
	.q_a ( RAM0_read_data_a ),
	.q_b ( RAM0_read_data_b )
	);

RAM1_init RAM_inst1 (
	.address_a ( RAM1_address_a ),
	.address_b ( RAM1_address_b ),
	.clock ( CLOCK_50_I ),
	.data_a ( RAM1_write_data_a ),
	.data_b ( RAM1_write_data_b ),
	.wren_a ( RAM1_wren_a ),
	.wren_b ( RAM1_wren_b ),
	.q_a ( RAM1_read_data_a ),
	.q_b ( RAM1_read_data_b )
);

M2_state_type M2_state;

// CONSTANTS //
parameter base_address = 18'd76800,
		S_prime_address = 8'd64,
		C_base_address = 8'd64,
		S_base_address = 8'd64;
// COUNTERS/LOGIC // 
logic [7:0] S_prime_count;
logic [6:0] C_count;
logic [6:0] S_count;
logic [6:0] S_offset;
logic [6:0] SC_count;
logic [2:0] row_count;
logic [6:0] col_count;
logic [17:0] curr_max_row;
logic [17:0] row_offset;
logic [17:0] col_offset;
logic fetch_Y;
logic signed [31:0] S_prime_C;
logic signed [31:0] S_result;
logic signed [31:0] S_prime_buf;
logic signed [31:0] SC_buf;
logic signed [31:0] S_buf;
logic [18:0] write_count;
logic [11:0] block_count;
//  //
logic [17:0] col;
logic [17:0] row;
		
// MULTIPLIER STUFF //
logic [31:0] op1;
logic [31:0] op2;
logic [31:0] op3;
logic [31:0] op4;
logic [63:0] result1_long;
logic [63:0] result2_long;
logic [31:0] result1;
logic [31:0] result2;

// flags
logic done_read;
logic done_write;
logic write_ready;
logic read_flag;
logic even_loop;
logic first_loop;
logic done_curr_state;


always_comb begin
	if(fetch_Y) row_offset = (row<<6) + (row<<8);
	else row_offset = (row<<7) + (row<<5);
	result1_long = op1*op2;
	result2_long = op3*op4;

	result1 = result1_long[31:0];
	result2 = result2_long[31:0];
end
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^//
// THESE TERINARY STATEMENTS DETERMINE IF IT IS Y LI OR UV LI
// 256*row + 64*row = 320*row <-- For Y fetching
// 128*row + 32*row = 160*row <-- For UV fetching

// FSM // 
always @(posedge CLOCK_50_I or negedge resetn) begin
	if(~resetn) begin
		col <= 9'd0;
		row <= 9'd0;
		op1 <= 32'd0;
		op2 <= 32'd0;
		op3 <= 32'd0;
		op4 <= 32'd0;
		S_prime_count <= 8'd0;
		col_count <= 7'd0;
		SC_count <= 7'd0;
		C_count <= 7'd0;
		S_count <= 7'd0;
		row_count <= 3'd0;
		col_count <= 7'd0;
		write_count <= 18'd0;
		col_offset <= 18'd0;
		block_count <= 12'd0;
		done_curr_state <= 1'b0;
		row <= 18'd0;
		col <= 18'd0;
		curr_max_row <= 18'd7;
		S_offset <= 7'd0;
		S_prime_C <= 32'd0;
		S_result <= 32'd0;
		S_buf <= 32'd0;
		S_prime_buf <= 32'd0;
		SC_buf <= 32'd0;
		even_loop <= 1'b1;
		first_loop <= 1'b1;
		SRAM_write_data <= 16'd0;
		SRAM_we_n <= 1'b1;
		SRAM_address <= 18'd0;
		fetch_Y <= 1'b1;
		RAM0_address_a <= 7'd0;
		RAM0_address_b <= 7'd0;
		RAM0_write_data_a <= 32'd0;
		RAM0_write_data_b <= 32'd0;
		RAM0_wren_a <= 1'b0;
		RAM0_wren_b <= 1'b0;
		RAM1_address_a <= 7'd0;
		RAM1_address_b <= 7'd0;
		RAM1_write_data_a <= 32'd0;
		RAM1_write_data_b <= 32'd0;
		RAM1_wren_a <= 1'b0;
		RAM1_wren_b <= 1'b0;
		
	end else begin
		case(M2_state)
		// LI FETCH 0 //
		M2_LI_FS0: begin
			if(M2_start) begin
				RAM0_wren_a <= 1'b0;
				// SRAM address will be equal to the base address + 320(or160)*row# + col#	
				SRAM_address <= base_address + row_offset + col;
				col <= col + 18'd1; // column number increments normally and add 1

				M2_state <= M2_LI_FS1;
			end
		end
		// LI FETCH 1 //
		M2_LI_FS1: begin // basically reading SRAM data while waiting for latency to catch up
			SRAM_address <= base_address + row_offset + col;
			col <= col + 18'd1;

			M2_state <= M2_LI_FS2;
		end
		// LI FETCH 2 //
		M2_LI_FS2: begin
			SRAM_address <= base_address + row_offset + col;
			col <= col + 18'd1;

			M2_state <= M2_LI_FS3;
		end
		// LI FETCH 3 //
		M2_LI_FS3: begin
			SRAM_address <= base_address + row_offset + col;
			col <= col + 18'd1;
			// enabling writing on DP RAM0 port A
			S_prime_buf <= SRAM_read_data; // write data being read from the SRAM directly to the DP RAM

			M2_state <= M2_LI_FS4;
		end
		// LI FETCH 4 //
		M2_LI_FS4: begin // lots of repetition in these next few states
			SRAM_address <= base_address + row_offset + col;
			col <= col + 18'd1;

			RAM0_wren_a <= 1'b1;
			RAM0_address_a <= S_prime_address + S_prime_count; // C is stored in 0-63 so must add S' base address of 64
			S_prime_count <= S_prime_count + 7'd1; // add one to move to next address after writing the current one
			RAM0_write_data_a[31:16] <= S_prime_buf; // write two values to one memory location to make multiplication more efficient
			RAM0_write_data_a[15:0] <= SRAM_read_data;
			
			M2_state <= M2_LI_FS5;
		end
		// LI FETCH 5 //
		M2_LI_FS5: begin
			RAM0_wren_a <= 1'b0;
			SRAM_address <= base_address + row_offset + col;
			col <= col + 18'd1;

			S_prime_buf <= SRAM_read_data;


			M2_state <= M2_LI_FS6;
		end
		// LI FETCH 6 //
		M2_LI_FS6: begin
			RAM0_wren_a <= 1'b1;
			SRAM_address <= base_address + row_offset + col;
			col <= col + 18'd1;

			// same idea
			RAM0_address_a <= S_prime_address + S_prime_count;
			S_prime_count <= S_prime_count + 7'd1;
			RAM0_write_data_a[31:16] <= S_prime_buf;
			RAM0_write_data_a[15:0] <= SRAM_read_data;


			M2_state <= M2_LI_FS7;
		end
		// LI FETCH 7 //
		M2_LI_FS7: begin
			RAM0_wren_a <= 1'b0;
			SRAM_address <= base_address + row_offset + col; // LAST VALUE OF ROW TO READ
			col <= col + 18'd1;

			S_prime_buf <= SRAM_read_data;


			M2_state <= M2_LI_FS8;
		end
		// LI FETCH 8 //
		M2_LI_FS8: begin
			RAM0_wren_a <= 1'b1;
			// Gonna finish writing the rest of the row in next few states
			RAM0_address_a <= S_prime_address + S_prime_count;
			S_prime_count <= S_prime_count + 7'd1;
			RAM0_write_data_a[31:16] <= S_prime_buf;
			RAM0_write_data_a[15:0] <= SRAM_read_data;


			M2_state <= M2_LI_FS9;
		end
		// LI FETCH 9 //
		M2_LI_FS9: begin
			RAM0_wren_a <= 1'b0;
			// Gonna finish writing the rest of the row in next few states
			S_prime_buf <= SRAM_read_data;


			M2_state <= M2_LI_FS10;
		end
		// LI FETCH 10 //
		M2_LI_FS10: begin
			RAM0_wren_a <= 1'b1;
			// Writing last value of the row here
			RAM0_address_a <= S_prime_address + S_prime_count;
			RAM0_write_data_a[31:16] <= S_prime_buf;
			RAM0_write_data_a[15:0] <= SRAM_read_data;
			
			
			// If finished reading block start calculating first S'C, otherwise fetch next row
			if(row==curr_max_row) begin 
				S_prime_count <= 7'd0;
				row <= curr_max_row - 18'd7;
				col_offset <= 18'd8;
				block_count <= block_count + 12'd1;
				M2_state <= M2_LI_SC0;
			end else begin
				M2_state <= M2_LI_FS0;
				S_prime_count <= S_prime_count + 7'd1;
				row <= row + 18'd1;
				col <= 18'd0;
			end
		end
		// LEAD IN S'C 0 //
		// in this part of the lead in strictly calculations will be performed to determine and write S'C to DP RAM1 //
		// multiplying by the rows of the transpose as they are equivalent to the columns of the regular matrix //
		// writing in column order not row order to facilitate easier reading for CTS'C calc //
		M2_LI_SC0: begin
			// just making sure these are off
			RAM1_wren_a <= 1'b0;
			RAM0_wren_a <= 1'b0;
			RAM0_wren_b <= 1'b0;
			RAM0_address_a <= C_count; // get C row1 coln
			C_count <= C_count + 7'd1;
			RAM0_address_b <= S_prime_address + S_prime_count + S_offset; // get S
			S_prime_count <= S_prime_count + 7'd1; 

			M2_state <= M2_LI_SC1;
		end
		// LEAD IN S'C 1 //
		M2_LI_SC1: begin
			RAM0_address_a <= C_count; // get C row1 coln
			C_count <= C_count + 7'd1;
			RAM0_address_b <= S_prime_address + S_prime_count + S_offset; // get S
			S_prime_count <= S_prime_count + 7'd1; 


			op1 <= RAM0_read_data_a[31:16];
			op2 <= RAM0_read_data_b[31:16];
			op3 <= RAM0_read_data_a[15:0];
			op4 <= RAM0_read_data_b[15:0];

			M2_state <= M2_LI_SC2;
		end
		// LEAD IN S'C 2 //
		M2_LI_SC2: begin
			RAM0_address_a <= C_count; // get C row1 coln
			C_count <= C_count + 7'd1;
			RAM0_address_b <= S_prime_address + S_prime_count + S_offset; // get S
			S_prime_count <= S_prime_count + 7'd1;

			S_prime_C <= S_prime_C + result1 + result2; 

			op1 <= RAM0_read_data_a[31:16];
			op2 <= RAM0_read_data_b[31:16];
			op3 <= RAM0_read_data_a[15:0];
			op4 <= RAM0_read_data_b[15:0];

			M2_state <= M2_LI_SC3;
		end
		// LEAD IN S'C 3 //
		M2_LI_SC3: begin
			RAM0_address_a <= C_count; // get C row1 coln
			RAM0_address_b <= S_prime_address + S_prime_count + S_offset; // get S

			S_prime_C <= S_prime_C + result1 + result2; 

			op1 <= RAM0_read_data_a[31:16];
			op2 <= RAM0_read_data_b[31:16];
			op3 <= RAM0_read_data_a[15:0];
			op4 <= RAM0_read_data_b[15:0];

			M2_state <= M2_LI_SC4;
		end
		// LEAD IN S'C 4 //
		M2_LI_SC4: begin
			S_prime_C<= S_prime_C + result1 + result2; 

			op1 <= RAM0_read_data_a[31:16];
			op2 <= RAM0_read_data_b[31:16];
			op3 <= RAM0_read_data_a[15:0];
			op4 <= RAM0_read_data_b[15:0];

			M2_state <= M2_LI_SC5;
		end
		// LEAD IN S'C 5 //
		M2_LI_SC5: begin
			RAM1_address_a <= SC_count;
			SC_count <= SC_count + 7'd1;
			// write final result of multiplications
			if(write_ready) begin
				RAM1_wren_a <= 1'b1;
				RAM1_address_a <= S_base_address + S_count;
				S_count <= S_count + 7'd1;
				RAM1_write_data_a[31:16] <= SC_buf >> 8;
				RAM1_write_data_a[15:0] <= (S_prime_C+result1+result2) >> 8;
				write_ready <= 1'b0;
			end else begin
				SC_buf <= S_prime_C+result1+result2;
				write_ready <= 1'b1;
			end
			// if both last column and last row have been reached move to common case and reset counts
			if(S_offset == 7'd28 && row_count == 3'd7 ) begin
				row_count <= 3'd0;
				C_count <= 7'd0;
				S_prime_count <= 7'd0;
				SC_count <= 7'd0;
				S_offset <= 7'd0;
				S_prime_C <= 32'd0;
				col <= col_offset;
				write_ready <= 1'b0;
				M2_state <= M2_CC_FS0;
			end else begin
				// if last column but not last row increment row count and set variables for next multiplication
				if(S_offset == 7'd28) begin
					row_count <= row_count + 3'd1;
					C_count <= (row_count+3'd1) << 2; // C_count
					S_prime_count <= 7'd0; // S'_count
					S_offset <= 7'd0; // S_offset
					M2_state <= M2_LI_SC0;
				end else begin
					// if not last column set row for next multiplication and increment column count
					C_count <= row_count << 2; // C_count
					S_prime_count <= 7'd0; // S_count
					S_offset <= S_offset + 7'd4; // S_offset
					M2_state <= M2_LI_SC0;
				end
			end
		end
		// COMMON CASE FETCH AND MULTIPLY CT(S'C) - FS0 //
		M2_CC_FS0: begin
			RAM0_wren_a <= 1'b0;
			RAM0_wren_b <= 1'b0;
			RAM1_wren_a <= 1'b0;
			RAM1_wren_b <= 1'b0;
			
			first_loop <= 1'b1;
			
			// SRAM address will be equal to the base address + 320(or160)*row# + col#	
			SRAM_address <= base_address + row_offset + col;
			col <= col + 18'd1; // column number increments normally and add 1

			M2_state <= M2_CC_FS1;
		end
		// CC FETCH 1 //
		M2_CC_FS1: begin
			SRAM_address <= base_address + row_offset + col;
			col <= col + 18'd1;

			M2_state <= M2_CC_FS2;
		end
		// CC FETCH 2 //
		M2_CC_FS2: begin
			SRAM_address <= base_address + row_offset + col;
			col <= col + 18'd1;

			RAM0_address_b <= C_count;
			C_count <= C_count + 7'd1;
			RAM1_address_a <= SC_count + S_offset; // this will pull first Y(0,0) and Y(1,0)
			SC_count <= SC_count + 7'd1;

			// These first 3 states are delays to get past the SRAM latency

			M2_state <= M2_CC_FS3;
		end
		// CC FETCH 3 (LOOPING STARTS HERE) //
		M2_CC_FS3: begin
			if(read_flag) done_read <= 1'b1; // need to read one more value so set a flag to set a flag

			if(~done_read) begin
				SRAM_address <= base_address + row_offset + col;
				col <= col + 18'd1;
			end
			if(~done_write) begin
				S_prime_buf <= SRAM_read_data;
			end

			first_loop <= 1'b0;
			if(~first_loop) begin
				if(write_ready) begin
					RAM1_wren_a <= 1'b1;
					RAM1_address_a <= S_base_address + S_count;
					S_count <= S_count + 7'd1;
					RAM1_write_data_a[31:16] <= S_buf >> 16;
					RAM1_write_data_a[15:0] <= (S_result+result1+result2) >> 16;
					write_ready <= 1'b0;
				end else begin
					S_buf <= S_result + result1 + result2;
					write_ready <= 1'b1;
				end
			end
			// 

			RAM0_address_b <= C_count;
			C_count <= C_count + 7'd1;
			RAM1_address_a <= SC_count + S_offset;
			SC_count <= SC_count + 7'd1;

			op1 <= RAM0_read_data_b[31:16];
			op2 <= RAM1_read_data_a[31:16];
			op3 <= RAM0_read_data_b[15:0];
			op4 <= RAM1_read_data_a[15:0];

			if(~done_curr_state)M2_state <= M2_CC_FS4;
			else begin // reset everything when leaving state so its ready for next block
				block_count <= block_count + 12'd1;
				done_curr_state <= 1'b0;
				row_count <= 3'd0;
				C_count <= 7'd0;
				SC_count <= 7'd0;
				S_offset <= 7'd0;
				S_count <= 7'd0;
				first_loop <= 1'b1;
				even_loop <= 1'b1;
				write_ready <= 1'b0;
				done_write <= 1'b0;
				done_read <= 1'b0;
				M2_state <= M2_CC_SC0; // need to leave here to ensure last values get written to the DPRAM
			end
		end
		// CC FETCH 4 //
		M2_CC_FS4: begin
			RAM1_wren_a <= 1'b0;
			if(~done_read) begin
				SRAM_address <= base_address + row_offset + col;
				col <= col + 18'd1;
			end
			if(~done_write) begin
				RAM0_wren_a <= 1'b1;
				RAM0_address_a <= S_prime_address + S_prime_count;
				S_prime_count <= S_prime_count + 7'd1;
				RAM0_write_data_a[31:16] <= S_prime_buf;
				RAM0_write_data_a[15:0] <= SRAM_read_data;
			end

			RAM0_address_b <= C_count;
			C_count <= C_count + 7'd1;
			RAM1_address_a <= SC_count + S_offset;
			SC_count <= SC_count + 7'd1;

			S_result <= S_result + result1 + result2;

			op1 <= RAM0_read_data_b[31:16];
			op2 <= RAM1_read_data_a[31:16];
			op3 <= RAM0_read_data_b[15:0];
			op4 <= RAM1_read_data_a[15:0];

			M2_state <= M2_CC_FS5;
		end
		// CC FETCH 5 //
		M2_CC_FS5: begin
			RAM0_wren_a <= 1'b0;
			if(~done_read) begin
				SRAM_address <= base_address + row_offset + col;
				col <= col + 18'd1;
			end
			if(~done_write) begin
				SRAM_address <= base_address + row_offset + col;
				col <= col + 18'd1;
			end
			
			RAM0_address_b <= C_count;
			C_count <= C_count + 7'd1;
			RAM1_address_a <= SC_count + S_offset;
			SC_count <= SC_count + 7'd1;

			S_result <= S_result + result1 + result2;

			op1 <= RAM0_read_data_b[31:16];
			op2 <= RAM1_read_data_a[31:16];
			op3 <= RAM0_read_data_b[15:0];
			op4 <= RAM1_read_data_a[15:0];

			M2_state <= M2_CC_FS6;
		end
		// CC FETCH 6 //
		M2_CC_FS6: begin
			if(~done_read) begin
				SRAM_address <= base_address + row_offset + col;
				col <= col + 18'd1;
			end else done_write <= 1'b1; // we know if reading is done that writing will be done here
			if(~done_write) begin
				RAM0_wren_a <= 1'b1;
				RAM0_address_a <= S_prime_address + S_prime_count;
				S_prime_count <= S_prime_count + 7'd1;
				RAM0_write_data_a[31:16] <= S_prime_buf;
				RAM0_write_data_a[15:0] <= SRAM_read_data;
			end

			RAM0_address_b <= C_count;
			C_count <= C_count + 7'd1;
			RAM1_address_a <= SC_count + S_offset;
			SC_count <= SC_count + 7'd1;

			S_result <= S_result + result1 + result2;

			op1 <= RAM0_read_data_b[31:16];
			op2 <= RAM1_read_data_a[31:16];
			op3 <= RAM0_read_data_b[15:0];
			op4 <= RAM1_read_data_a[15:0];
			
			even_loop <= ~even_loop;
			if(~even_loop) begin
				if(row==curr_max_row) begin  // check if row has reached end of current block				
					if((fetch_Y)?col_offset == 18'd312:col_offset == 18'd152) begin // if at the end of row of blocks (312 for Y, 152 for UV)
						col_offset <= 18'd0;
						curr_max_row <= curr_max_row + 18'd8;
						row <= curr_max_row + 18'd1;
						S_prime_count <= 7'd0;
						read_flag <= 1'b1;			
					end else begin
						S_prime_count <= 7'd0;
						row <= curr_max_row - 18'd7; // reset row to 8n
						col_offset <= col_offset + 18'd8;
						read_flag <= 1'b1;
					end
				end else begin
					S_prime_count <= S_prime_count + 7'd1;
					row <= row + 18'd1;
					col <= col_offset;
				end 
			end
			// if both last column and last row have been reached move to write and S'C calc and reset counts
			if(S_offset == 7'd28 && row_count == 3'd7 ) begin
				done_curr_state <= 1'b1;
				M2_state <= M2_CC_FS3;
			end else begin
				// if last column but not last row increment row count and set variables for next multiplication
				if(S_offset == 7'd28) begin
					row_count <= row_count + 3'd1;
					C_count <= (row_count+3'd1) << 2; // C_count
					SC_count <= 7'd0; // S'_count
					S_offset <= 7'd0; // S_offset
					M2_state <= M2_CC_FS3;
				end else begin
					// if not last column set row for next multiplication and increment column count
					C_count <= row_count << 2; // C_count
					SC_count <= 7'd0;
					S_offset <= S_offset + 7'd4; // S_offset
					M2_state <= M2_CC_FS3;
				end
			end
		end
		// CC SC 0 (FOR CALCULATING S'C AND WRITING S TO SRAM) //
		M2_CC_SC0: begin
			RAM1_wren_a <= 1'b0;
			RAM1_wren_b <= 1'b0;
			RAM0_wren_a <= 1'b0;
			RAM0_wren_b <= 1'b0;

			// state for bypassing read latency

			// for calculations
			RAM0_address_a <= C_count;
			C_count <= C_count + 7'd1;
			RAM0_address_b <= S_prime_address + S_prime_count + S_offset;
			S_prime_count <= S_prime_count + 7'd1;

			// for writing to SRAM
			RAM1_address_b <= S_base_address + S_count;
			S_count <= S_count + 7'd1;

			M2_state <=	M2_CC_SC1;
		end
		// CC SC1 (LOOPING STARTS HERE) //
		M2_CC_SC1: begin
			if(~done_write) begin
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_count;
				write_count <= write_count + 18'd1;
				SRAM_write_data[15:8] <= RAM1_read_data_b[23:16]; // clipping to 8 bits
				SRAM_write_data[7:0] <= RAM1_read_data_b[7:0];
			end
			if(~done_read) begin
				RAM1_address_b <= S_base_address + S_count;
				S_count <= S_count + 7'd1;
			end

			first_loop <= 1'b0;
			if(~first_loop) begin
				if(write_ready) begin
					RAM1_wren_a <= 1'b1;
					RAM1_address_a <= SC_count;
					SC_count <= SC_count + 7'd1;
					RAM1_write_data_a[31:16] <= S_buf >> 8;
					RAM1_write_data_a[15:0] <= (S_result+result1+result2) >> 8;
				end else begin
					S_buf <= S_result + result1 + result2;
					write_ready <= 1'b1;
				end
			end
			
			RAM0_address_a <= C_count;
			C_count <= C_count + 7'd1;
			RAM0_address_b <= S_prime_address + S_prime_count + S_offset;
			S_prime_count <= S_prime_count + 7'd1;

			op1 <= RAM0_read_data_a[31:16];
			op2 <= RAM0_read_data_b[31:16];
			op3 <= RAM0_read_data_a[15:0];
			op4 <= RAM0_read_data_b[15:0];

			if(~done_curr_state)M2_state <= M2_CC_FS2;
			else begin // reset everything when leaving state so its ready for next block
				block_count <= block_count + 12'd1;
				done_curr_state <= 1'b0;
				row_count <= 3'd0;
				C_count <= 7'd0;
				SC_count <= 7'd0;
				S_offset <= 7'd0;
				S_count <= 7'd0;
				first_loop <= 1'b1;
				even_loop <= 1'b1;
				write_ready <= 1'b0;
				done_write <= 1'b0;
				done_read <= 1'b0;
				if((fetch_Y) ? block_count==18'd1199 : block_count==18'd2399) M2_state <= M2_LO_S0; // move to lead out if done Y blocks or UV blocks
				else M2_state <= M2_CC_FS0; // need to leave here to ensure last values get written to the DPRAM
			end
		end		
		// CC SC2 //
		M2_CC_SC2: begin
			if(~done_write) begin
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_count;
				write_count <= write_count + 18'd1;
				SRAM_write_data[15:8] <= RAM1_read_data_b[23:16]; // clipping to 8 bits
				SRAM_write_data[7:0] <= RAM1_read_data_b[7:0];
			end
			if(~done_read) begin
				RAM1_address_b <= S_base_address + S_count;
				S_count <= S_count + 7'd1;
			end

			RAM0_address_a <= C_count;
			C_count <= C_count + 7'd1;
			RAM0_address_b <= S_prime_address + S_prime_count + S_offset;
			S_prime_count <= S_prime_count + 7'd1;

			S_prime_C <= S_prime_C + result1 + result2;

			op1 <= RAM0_read_data_a[31:16];
			op2 <= RAM0_read_data_b[31:16];
			op3 <= RAM0_read_data_a[15:0];
			op4 <= RAM0_read_data_b[15:0];

			M2_state <= M2_CC_SC3;
		end
		// CC SC3 //
		M2_CC_SC3: begin

			if(~done_write) begin
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_count;
				write_count <= write_count + 18'd1;
				SRAM_write_data[15:8] <= RAM1_read_data_b[23:16]; // clipping to 8 bits
				SRAM_write_data[7:0] <= RAM1_read_data_b[7:0];
			end
			if(~done_read) begin
				RAM1_address_b <= S_base_address + S_count;
				S_count <= S_count + 7'd1;
			end
			if(S_count == 7'd31) done_read <= 1'b1; // once 31 values have been read assert done reade
			
			RAM0_address_a <= C_count;
			C_count <= C_count + 7'd1;
			RAM0_address_b <= S_prime_address + S_prime_count + S_offset;
			S_prime_count <= S_prime_count + 7'd1;

			S_prime_C <= S_prime_C + result1 + result2;

			op1 <= RAM0_read_data_a[31:16];
			op2 <= RAM0_read_data_b[31:16];
			op3 <= RAM0_read_data_a[15:0];
			op4 <= RAM0_read_data_b[15:0];

			M2_state <= M2_CC_SC4;
		end
		// CC SC4 //
		M2_CC_SC4: begin
			if(~done_write) begin
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_count;
				write_count <= write_count + 18'd1;
				SRAM_write_data[15:8] <= RAM1_read_data_b[23:16]; // clipping to 8 bits
				SRAM_write_data[7:0] <= RAM1_read_data_b[7:0];
			end
			if(~done_read) begin
				RAM1_address_b <= S_base_address + S_count;
				S_count <= S_count + 7'd1;
			end else begin
				done_write <= 1'b1; // if done reading will be done writing on this cycle
				SRAM_we_n <= 1'b1; // disable write enable
			end

			RAM0_address_a <= C_count;
			C_count <= C_count + 7'd1;
			RAM0_address_b <= S_prime_address + S_prime_count + S_offset;
			S_prime_count <= S_prime_count + 7'd1;

			S_prime_C <= S_prime_C + result1 + result2;

			op1 <= RAM0_read_data_a[31:16];
			op2 <= RAM0_read_data_b[31:16];
			op3 <= RAM0_read_data_a[15:0];
			op4 <= RAM0_read_data_b[15:0];

			M2_state <= M2_CC_SC3;

			// if both last column and last row have been reached move to common case and reset counts
			if(S_offset == 7'd28 && row_count == 3'd7 ) begin
				done_curr_state <= 1'b1;
				M2_state <= M2_CC_SC1;
			end else begin
				// if last column but not last row increment row count and set variables for next multiplication
				if(S_offset == 7'd28) begin
					row_count <= row_count + 3'd1;
					C_count <= (row_count+3'd1) << 2; // C_count
					S_prime_count <= 7'd0; // S'_count
					S_offset <= 7'd0; // S_offset
					M2_state <= M2_CC_SC1;
				end else begin
					// if not last column set row for next multiplication and increment column count
					C_count <= row_count << 2; // C_count
					S_prime_count <= 7'd0; // S_count
					S_offset <= S_offset + 7'd4; // S_offset
					M2_state <= M2_CC_SC1;
				end
			end

		end
		// LEAD OUT CALCULATE S //
		M2_LO_S0: begin	
			RAM0_wren_a <= 1'b0;
			RAM0_wren_a <= 1'b0;
			RAM1_wren_a <= 1'b0;
			RAM1_wren_a <= 1'b0;

			RAM0_address_b <= C_count;
			C_count <= C_count + 7'd1;
			RAM1_address_a <= SC_count + S_offset;
			SC_count <= SC_count + 7'd1;

			// bypass latency in loop

			M2_state <= M2_LO_S1;
		end
		// LEAD OUT S1 (LOOPING STARTS HERE) //
		M2_LO_S1: begin
			first_loop <= 1'b0;
			if(~first_loop) begin
				if(write_ready) begin
					RAM1_wren_a <= 1'b1;
					RAM1_address_a <= S_base_address + S_count;
					S_count <= S_count + 7'd1;
					RAM1_write_data_a[31:16] <= S_buf >> 16;
					RAM1_write_data_a[15:0] <= (S_result+result1+result2) >> 16;
					write_ready <= 1'b0;
				end else begin
					S_buf <= S_result + result1 + result2;
					write_ready <= 1'b1;
				end
			end

			RAM0_address_b <= C_count;
			C_count <= C_count + 7'd1;
			RAM1_address_a <= SC_count + S_offset;
			SC_count <= SC_count + 7'd1;

			op1 <= RAM0_read_data_b[31:16];
			op2 <= RAM1_read_data_a[31:16];
			op3 <= RAM0_read_data_b[15:0];
			op4 <= RAM1_read_data_a[15:0];

			if(~done_curr_state)M2_state <= M2_LO_S2;
			else begin // reset everything when leaving state so its ready for next cycle
				done_curr_state <= 1'b0;
				row_count <= 3'd0;
				C_count <= 7'd0;
				SC_count <= 7'd0;
				S_offset <= 7'd0;
				S_count <= 7'd0;
				first_loop <= 1'b1;
				even_loop <= 1'b1;
				write_ready <= 1'b0;
				done_write <= 1'b0;
				done_read <= 1'b0;
				M2_state <= M2_LO_WS0; // need to leave here to ensure last values get written to the DPRAM
			end
		end
		// LEAD OUT S2 //
		M2_LO_S2: begin
			RAM1_wren_a <= 1'b0;
			RAM0_address_b <= C_count;
			C_count <= C_count + 7'd1;
			RAM1_address_a <= SC_count + S_offset;
			SC_count <= SC_count + 7'd1;

			S_result <= S_result + result1 + result2;

			op1 <= RAM0_read_data_b[31:16];
			op2 <= RAM1_read_data_a[31:16];
			op3 <= RAM0_read_data_b[15:0];
			op4 <= RAM1_read_data_a[15:0];

			M2_state <= M2_LO_S3;			
		end
		// LEAD OUT S3 //
		M2_LO_S3: begin
			RAM0_address_b <= C_count;
			C_count <= C_count + 7'd1;
			RAM1_address_a <= SC_count + S_offset;
			SC_count <= SC_count + 7'd1;

			S_result <= S_result + result1 + result2;

			op1 <= RAM0_read_data_b[31:16];
			op2 <= RAM1_read_data_a[31:16];
			op3 <= RAM0_read_data_b[15:0];
			op4 <= RAM1_read_data_a[15:0];

			M2_state <= M2_LO_S4;
		end
		// LEAD OUT S4 //
		M2_LO_S4: begin
			RAM0_address_b <= C_count;
			C_count <= C_count + 7'd1;
			RAM1_address_a <= SC_count + S_offset;
			SC_count <= SC_count + 7'd1;

			S_result <= S_result + result1 + result2;

			op1 <= RAM0_read_data_b[31:16];
			op2 <= RAM1_read_data_a[31:16];
			op3 <= RAM0_read_data_b[15:0];
			op4 <= RAM1_read_data_a[15:0];

			// if both last column and last row have been reached move to write and S'C calc and reset counts
			if(S_offset == 7'd28 && row_count == 3'd7 ) begin
				done_curr_state <= 1'b1;
				M2_state <= M2_LO_S1;
			end else begin
				// if last column but not last row increment row count and set variables for next multiplication
				if(S_offset == 7'd28) begin
					row_count <= row_count + 3'd1;
					C_count <= (row_count+3'd1) << 2; // C_count
					SC_count <= 7'd0; // S'_count
					S_offset <= 7'd0; // S_offset
					M2_state <= M2_LO_S1;
				end else begin
					// if not last column set row for next multiplication and increment column count
					C_count <= row_count << 2; // C_count
					SC_count <= 7'd0;
					S_offset <= S_offset + 7'd4; // S_offset
					M2_state <= M2_LO_S1;
				end
			end
		end
		M2_LO_WS0: begin
			RAM1_wren_a <= 1'b0;
			RAM1_wren_b <= 1'b0;
			RAM0_wren_a <= 1'b0;
			RAM0_wren_b <= 1'b0;

			RAM1_address_b <= S_base_address + S_count;
			S_count <= S_count + 7'd1;			

			M2_state <= M2_LO_WS1;
		end
		M2_LO_WS1: begin
			if(~done_write) begin
				SRAM_we_n <= 1'b0;
				SRAM_address <= write_count;
				write_count <= write_count + 18'd1;
				SRAM_write_data[15:8] <= RAM1_read_data_b[23:16]; // clipping to 8 bits
				SRAM_write_data[7:0] <= RAM1_read_data_b[7:0];
			end
			if(~done_read) begin
				RAM1_address_b <= S_base_address + S_count;
				S_count <= S_count + 7'd1;
			end
			if(S_count == 7'd31) done_curr_state <= 1'b1; // after writing all 31 values asset

			M2_state <= M2_LO_WS2; 
		end
		M2_LO_WS2: begin
			if(done_curr_state) begin
				if(block_count == 18'd1199) begin // re-loop for U and V blocks
					done_curr_state <= 1'b0;
					row_count <= 3'd0;
					C_count <= 7'd0;
					SC_count <= 7'd0;
					S_offset <= 7'd0;
					S_count <= 7'd0;
					first_loop <= 1'b1;
					even_loop <= 1'b1;
					write_ready <= 1'b0;
					done_write <= 1'b0;
					done_read <= 1'b0;
					fetch_Y <= 1'b0; // deassert Y fetching
					M2_state <= M2_LI_FS0;
				end else begin
					M2_finish <= 1'b1;
				end
			end else M2_state <= M2_LO_WS1;
		end

		default: M2_state <= M2_LI_FS0;
		endcase

	end
end

endmodule