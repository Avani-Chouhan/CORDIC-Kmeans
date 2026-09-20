`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:43:18 11/10/2015 
// Design Name: 
// Module Name:    ip_upscale 
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
module ip_upscale #(
        parameter DATA_WIDTH = 16,
        parameter CORDIC_WIDTH = 22
    ) (
//        input clk,
//        input nreset,
	    input [DATA_WIDTH-1:0] x_in,
        input [DATA_WIDTH-1:0] y_in,
//        input enable,
    
//        output reg [CORDIC_WIDTH-1:0] x_out,
//        output reg [CORDIC_WIDTH-1:0] y_out,
//        output reg op_vld
        output [CORDIC_WIDTH-1:0] x_out,
        output [CORDIC_WIDTH-1:0] y_out

    );
    
    assign x_out = {x_in,{CORDIC_WIDTH-DATA_WIDTH{1'b0}}};
    assign y_out = {y_in,{CORDIC_WIDTH-DATA_WIDTH{1'b0}}};
        
//    always @(posedge clk or negedge nreset) begin
//        if (~nreset) begin
//            x_out <= {CORDIC_WIDTH{1'b0}};
//            y_out <= {CORDIC_WIDTH{1'b0}};
//            op_vld <= 1'b0;
//        end
        
//        else begin
//	        x_out <= {x_in,{CORDIC_WIDTH-DATA_WIDTH{1'b0}}};
//	        y_out <= {y_in,{CORDIC_WIDTH-DATA_WIDTH{1'b0}}};
//	        op_vld <= enable;
//	    end
//	end
	
endmodule
