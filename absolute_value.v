`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/10/2016 01:41:57 PM
// Design Name: 
// Module Name: absolute_value
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

module absolute_value #(
        parameter DATA_WIDTH = 16
    ) (
        input signed [DATA_WIDTH-1:0] x_in,
        input signed [DATA_WIDTH-1:0] y_in,
        output reg [DATA_WIDTH-1:0] x_out,
        output reg [DATA_WIDTH-1:0] y_out
    );
    
    always @* begin
        x_out = x_in[DATA_WIDTH-1] ? {1'b0,~x_in[DATA_WIDTH-2:0]+1'b1} : x_in;
        y_out = y_in[DATA_WIDTH-1] ? {1'b0,~y_in[DATA_WIDTH-2:0]+1'b1} : y_in;
    end
                
endmodule
