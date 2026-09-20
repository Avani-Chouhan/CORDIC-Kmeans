`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    01:25:28 10/31/2015 
// Design Name: 
// Module Name:    output_scale 
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
module output_scale #(
        parameter CORDIC_WIDTH = 22
    ) (
	    input signed [CORDIC_WIDTH-1:0] x_in,
        input signed [CORDIC_WIDTH-1:0] y_in,
        input en,
        output reg signed [CORDIC_WIDTH-1:0] x_out,
        output reg signed [CORDIC_WIDTH-1:0] y_out    
    );
	
	always @* begin 
	   if (en) begin
	       x_out = {x_in[CORDIC_WIDTH-1],x_in[CORDIC_WIDTH-1:1]} + {{4{x_in[CORDIC_WIDTH-1]}},x_in[CORDIC_WIDTH-1:4]} +
						{{5{x_in[CORDIC_WIDTH-1]}},x_in[CORDIC_WIDTH-1:5]} + {{7{x_in[CORDIC_WIDTH-1]}},x_in[CORDIC_WIDTH-1:7]} +
						{{8{x_in[CORDIC_WIDTH-1]}},x_in[CORDIC_WIDTH-1:8]} + {{10{x_in[CORDIC_WIDTH-1]}},x_in[CORDIC_WIDTH-1:10]} +
						{{11{x_in[CORDIC_WIDTH-1]}},x_in[CORDIC_WIDTH-1:11]} + {{12{x_in[CORDIC_WIDTH-1]}},x_in[CORDIC_WIDTH-1:12]} +
						{{14{x_in[CORDIC_WIDTH-1]}},x_in[CORDIC_WIDTH-1:14]};
						
	       y_out = {y_in[CORDIC_WIDTH-1],y_in[CORDIC_WIDTH-1:1]} + {{4{y_in[CORDIC_WIDTH-1]}},y_in[CORDIC_WIDTH-1:4]} +
                        {{5{y_in[CORDIC_WIDTH-1]}},y_in[CORDIC_WIDTH-1:5]} + {{7{y_in[CORDIC_WIDTH-1]}},y_in[CORDIC_WIDTH-1:7]} +
                        {{8{y_in[CORDIC_WIDTH-1]}},y_in[CORDIC_WIDTH-1:8]} + {{10{y_in[CORDIC_WIDTH-1]}},y_in[CORDIC_WIDTH-1:10]} +
                        {{11{y_in[CORDIC_WIDTH-1]}},y_in[CORDIC_WIDTH-1:11]} + {{12{y_in[CORDIC_WIDTH-1]}},y_in[CORDIC_WIDTH-1:12]} +
                        {{14{y_in[CORDIC_WIDTH-1]}},y_in[CORDIC_WIDTH-1:14]};
       end
                                    
	   else begin
	       x_out = {CORDIC_WIDTH{1'b0}};
	       y_out = {CORDIC_WIDTH{1'b0}};
       end
   end
   			
endmodule