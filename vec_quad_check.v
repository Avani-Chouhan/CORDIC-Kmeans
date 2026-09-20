`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/12/2016 02:35:40 PM
// Design Name: 
// Module Name: vec_quad_check
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

module vec_quad_check(
        input clk,
        input nreset,
        input enable,
        input x_in_MSB,
        input y_in_MSB,
        output [1:0] quad_out
    );
    
    reg [1:0] quad;    
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            quad <= 2'b00;
        else if (enable)
            quad <= {y_in_MSB,x_in_MSB};
    end
    
    assign quad_out = enable ? {y_in_MSB,x_in_MSB} : quad;
    
endmodule