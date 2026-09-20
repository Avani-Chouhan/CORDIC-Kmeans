`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    01:42:55 10/31/2015 
// Design Name: 
// Module Name:    quad_chk 
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
module quad_chk #(
        parameter DATA_WIDTH = 16,
        parameter ANGLE_WIDTH = 16,
        parameter CORDIC_STAGES = 16
    ) (
    	input clk,
    	input nreset,
    	input signed [DATA_WIDTH-1:0] x_in,
        input signed [DATA_WIDTH-1:0] y_in,
        input signed [ANGLE_WIDTH-1:0] angle_in,
        input [CORDIC_STAGES-1:0] micro_rot_in,
        input enable,
        input angle_microRot_n,
        input [1:0] quad_in,
        
        output reg signed [DATA_WIDTH-1:0] x_out,
        output reg signed [DATA_WIDTH-1:0] y_out,  
        output reg signed [ANGLE_WIDTH-1:0] angle_out,
        output [CORDIC_STAGES-1:0] micro_rot_out    
    );
	
	wire [1:0] quad;
	// While using micro-rotation angles from Vectoring Mode, the quad encoding is based on sign bits of x and y inputs
	// and hence it is as follows: 00 - Q1, 01 - Q2, 11 - Q3, 10 - Q4. 
	// However, if the angle is given directly the encoding is based on the values of the bits corresponding to -pi and pi/2.
	// Therefore, in this case it is as follows: 00 - Q1, 01 - Q2, 10 - Q3, 11 - Q4.
	// To use one single format, a conversion is performed and the quad is represented using the latter format.
	// This is then used to complement (or not) the inputs.
	assign quad = angle_microRot_n ? angle_in[ANGLE_WIDTH-1:ANGLE_WIDTH-2] : {quad_in[1],quad_in[1]^quad_in[0]};	
    
    reg [CORDIC_STAGES-2:0] quad_r;
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            quad_r <= {CORDIC_STAGES-1{1'b0}};
        else
            quad_r <= {quad_r[CORDIC_STAGES-3:0],enable && quad[0]};
    end
                
    // If in 1st or 3rd quadrant, rotate in the same direction; else opp direction. This is determined by the
    // LSB of quad. if LSB is 0, it corresponds to Q1 or Q3. Else, it corresponds to Q2 or Q4.	
    assign micro_rot_out = {quad_r,quad[0]} ^ micro_rot_in;
    
	always @* begin
	    case ({enable,quad})
	        3'b100:									// 0 < angle < pi/2; give inputs as they are
			    begin
			        x_out = x_in;
					y_out = y_in;
					angle_out = angle_in;
				end
				
			3'b101: 
			    begin						// pi/2 < angle < pi; change inputs' sign; rotate by (pi - theta) in opp direction
				    x_out = ~x_in + 1'b1;	// 2's complement
					y_out = ~y_in + 1'b1;
				    angle_out = {1'b1,angle_in[ANGLE_WIDTH-2:0]};
				end
					
			3'b110:
			    begin						// -pi < angle < -pi/2; change inputs' sign; rotate by (theta - pi) in opp direction
				    x_out = ~x_in + 1'b1;	// 2's complement
					y_out = ~y_in + 1'b1;
				    angle_out = {1'b0,angle_in[ANGLE_WIDTH-2:0]};
				end
				
			3'b111: 
			    begin						// -pi/2 < angle < 0; give inputs as they are
				    x_out = x_in;
					y_out = y_in;
					angle_out = angle_in;
				end
						 
			default: 
			    begin
				    x_out = x_in;
					y_out = y_in;
					angle_out = angle_in;
				end
		endcase
	end	
		
endmodule