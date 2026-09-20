`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/10/2016 06:35:58 PM
// Design Name: 
// Module Name: rot_block_first_stage
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

module rot_block_first_stage #(
        parameter CORDIC_WIDTH = 22
    ) (
        input clk,
        input nreset,
        input enable,    
        input signed [CORDIC_WIDTH-1:0] x_in,
        input signed [CORDIC_WIDTH-1:0] y_in,
        input microRot_dir_in,

        output reg signed [CORDIC_WIDTH-1:0] x_out,
        output reg signed [CORDIC_WIDTH-1:0] y_out,    
        output reg enable_next,
        output reg rot_active
    );

    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            x_out <= {CORDIC_WIDTH{1'b0}};
            y_out <= {CORDIC_WIDTH{1'b0}};
            enable_next <= 1'b0;
            rot_active <= 1'b0;
        end

        else begin
            if (!enable) begin
                x_out <= {CORDIC_WIDTH{1'b0}};
                y_out <= {CORDIC_WIDTH{1'b0}};
                enable_next <= 1'b0;
                rot_active <= 1'b0;
            end
    
            else begin
                enable_next <= 1'b1;
                rot_active <= 1'b1;
                
                if (~microRot_dir_in) begin
                    x_out <= x_in + y_in;       
                    y_out <= y_in - x_in;
                end
                
                else begin
                    x_out <= x_in - y_in;
                    y_out <= y_in + x_in;
                end
            end
        end
    end 
    
endmodule
