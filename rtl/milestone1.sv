/* M1LESTONE 1
Copyright by Group 34
McMaster University
Ontario, Canada
*/


`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

module milestone1(
		input logic CLOCK_50_I,							//50 MHz Clock
		input logic resetn,								// reset
		input logic M1_start,
		// SRAM //
		input logic [15:0] SRAM_read_data,
		output logic [15:0] SRAM_write_data,
		output logic [17:0] SRAM_address,
		output logic SRAM_we_n,
		output logic M1_finish
		
);

M1_state_type M1_state;

// CONSTANTS
parameter Y_address = 18'd0,
			 U_address = 18'd38400,
			 V_address = 18'd57600,
			 RGB_address = 18'd146944,
			 coeff_UV5 = 18'd21,
			 coeff_UV3 = 18'd52,
			 coeff_UV1 = 18'd159,
			 Y_RGB = 18'd76284,
			 V_R = 18'd104595,
			 U_R = 18'd0,
			 U_G = 18'd25624,
			 V_G = 18'd53281,
			 V_B = 18'd0,
			 U_B = 18'd132251,
			 Y_sub = 18'd16,
			 UV_sub = 18'd128;
			 
			 
			 
// REGISTERS
logic [31:0] Y_val;
logic [31:0] U_val;
logic [31:0] V_val;
logic [7:0] U_buf;
logic [7:0] V_buf;
logic [7:0] U_p5;
logic [7:0] U_p3;
logic [7:0] U_p1;
logic [7:0] U_m1;
logic [7:0] U_m3;
logic [7:0] U_m5;
logic [7:0] V_p5;
logic [7:0] V_p3;
logic [7:0] V_p1;
logic [7:0] V_m1;
logic [7:0] V_m3;
logic [7:0] V_m5;
logic signed [31:0] R_val;
logic signed [31:0] G_val;
logic signed [31:0] B_val;

// COUNTERS
logic [17:0] RGB_count;
logic [17:0] UV_count;
logic [17:0] Y_count;

// MULTIPLICATION STUFF
logic [31:0] op1;
logic [31:0] op2;
logic [31:0] op3;
logic [31:0] op4;
logic [31:0] op5;
logic [31:0] op6;

logic [31:0] result1;
logic [31:0] result2;
logic [31:0] result3;
logic [63:0] result3_long;
logic [63:0] result2_long;
logic [63:0] result1_long;

logic [8:0] line_count;


assign result1_long = op1*op2;
assign result2_long = op3*op4;
assign result3_long = op5*op6;

assign result1 = result1_long[31:0];
assign result2 = result2_long[31:0];
assign result3 = result3_long[31:0];

//flag
logic CC_done;

always @(posedge CLOCK_50_I or negedge resetn) begin
	if(~resetn) begin
		M1_state <= M1_IDLE;
		Y_val <= 16'd0;
		U_val <= 8'd0;
		V_val <= 8'd0;
		U_buf <= 8'd0;
		V_buf <= 8'd0;
		U_p5 <= 8'd0;
		U_p3 <= 8'd0;
		U_p1 <= 8'd0;
		U_m1 <= 8'd0;
		U_m3 <= 8'd0;
		U_m5 <= 8'd0;
		V_p5 <= 8'd0;
		V_p3 <= 8'd0;
		V_p1 <= 8'd0;
		V_m1 <= 8'd0;
		V_m3 <= 8'd0;
		V_m5 <= 8'd0;
		R_val <= 32'd0;
		G_val <= 32'd0;
		B_val <= 32'd0;
		op1 <= 32'd0;
		op2 <= 32'd0;
		op3 <= 32'd0;
		op4 <= 32'd0;
		op5 <= 32'd0;
		op6 <= 32'd0;
		RGB_count <= 18'd0;
		UV_count <= 18'd0;
		Y_count <= 18'd0;
		SRAM_address <= 18'd0;
		SRAM_write_data <= 16'd0;
		SRAM_we_n <= 1'b1;
		line_count <= 9'd1;
		M1_finish <= 1'b0;
		CC_done <= 1'b0;
	end else begin
		case(M1_state)
		// Lead In 0 in state table, all state names counting, comments for state table
		M1_IDLE: begin		
			if(M1_start) begin
				SRAM_we_n <= 1'b1;
				SRAM_address <= Y_address + Y_count; // Y0Y1
				Y_count <= Y_count + 18'd1;
				
				M1_state <= M1_LI0;
			end
		end
		
		// LEAD IN 1 //
		M1_LI0: begin
			SRAM_address <= U_address + UV_count; // U0U1
			
			M1_state <= M1_LI1;		
		end
		// LEAD IN 2 //
		M1_LI1: begin
			SRAM_address <= V_address + UV_count; // V0V1
			UV_count <= UV_count + 18'd1;
			
			M1_state <= M1_LI2;
		end
		// LEAD IN 3 //
		M1_LI2: begin
			SRAM_address <= U_address + UV_count; //U2U3
			
			Y_val <= SRAM_read_data; // Y0Y1
			
			M1_state <= M1_LI3;
		end
		// LEAD IN 4 //
		M1_LI3: begin
			SRAM_address <= V_address + UV_count; // V2V3
			UV_count <= UV_count + 18'd1;
			U_val <= SRAM_read_data[15:8];	// U0
			
			U_p1 <= SRAM_read_data[7:0]; //U1
			U_m1 <= SRAM_read_data[15:8];
			U_m3 <= SRAM_read_data[15:8];
			U_m5 <= SRAM_read_data[15:8];
			
			M1_state <= M1_LI4;
		end
		// LEAD IN 5 //
		M1_LI4: begin
			V_val <= SRAM_read_data[15:8];	// V0
			
			V_p1 <= SRAM_read_data[7:0]; //V1
			V_m1 <= SRAM_read_data[15:8];
			V_m3 <= SRAM_read_data[15:8];
			V_m5 <= SRAM_read_data[15:8];
			
			// Operands for R0 calculation
			op1 <= Y_val[15:8]-Y_sub;
			op2 <= Y_RGB;
			op3 <= U_val-UV_sub;
			op4 <= U_R;
			op5 <= SRAM_read_data[15:8] - UV_sub;
			op6 <= V_R;
			
			M1_state <= M1_LI5;
		
		end
		// LEAD IN 6 //
		M1_LI5: begin
			R_val <= (result1 + result2 + result3) >> 16; // R0
			
			U_p5 <= SRAM_read_data[7:0]; // U3
			U_p3 <= SRAM_read_data[15:8]; // U2
			
			// Operands for G0 calculation
			op3 <= U_val - UV_sub;
			op4 <= U_G;
			op6 <= V_G;
		
			M1_state <= M1_LI6;
		end
		// LEAD IN 7 //
		M1_LI6: begin
			G_val <= (result1 - result2 - result3) >> 16; // G0
			
			V_p5 <= SRAM_read_data[7:0]; // V3
			V_p3 <= SRAM_read_data[15:8]; // V2
			
			// Operands for B0 calculation
			op4 <= U_B;
			op6 <= V_B;
			
			M1_state <= M1_LI7;			
		end
		// LEAD IN 8 //
		M1_LI7: begin
			SRAM_we_n <= 1'b0; // enable writing
			SRAM_address <= RGB_address + RGB_count;
			RGB_count <= RGB_count + 18'd1;
			
			B_val <= (result1 + result2 + result3) >> 16; // B0
			
			// Writing R0G0
			SRAM_write_data[15:8] <= (R_val[15] == 1'b1) ? 8'b0 : ((|R_val[15:8]) ? 8'd255 : R_val[7:0]); // If negative, use 0, if >255 use 255
			SRAM_write_data[7:0] <= (G_val[15] == 1'b1) ? 8'b0 : ((|G_val[15:8]) ? 8'd255 : G_val[7:0]);
			
			//Operands to calculate U1'
			op1 <= U_p5 + U_m5;
			op2 <= coeff_UV5;
			op3 <= U_p3 + U_m3;
			op4 <= coeff_UV3;
			op5 <= U_p1 + U_m1;
			op6 <= coeff_UV1;
			
			M1_state <= M1_LI8;
		end
		// LEAD IN 9 //
		M1_LI8: begin
			SRAM_we_n <= 1'b1; // enable read
			
			SRAM_address <= Y_address + Y_count; // Y2Y3
			Y_count <= Y_count + 18'd1;
			
			U_val <= (result1-result2+result3+UV_sub) >> 8; //U1'
			
			//Operands to calculate V1'
			op1 <= V_p5 + V_m5;
			op2 <= coeff_UV5;
			op3 <= V_p3 + V_m3;
			op4 <= coeff_UV3;
			op5 <= V_p1 + V_m1;
			op6 <= coeff_UV1;
			
			M1_state <= M1_LI9;
		end
		// LEAD IN 10 //
		M1_LI9: begin
			SRAM_address <= U_address + UV_count;
			
			V_val <= (result1-result2+result3+UV_sub) >> 8; //V1'
			
			// Operands for calculation R1
			op1 <= Y_val[7:0]-Y_sub;
			op2 <= Y_RGB;
			op3 <= U_val;
			op4 <= U_R;
			op5 <= ((result1-result2+result3+UV_sub) >> 8) - UV_sub;
			op6 <= V_R;
			
			M1_state <= M1_LI10;
		end
		// LEAD IN 11 //
		M1_LI10: begin
			SRAM_address <= V_address + UV_count;
			UV_count <= UV_count + 18'd1;
			
			R_val <= (result1+result2+result3) >> 16;
			
			//G1 Calculation
			op3 <= U_val - UV_sub;
			op4 <= U_G;
			op6 <= V_G;
			
			M1_state <= M1_LI11;			
		end
		// LEAD IN 12 (LAST LI STATE) //
		M1_LI11: begin
			SRAM_we_n <= 1'b0; // enable write
			SRAM_address <= RGB_address + RGB_count; // B0R1
			RGB_count <= RGB_count + 18'd1;
			
			// writing B0R1
			SRAM_write_data[15:8] <= (B_val[15] == 1'b1) ? 8'b0 : ((|B_val[15:8]) ? 8'd255 : B_val[7:0]); // If negative, use 0, if >255 use 255
			SRAM_write_data[7:0] <= (R_val[15] == 1'b1) ? 8'b0 : ((|R_val[15:8]) ? 8'd255 : R_val[7:0]);
			
			Y_val <= SRAM_read_data;
			G_val <= (result1-result2-result3) >> 16;
			
			U_val <= U_p1; //U2 = U1 = U_p1
			
			// calc b1
			op4 <= U_B;
			op6 <= V_B;
			
			M1_state <= M1_CC0;			
		end
		// COMMONC CASE 0 //
		M1_CC0: begin
			SRAM_we_n <= 1'b1;
			B_val <= (result1+result2+result3) >> 16;
			
			V_val <= V_p1; // even V value
			
			U_buf <= SRAM_read_data[7:0]; // save for later use
			U_p5 <= SRAM_read_data[15:8]; // add U value to shift register
			U_p3 <= U_p5;
			U_p1 <= U_p3;
			U_m1 <= U_p1;
			U_m3 <= U_m1;
			U_m5 <= U_m3;
			
			// calculate red
			op1 <= Y_val[15:8] - Y_sub;
			op2 <= Y_RGB;
			op3 <= U_val;
			op4 <= U_R;
			op5 <= V_p1 - UV_sub;
			op6 <= V_R;
			
			M1_state <= M1_CC1;			
		end
		// COMMON CASE 1 //
		M1_CC1: begin
			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_address + RGB_count; // this will be GB
			RGB_count <= RGB_count + 18'd1;
			
			// writing GB
			SRAM_write_data[15:8] <= (G_val[15] == 1'b1) ? 8'b0 : ((|G_val[15:8]) ? 8'd255 : G_val[7:0]); // If negative, use 0, if >255 use 255
			SRAM_write_data[7:0] <= (B_val[15] == 1'b1) ? 8'b0 : ((|B_val[15:8]) ? 8'd255 : B_val[7:0]);
			
			R_val <= (result1+result2+result3) >> 16;
			
			V_buf <= SRAM_read_data[7:0]; // save V value for later
			V_p5 <= SRAM_read_data[15:8]; // add V value to shift reg
			V_p3 <= V_p5;
			V_p1 <= V_p3;
			V_m1 <= V_p1;
			V_m3 <= V_m1;
			V_m5 <= V_m3;
			
			// calculate green
			op3 <= U_val - UV_sub;
			op4 <= U_G;
			op6 <= V_G;
			
			M1_state <= M1_CC2;
		end
		// COMMON CASE 2 //
		M1_CC2: begin
			SRAM_we_n <= 1'b1;
			G_val <= (result1-result2-result3) >> 16;
			
			// calculate blue
			op4 <= U_B;
			op6 <= V_B;
			
			M1_state <= M1_CC3;
		end
		// COMMON CASE 3 //
		M1_CC3: begin
			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_address + RGB_count;
			RGB_count <= RGB_count + 18'd1;
			
			B_val <= (result1+result2+result3) >> 16;
			
			// writing RG
			SRAM_write_data[15:8] <= (R_val[15] == 1'b1) ? 8'b0 : ((|R_val[15:8]) ? 8'd255 : R_val[7:0]); // If negative, use 0, if >255 use 255
			SRAM_write_data[7:0] <= (G_val[15] == 1'b1) ? 8'b0 : ((|G_val[15:8]) ? 8'd255 : G_val[7:0]);
			
			// calculating U'
			op1 <= U_p5 + U_m5;
			op2 <= coeff_UV5;
			op3 <= U_p3 + U_m3;
			op4 <= coeff_UV3;
			op5 <= U_p1 + U_m1;
			op6 <= coeff_UV1;			
			
			M1_state <= M1_CC4;
		end
		// COMMON CASE 4 //
		M1_CC4: begin
			SRAM_we_n <= 1'b1;
			SRAM_address <= Y_address + Y_count;
			Y_count <= Y_count + 18'd1;
			
			U_val <= (result1-result2+result3+UV_sub) >> 8;
			
			// calculating V'
			op1 <= V_p5 + V_m5;
			op2 <= coeff_UV5;
			op3 <= V_p3 + V_m3;
			op4 <= coeff_UV3;
			op5 <= V_p1 + V_m1;
			op6 <= coeff_UV1;
			
			M1_state <= M1_CC5;			
		end
		// COMMON CASE 5 //
		M1_CC5: begin
			V_val <= (result1-result2+result3+UV_sub) >> 8;
			
			// calculating red
			op1 <= Y_val[7:0] - Y_sub;
			op2 <= Y_RGB;
			op3 <= U_val;
			op4 <= U_R;
			op5 <= ((result1-result2+result3+UV_sub) >> 8)-UV_sub;
			op6 <= V_R;

			M1_state <= M1_CC6;
		end
		// COMMON CASE 6 //
		M1_CC6: begin
			R_val <= (result1+result2+result3) >> 16;
			
			// calculate green
			op3 <= U_val-UV_sub;
			op4 <= U_G;
			op6 <= V_G;
			
			M1_state <= M1_CC7;
		end
		// COMMON CASE 7 //
		M1_CC7: begin
			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_address + RGB_count;
			RGB_count <= RGB_count + 18'd1;
			
			// writing BR
			SRAM_write_data[15:8] <= (B_val[15] == 1'b1) ? 8'b0 : ((|B_val[15:8]) ? 8'd255 : B_val[7:0]); // If negative, use 0, if >255 use 255
			SRAM_write_data[7:0] <= (R_val[15] == 1'b1) ? 8'b0 : ((|R_val[15:8]) ? 8'd255 : R_val[7:0]);
			
			G_val <= (result1-result2-result3) >> 16;
			Y_val <= SRAM_read_data;
			U_val <= U_p1; // even value U next
			
			// calculate blue
			op4 <= U_B;
			op6 <= V_B;
		
			M1_state <= M1_CC8;
		end
		// COMMON CASE 8
		M1_CC8: begin
			SRAM_we_n <= 1'b1;
			B_val <= (result1+result2+result3) >> 16;
			
			U_p5 <= U_buf; // put saved value into shift register now
			U_p3 <= U_p5;
			U_p1 <= U_p3;
			U_m1 <= U_p1;
			U_m3 <= U_m1;
			U_m5 <= U_m3;
			
			V_val <= V_p1;
			
			// calculate red
			op1 <= Y_val[15:8] - Y_sub;
			op2 <= Y_RGB;
			op3 <= U_val;
			op4 <= U_R;
			op5 <= V_p1 - UV_sub;
			op6 <= V_R;
			
			M1_state <= M1_CC9;
		end
		// COMMON CASE 9 //
		M1_CC9: begin
			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_address + RGB_count;
			RGB_count <= RGB_count + 18'd1;
			
			//writing GB
			SRAM_write_data[15:8] <= (G_val[15] == 1'b1) ? 8'b0 : ((|G_val[15:8]) ? 8'd255 : G_val[7:0]); // If negative, use 0, if >255 use 255
			SRAM_write_data[7:0] <= (B_val[15] == 1'b1) ? 8'b0 : ((|B_val[15:8]) ? 8'd255 : B_val[7:0]);
			
			R_val <= (result1+result2+result3) >> 16;	
			
			V_p5 <= V_buf; // put saved V in shift reg
			V_p3 <= V_p5;
			V_p1 <= V_p3;
			V_m1 <= V_p1;
			V_m3 <= V_m1;
			V_m5 <= V_m3;
			
			// calculate green
			op3 <= U_val - UV_sub;
			op4 <= U_G;
			op6 <= V_G;
		
			M1_state <= M1_CC10;
		end
		// COMMON CASE 10 //
		M1_CC10: begin
			SRAM_we_n <= 1'b1;
			G_val <= (result1-result2-result3) >> 16;
			
			//calculate blue
			op4 <= U_B;
			op6 <= V_B;
			
			M1_state <= M1_CC11;
		end
		// COMMON CASE 11 //
		M1_CC11: begin
			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_address + RGB_count;
			RGB_count <= RGB_count + 18'd1;
			
			B_val <= (result1+result2+result3) >> 16;
			
			// writing RG
			SRAM_write_data[15:8] <= (R_val[15] == 1'b1) ? 8'b0 : ((|R_val[15:8]) ? 8'd255 : R_val[7:0]); // If negative, use 0, if >255 use 255
			SRAM_write_data[7:0] <= (G_val[15] == 1'b1) ? 8'b0 : ((|G_val[15:8]) ? 8'd255 : G_val[7:0]);
			
			// calculate U'
			op1 <= U_p5 + U_m5;
			op2 <= coeff_UV5;
			op3 <= U_p3 + U_m3;
			op4 <= coeff_UV3;
			op5 <= U_p1 + U_m1;
			op6 <= coeff_UV1;
			
			M1_state <= M1_CC12;
		end
		// COMMON CASE 12 //
		M1_CC12: begin
			SRAM_we_n <= 1'b1;
			SRAM_address <= Y_address + Y_count;
			Y_count <= Y_count + 18'd1;
			
			U_val <= (result1-result2+result3+UV_sub) >> 8;
			
			// calculating V'
			op1 <= V_p5 + V_m5;
			op2 <= coeff_UV5;
			op3 <= V_p3 + V_m3;
			op4 <= coeff_UV3;
			op5 <= V_p1 + V_m1;
			op6 <= coeff_UV1;
			
			// if CC finished detected on previous loop exit CC before reading invalid memory values in state 13
			if(CC_done) begin
				M1_state <= M1_LO0;
				line_count <= line_count + 9'd1;
				CC_done <= 1'b0;
			end
			else M1_state <= M1_CC13;
		end
		// COMMON CASE 13 //
		M1_CC13: begin
			SRAM_address <= U_address + UV_count;
			
			V_val <= (result1-result2+result3+UV_sub) >> 8;
			
			// calculate red
			op1 <= Y_val[7:0] - Y_sub;
			op2 <= Y_RGB;
			op3 <= U_val;
			op4 <= U_R;
			op5 <= ((result1-result2+result3+UV_sub) >> 8)-UV_sub;
			op6 <= V_R;
		
			M1_state <= M1_CC14;
		end
		// COMMON CASE 14 //
		M1_CC14: begin
			SRAM_address <= V_address + UV_count;
			UV_count <= UV_count + 18'd1;
			
			R_val <= (result1+result2+result3) >> 16;
			
			op3 <= U_val - UV_sub;
			op4 <= U_G;
			op6 <= V_G;
		
			M1_state <= M1_CC15;
		end
		// COMMON CASE 15 (LAST STATE FOR CC) //
		M1_CC15: begin
			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_address + RGB_count;
			RGB_count <= RGB_count + 18'd1;
			
			//writing BR
			SRAM_write_data[15:8] <= (B_val[15] == 1'b1) ? 8'b0 : ((|B_val[15:8]) ? 8'd255 : B_val[7:0]); // If negative, use 0, if >255 use 255
			SRAM_write_data[7:0] <= (R_val[15] == 1'b1) ? 8'b0 : ((|R_val[15:8]) ? 8'd255 : R_val[7:0]);
			
			Y_val <= SRAM_read_data;
			
			G_val <= (result1-result2-result3) >> 16;
			
			U_val <= U_p1;
			
			// calculate B
			op4 <= U_B;
			op6 <= V_B;
			
			if(UV_count >= ((line_count<<6)+(line_count<<4))) CC_done <= 1'b1;
			
			M1_state <= M1_CC0;
		end
		// LEAD OUT 0 //
		M1_LO0: begin
			SRAM_we_n <= 1'b1;
			V_val <= (result1-result2+result3+UV_sub) >> 8;
			
			// calculating R38393
			op1 <= Y_val[7:0] - Y_sub;
			op2 <= Y_RGB;
			op3 <= U_val;
			op4 <= U_R;
			op5 <= ((result1-result2+result3+UV_sub) >> 8)-UV_sub;
			op6 <= V_R;
			
			M1_state <= M1_LO1;
		end
		// LEAD OUT 1 //
		M1_LO1: begin
			R_val <= (result1+result2+result3) >> 16; // R38393
		
			op3 <= U_val - UV_sub;
			op4 <= U_G;
			op6 <= V_G;
			
			M1_state <= M1_LO2;
		end
		// LEAD OUT 2 //
		M1_LO2: begin
			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_address + RGB_count;
			RGB_count <= RGB_count + 18'd1;
			
			// write B38392 and R38393
			SRAM_write_data[15:8] <= (B_val[15] == 1'b1) ? 8'b0 : ((|B_val[15:8]) ? 8'd255 : B_val[7:0]); // If negative, use 0, if >255 use 255
			SRAM_write_data[7:0] <= (R_val[15] == 1'b1) ? 8'b0 : ((|R_val[15:8]) ? 8'd255 : R_val[7:0]);
			
			// G38393
			G_val <= (result1-result2-result3) >> 16;
			Y_val <= SRAM_read_data;
			U_val <= U_p1; // U39394
			
			op4 <= U_B;
			op6 <= V_B;
		
			M1_state <= M1_LO3;
		end
		// LEAD OUT 3 //
		M1_LO3: begin
			SRAM_we_n <= 1'b1;
			B_val <= (result1+result2+result3) >> 16;
			
			U_p3 <= U_p5;
			U_p1 <= U_p3;
			U_m1 <= U_p1;
			U_m3 <= U_m1;
			U_m5 <= U_m3;
			
			V_val <= V_p1;
			
			// R38394 calculation
			op1 <= Y_val[15:8]-Y_sub;
			op2 <= Y_RGB;
			op3 <= U_val;
			op4 <= U_R;
			op5 <= V_p1 - UV_sub;
			op6 <= V_R;
		
			M1_state <= M1_LO4;
		end
		// LEAD OUT 4 //
		M1_LO4: begin
			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_address + RGB_count;
			RGB_count <= RGB_count + 18'd1;
			
			// Writing G38393 and B38393
			//writing GB
			SRAM_write_data[15:8] <= (G_val[15] == 1'b1) ? 8'b0 : ((|G_val[15:8]) ? 8'd255 : G_val[7:0]); // If negative, use 0, if >255 use 255
			SRAM_write_data[7:0] <= (B_val[15] == 1'b1) ? 8'b0 : ((|B_val[15:8]) ? 8'd255 : B_val[7:0]);
		
			R_val <= (result1+result2+result3) >> 16;
			
			V_p3 <= V_p5;
			V_p1 <= V_p3;
			V_m1 <= V_p1;
			V_m3 <= V_m1;
			V_m5 <= V_m3;
			
			op3 <= U_val - UV_sub;
			op4 <= U_G;
			op6 <= V_G;
		
			M1_state <= M1_LO5;
		end
		// LEAD OUT 5 //
		M1_LO5: begin
			SRAM_we_n <= 1'b1;
			G_val <= (result1-result2-result3) >> 16;
			
			op4 <= U_B;
			op6 <= V_B;
		
			M1_state <= M1_LO6;
		end
		// LEAD OUT 6 //
		M1_LO6: begin
			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_address + RGB_count;
			RGB_count <= RGB_count + 18'd1;
			
			// writing R38394 and G38394
			SRAM_write_data[15:8] <= (R_val[15] == 1'b1) ? 8'b0 : ((|R_val[15:8]) ? 8'd255 : R_val[7:0]); // If negative, use 0, if >255 use 255
			SRAM_write_data[7:0] <= (G_val[15] == 1'b1) ? 8'b0 : ((|G_val[15:8]) ? 8'd255 : G_val[7:0]);
			
			B_val <= (result1+result2+result3) >> 16;
			
			op1 <= U_p5 + U_m5;
			op2 <= coeff_UV5;
			op3 <= U_p3 + U_m3;
			op4 <= coeff_UV3;
			op5 <= U_p1 + U_m1;
			op6 <= coeff_UV1;
		
			M1_state <= M1_LO7;
		end
		// LEAD OUT 7 //
		M1_LO7: begin
			SRAM_we_n <= 1'b1;
		
			// read Y38396 and Y38397
			SRAM_address <= Y_address + Y_count;
			Y_count <= Y_count + 18'd1;
		
			U_val <= (result1-result2+result3+UV_sub) >> 8;
		
			op1 <= V_p5 + V_m5;
			op2 <= coeff_UV5;
			op3 <= V_p3 + V_m3;
			op4 <= coeff_UV3;
			op5 <= V_p1 + V_m1;
			op6 <= coeff_UV1;
		
			M1_state <= M1_LO8;		
		end
		// LEAD OUT 8 //
		M1_LO8: begin
			V_val <= (result1-result2+result3+UV_sub) >> 8;
			
			// R38395
			op1 <= Y_val[7:0] - Y_sub;
			op2 <= Y_RGB;
			op3 <= U_val;
			op4 <= U_R;
			op5 <= ((result1-result2+result3+UV_sub) >> 8)-UV_sub;
			op6 <= V_R;
		
			M1_state <= M1_LO9;
		end
		// LEAD OUT 9 //
		M1_LO9: begin
			R_val <= (result1+result2+result3) >> 16;
			
			// G38395
			op3 <= U_val - UV_sub;
			op4 <= U_G;
			op6 <= V_G;
		
			M1_state <= M1_LO10;
		end
		// LEAD OUT 10 //
		M1_LO10: begin
			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_address + RGB_count;
			RGB_count <= RGB_count + 18'd1;
			
			// write B38394 and R38395
			SRAM_write_data[15:8] <= (B_val[15] == 1'b1) ? 8'b0 : ((|B_val[15:8]) ? 8'd255 : B_val[7:0]); // If negative, use 0, if >255 use 255
			SRAM_write_data[7:0] <= (R_val[15] == 1'b1) ? 8'b0 : ((|R_val[15:8]) ? 8'd255 : R_val[7:0]);
		
			G_val <= (result1-result2-result3) >> 16;
			Y_val <= SRAM_read_data;
			U_val <= U_p1;
			
			op4 <= U_B;
			op6 <= V_B;
		
			M1_state <= M1_LO11;
		end
		// LEAD OUT 11 //
		M1_LO11: begin
			SRAM_we_n <= 1'b1;
			B_val <= (result1+result2+result3) >> 16;
			
			U_p1 <= U_p3;
			U_m1 <= U_p1;
			U_m3 <= U_m1;
			U_m5 <= U_m3;
			
			V_val <= V_p1;
			
			// R38396
			op1 <= Y_val[15:8] - Y_sub;
			op2 <= Y_RGB;
			op3 <= U_val;
			op4 <= U_R;
			op5 <= V_p1 - UV_sub;
			op6 <= V_R;
		
			M1_state <= M1_LO12;
		end
		// LEAD OUT 12 //
		M1_LO12: begin
			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_address + RGB_count;
			RGB_count <= RGB_count + 18'd1;
			
			// writing G38395 B38395
			SRAM_write_data[15:8] <= (G_val[31] == 1'b1) ? 8'b0 : ((|G_val[15:8]) ? 8'd255 : G_val[7:0]); // If negative, use 0, if >255 use 255
			SRAM_write_data[7:0] <= (B_val[31] == 1'b1) ? 8'b0 : ((|B_val[15:8]) ? 8'd255 : B_val[7:0]);
		
			R_val <= (result1+result2+result3) >> 16;
		
			V_p1 <= V_p3;
			V_m1 <= V_p1;
			V_m3 <= V_m1;
			V_m5 <= V_m3;
			
			// G38396
			op3 <= U_val - UV_sub;
			op4 <= U_G;
			op6 <= V_G;		
		
			M1_state <= M1_LO13;
		end
		// LEAD OUT 13 //
		M1_LO13: begin
			SRAM_we_n <= 1'b1;
			G_val <= (result1-result2-result3) >> 16;
			
			// B38396
			op4 <= U_B;
			op6 <= V_B;
		
			M1_state <= M1_LO14;
		end
		// LEAD OUT 14 //
		M1_LO14: begin
			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_address + RGB_count;
			RGB_count <= RGB_count + 18'd1;
			
			// writing R38396 G38396
			SRAM_write_data[15:8] <= (R_val[15] == 1'b1) ? 8'b0 : ((|R_val[15:8]) ? 8'd255 : R_val[7:0]); // If negative, use 0, if >255 use 255
			SRAM_write_data[7:0] <= (G_val[15] == 1'b1) ? 8'b0 : ((|G_val[15:8]) ? 8'd255 : G_val[7:0]);
		
			B_val <= (result1+result2+result3) >> 16;
		
			// U38397
			op1 <= U_p5 + U_m5;
			op2 <= coeff_UV5;
			op3 <= U_p3 + U_m3;
			op4 <= coeff_UV3;
			op5 <= U_p1 + U_m1;
			op6 <= coeff_UV1;
		
			M1_state <= M1_LO15;
		end
		// LEAD OUT 15 //
		M1_LO15: begin
			SRAM_we_n <= 1'b1;
			
			// read Y38398 and Y38399
			SRAM_address <= Y_address + Y_count;
			Y_count <= Y_count + 18'd1;
			
			U_val <= (result1-result2+result3+UV_sub) >> 8;
			
			// V38397
			op1 <= V_p5 + V_m5;
			op2 <= coeff_UV5;
			op3 <= V_p3 + V_m3;
			op4 <= coeff_UV3;
			op5 <= V_p1 + V_m1;
			op6 <= coeff_UV1;
			
			M1_state <= M1_LO16;		
		end
		// LEAD OUT 16 //
		M1_LO16: begin
			V_val <= (result1-result2+result3+UV_sub) >> 8;
			
			// R38397
			op1 <= Y_val[7:0] - Y_sub;
			op2 <= Y_RGB;
			op3 <= U_val;
			op4 <= U_R;
			op5 <= ((result1-result2+result3+UV_sub) >> 8)-UV_sub;
			op6 <= V_R;	
		
			M1_state <= M1_LO17;
		end
		// LEAD OUT 17 //
		M1_LO17: begin
			R_val <= (result1+result2+result3) >> 16;
			
			// G38397
			op3 <= U_val - UV_sub;
			op4 <= U_G;
			op6 <= V_G;
		
			M1_state <= M1_LO18;
		end
		// LEAD OUT 18 //
		M1_LO18: begin
			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_address + RGB_count;
			RGB_count <= RGB_count + 18'd1;
			
			// write B38396 and R38397
			SRAM_write_data[15:8] <= (B_val[15] == 1'b1) ? 8'b0 : ((|B_val[15:8]) ? 8'd255 : B_val[7:0]); // If negative, use 0, if >255 use 255
			SRAM_write_data[7:0] <= (R_val[15] == 1'b1) ? 8'b0 : ((|R_val[15:8]) ? 8'd255 : R_val[7:0]);
		
			G_val <= (result1-result2-result3) >> 16;
			Y_val <= SRAM_read_data;
			U_val <= U_p1;
			
			// B38397
			op4 <= U_B;
			op6 <= V_B;
		
			M1_state <= M1_LO19;
		end
		// LEAD OUT 19 //
		M1_LO19: begin
			SRAM_we_n <= 1'b1;
			B_val <= (result1+result2+result3) >> 16;
			
			U_m1 <= U_p1;
			U_m3 <= U_m1;
			U_m5 <= U_m3;
			
			V_val <= V_p1;
			
			// R38398
			op1 <= Y_val[15:8] - Y_sub;
			op2 <= Y_RGB;
			op3 <= U_val;
			op4 <= U_R;
			op5 <= V_p1 - UV_sub;
			op6 <= V_R;
		
			M1_state <= M1_LO20;
		end
		// LEAD OUT 20 //
		M1_LO20: begin
			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_address + RGB_count;
			RGB_count <= RGB_count + 18'd1;
			
			// writing G38397 B38397
			SRAM_write_data[15:8] <= (G_val[15] == 1'b1) ? 8'b0 : ((|G_val[15:8]) ? 8'd255 : G_val[7:0]); // If negative, use 0, if >255 use 255
			SRAM_write_data[7:0] <= (B_val[15] == 1'b1) ? 8'b0 : ((|B_val[15:8]) ? 8'd255 : B_val[7:0]);
		
			R_val <= (result1+result2+result3) >> 16;
		
			V_m1 <= V_p1;
			V_m3 <= V_m1;
			V_m5 <= V_m3;
			
			// G38398
			op3 <= U_val - UV_sub;
			op4 <= U_G;
			op6 <= V_G;		
		
			M1_state <= M1_LO21;
		end
		// LEAD OUT 21 //
		M1_LO21: begin
			SRAM_we_n <= 1'b1;
			G_val <= (result1-result2-result3) >> 16;
			
			// B38398
			op4 <= U_B;
			op6 <= V_B;
		
			M1_state <= M1_LO22;
		end
		// LEAD OUT 22 //
		M1_LO22: begin
			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_address + RGB_count;
			RGB_count <= RGB_count + 18'd1;
			
			// writing R38398 G38398
			SRAM_write_data[15:8] <= (R_val[15] == 1'b1) ? 8'b0 : ((|R_val[15:8]) ? 8'd255 : R_val[7:0]); // If negative, use 0, if >255 use 255
			SRAM_write_data[7:0] <= (G_val[15] == 1'b1) ? 8'b0 : ((|G_val[15:8]) ? 8'd255 : G_val[7:0]);
		
			B_val <= (result1+result2+result3) >> 16;
		
			// U38399
			op1 <= U_p5 + U_m5;
			op2 <= coeff_UV5;
			op3 <= U_p3 + U_m3;
			op4 <= coeff_UV3;
			op5 <= U_p1 + U_m1;
			op6 <= coeff_UV1;
		
			M1_state <= M1_LO23;
		end
		// LEAD OUT 23 //
		M1_LO23: begin
			SRAM_we_n <= 1'b1;
			
			U_val <= (result1-result2+result3+UV_sub) >> 8;
			
			// V38399
			op1 <= V_p5 + V_m5;
			op2 <= coeff_UV5;
			op3 <= V_p3 + V_m3;
			op4 <= coeff_UV3;
			op5 <= V_p1 + V_m1;
			op6 <= coeff_UV1;
			
			M1_state <= M1_LO24;		
		end
		// LEAD OUT 24 //
		M1_LO24: begin
			V_val <= (result1-result2+result3+UV_sub) >> 8;
			
			// R38399
			op1 <= Y_val[7:0] - Y_sub;
			op2 <= Y_RGB;
			op3 <= U_val;
			op4 <= U_R;
			op5 <= ((result1-result2+result3+UV_sub) >> 8)-UV_sub;
			op6 <= V_R;	
		
			M1_state <= M1_LO25;
		end
		// LEAD OUT 17 //
		M1_LO25: begin
			R_val <= (result1+result2+result3) >> 16;
			
			// G38399
			op3 <= U_val - UV_sub;
			op4 <= U_G;
			op6 <= V_G;
		
			M1_state <= M1_LO26;
		end
		// LEAD OUT 26 //
		M1_LO26: begin
			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_address + RGB_count;
			RGB_count <= RGB_count + 18'd1;
			
			// write B38398 and R38399
			SRAM_write_data[15:8] <= (B_val[15] == 1'b1) ? 8'b0 : ((|B_val[15:8]) ? 8'd255 : B_val[7:0]); // If negative, use 0, if >255 use 255
			SRAM_write_data[7:0] <= (R_val[15] == 1'b1) ? 8'b0 : ((|R_val[15:8]) ? 8'd255 : R_val[7:0]);
		
			G_val <= (result1-result2-result3) >> 16;
			
			// B38399
			op4 <= U_B;
			op6 <= V_B;
		
			M1_state <= M1_LO27;
		end
		// LEAD OUT 27 //
		M1_LO27: begin
			SRAM_we_n <= 1'b1;
			B_val <= (result1+result2+result3) >> 16;
		
			M1_state <= M1_LO28;
		end
		// LEAD OUT 28 //
		M1_LO28: begin
			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_address + RGB_count;
			RGB_count <= RGB_count + 18'd1;
			
			// write G38399 and B38399
			SRAM_write_data[15:8] <= (G_val[15] == 1'b1) ? 8'b0 : ((|G_val[15:8]) ? 8'd255 : G_val[7:0]); // If negative, use 0, if >255 use 255
			SRAM_write_data[7:0] <= (B_val[15] == 1'b1) ? 8'b0 : ((|B_val[15:8]) ? 8'd255 : B_val[7:0]);
			if(Y_count >= 38399) M1_finish <= 1'b1;
			else M1_state <= M1_IDLE;
		end
		default: M1_state <= M1_IDLE;
	
		endcase	
	end
end

endmodule
			
			 

		