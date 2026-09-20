`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:53:27 11/10/2015 
// Design Name: 
// Module Name:    op_downscale 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module op_downscale #(
        parameter CORDIC_WIDTH = 22,
        parameter DATA_WIDTH = 16
   ) (
	    input clk,
	    input nreset,
	    input [CORDIC_WIDTH-1:0] x_in,
        input [CORDIC_WIDTH-1:0] y_in,
        input enable,
        
        output [DATA_WIDTH-1:0] x_out,
        output [DATA_WIDTH-1:0] y_out,
        output op_vld
    );

	reg signed [DATA_WIDTH-1:0] x_downscaled;
    reg signed [DATA_WIDTH-1:0] y_downscaled;
    reg enable_r;
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            x_downscaled <= {DATA_WIDTH{1'b0}};
            y_downscaled <= {DATA_WIDTH{1'b0}};
            enable_r <= 1'b0;
        end
        
        else begin
            if (enable) begin   
                x_downscaled <= x_in [CORDIC_WIDTH-1:CORDIC_WIDTH-DATA_WIDTH];
                y_downscaled <= y_in [CORDIC_WIDTH-1:CORDIC_WIDTH-DATA_WIDTH];
                enable_r <= 1'b1;
            end
            
            else
                enable_r <= 1'b0;
        end
    end
    
    assign x_out = x_downscaled;
    assign y_out = y_downscaled;
    assign op_vld = enable_r;

endmodule
