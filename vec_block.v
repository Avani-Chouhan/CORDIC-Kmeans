`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/09/2016 10:48:24 PM
// Design Name: 
// Module Name: vec_block
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module vec_block #(
        parameter CORDIC_WIDTH = 22,
        parameter MICRO_ROT_STAGE = 1
    ) (
        input clk,
        input nreset,
       
        input enable,
        input signed [CORDIC_WIDTH-1:0] x_in,
        input signed [CORDIC_WIDTH-1:0] y_in,
       
        output signed [CORDIC_WIDTH-1:0] x_out,
        output signed [CORDIC_WIDTH-1:0] y_out,
        output reg micro_rot_o,
        output reg enable_next_stage
    );
	 
	reg signed [CORDIC_WIDTH-1:0]	x_temp_out;
	reg signed [CORDIC_WIDTH-1:0]	y_temp_out;
	
	assign x_out = x_temp_out;
	assign y_out = y_temp_out;
	
	always @(posedge clk or negedge nreset) begin
	    if (~nreset) begin
		    x_temp_out <= {CORDIC_WIDTH{1'b0}};
			y_temp_out <= {CORDIC_WIDTH{1'b0}};
			micro_rot_o <= 1'b0;
			enable_next_stage <= 1'b0;
		end
			
		else begin
			if (enable) begin
			    enable_next_stage <= 1'b1;

			    if (!(y_in[CORDIC_WIDTH-1])) begin
				    x_temp_out <= x_in + {{MICRO_ROT_STAGE{y_in[CORDIC_WIDTH-1]}}, y_in[CORDIC_WIDTH-1:MICRO_ROT_STAGE]};  
					y_temp_out <= y_in - {{MICRO_ROT_STAGE{x_in[CORDIC_WIDTH-1]}}, x_in[CORDIC_WIDTH-1:MICRO_ROT_STAGE]};  
					micro_rot_o <= 1'b0;
				end
							
				else begin
					x_temp_out <= x_in - {{MICRO_ROT_STAGE{y_in[CORDIC_WIDTH-1]}}, y_in[CORDIC_WIDTH-1:MICRO_ROT_STAGE]}; 
					y_temp_out <= y_in + {{MICRO_ROT_STAGE{x_in[CORDIC_WIDTH-1]}}, x_in[CORDIC_WIDTH-1:MICRO_ROT_STAGE]};  
					micro_rot_o <= 1'b1;
				end
			end
					
			else 
				enable_next_stage <= 1'b0;
		end
	end	
	
endmodule