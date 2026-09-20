`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/10/2016 06:35:58 PM
// Design Name: 
// Module Name: rot_block
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

module rot_block #(
        parameter CORDIC_WIDTH = 22,
        parameter MICRO_ROT_STAGE = 1
    ) (
        input clk,
        input nreset,
        input enable,    
        input signed [CORDIC_WIDTH-1:0] x_in,
        input signed [CORDIC_WIDTH-1:0] y_in,
        input microRot_dir_in,

        output reg signed [CORDIC_WIDTH-1:0] x_out,
        output reg signed [CORDIC_WIDTH-1:0] y_out,    
        output reg enable_next
    );

    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            x_out <= {CORDIC_WIDTH{1'b0}};
            y_out <= {CORDIC_WIDTH{1'b0}};
            enable_next <= 1'b0;
        end
    
        else begin
            if (!enable) begin
                x_out <= {CORDIC_WIDTH{1'b0}};
                y_out <= {CORDIC_WIDTH{1'b0}};
                enable_next <= 1'b0;
            end
            
            else begin
                enable_next <= 1'b1;
                
                if (~microRot_dir_in) begin    // Clockwise Rotation
                    x_out <= x_in + {{MICRO_ROT_STAGE{y_in[CORDIC_WIDTH-1]}},y_in[CORDIC_WIDTH-1:MICRO_ROT_STAGE]};       
                    y_out <= y_in - {{MICRO_ROT_STAGE{x_in[CORDIC_WIDTH-1]}},x_in[CORDIC_WIDTH-1:MICRO_ROT_STAGE]};
                end
                            
                else begin                          // Anti-Clockwise Rotation  
                    x_out <= x_in - {{MICRO_ROT_STAGE{y_in[CORDIC_WIDTH-1]}},y_in[CORDIC_WIDTH-1:MICRO_ROT_STAGE]};
                    y_out <= y_in + {{MICRO_ROT_STAGE{x_in[CORDIC_WIDTH-1]}},x_in[CORDIC_WIDTH-1:MICRO_ROT_STAGE]};
                end
            end
        end
    end 
       
endmodule