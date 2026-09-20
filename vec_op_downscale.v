`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/29/2016 06:23:14 PM
// Design Name: 
// Module Name: vec_op_downscale
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

module vec_op_downscale #(
        parameter CORDIC_WIDTH = 22,
        parameter DATA_WIDTH = 16
   ) (  
        input clk,
        input nreset,
        input enable,
	    input signed [CORDIC_WIDTH-1:0] x_in,
        output signed [DATA_WIDTH-1:0] x_out,
        output op_vld
    );
	
	reg signed [DATA_WIDTH-1:0] x_downscaled;
	reg enable_r;
	
	always @(posedge clk or negedge nreset) begin
	    if (~nreset) begin
	        x_downscaled <= {DATA_WIDTH{1'b0}};
	        enable_r <= 1'b0;
	    end
	    
	    else begin
	        if (enable) begin   
			    x_downscaled <= x_in [CORDIC_WIDTH-1:CORDIC_WIDTH-DATA_WIDTH];
                enable_r <= 1'b1;
            end
            
            else
                enable_r <= 1'b0;
        end
    end
    
    assign x_out = x_downscaled;
    assign op_vld = enable_r;
    
endmodule