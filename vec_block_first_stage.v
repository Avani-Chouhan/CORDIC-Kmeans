`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/09/2016 10:34:11 PM
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

module vec_block_first_stage #(
        parameter CORDIC_WIDTH = 22
    ) (
        input clk,
        input nreset,
        
        input enable,
        input signed [CORDIC_WIDTH-1:0] x_in,
        input signed [CORDIC_WIDTH-1:0] y_in,
		
		output signed [CORDIC_WIDTH-1:0] x_out,
		output signed [CORDIC_WIDTH-1:0] y_out,
        output reg micro_rot_o,
        output reg enable_next_stage,
        output reg vec_microRot_out_start         
    );
    
    reg signed [CORDIC_WIDTH-1:0] x_temp_out;
    reg signed [CORDIC_WIDTH-1:0] y_temp_out;
    
    assign x_out = x_temp_out;
    assign y_out = y_temp_out;
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            x_temp_out <= {CORDIC_WIDTH{1'b0}};
            y_temp_out <= {CORDIC_WIDTH{1'b0}};
            micro_rot_o <= 1'b0;
            enable_next_stage <= 1'b0;
            vec_microRot_out_start <= 1'b0;
        end
            
        else begin
            if (enable) begin
                x_temp_out <= x_in + y_in;  //clkwise rotation by 45 degree
                y_temp_out <= y_in - x_in;  //clkwise rotation by 45 degree
                micro_rot_o <= 1'b0;
                enable_next_stage <= 1'b1;
                vec_microRot_out_start <= 1'b1;
            end
                    
            else begin
                enable_next_stage <= 1'b0;
                vec_microRot_out_start <= 1'b0;
            end
        end
    end    
    
endmodule
