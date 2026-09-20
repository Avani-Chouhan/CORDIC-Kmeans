`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/10/2016 07:03:20 PM
// Design Name: 
// Module Name: micro_rot_gen
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

module micro_rot_gen #(
        parameter ANGLE_WIDTH = 16,
        parameter CORDIC_STAGES = 16
    ) (
        input clk,
        input nreset,
        input enable_in,
        input angle_microRot_n,
        input signed [ANGLE_WIDTH-1:0] angle_in,     
        input [CORDIC_STAGES-1:0] micro_rot_in,   
        output [CORDIC_STAGES-1:0] micro_rot_out
    );
    
    reg [ANGLE_WIDTH-1:0] atan [CORDIC_STAGES-1:0];
    always @(posedge clk) begin
        atan[0] <= 16'h2000;
        atan[1] <= 16'h12E4;
        atan[2] <= 16'h09FB;
        atan[3] <= 16'h0511;
        atan[4] <= 16'h028B;
        atan[5] <= 16'h0145;
        atan[6] <= 16'h00A2;
        atan[7] <= 16'h0051;
        atan[8] <= 16'h0028;
        atan[9] <= 16'h0014;
        atan[10] <= 16'h000A;
        atan[11] <= 16'h0005;
        atan[12] <= 16'h0002;
        atan[13] <= 16'h0001;
        atan[14] <= 16'h0000;
        atan[15] <= 16'h0000;
    end
    
    reg [CORDIC_STAGES-2:0] angle_microRot_n_r;
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            angle_microRot_n_r <= {CORDIC_STAGES-1{1'b0}};
        else
            angle_microRot_n_r <= {angle_microRot_n_r[CORDIC_STAGES-3:0],enable_in && angle_microRot_n};
    end
    
    reg signed [ANGLE_WIDTH-1:0] angle_diff [CORDIC_STAGES-2:0];
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            angle_diff[0] <= {ANGLE_WIDTH{1'b0}};
        else begin
            if (enable_in && angle_microRot_n) begin
                if (angle_in[ANGLE_WIDTH-1])
                    angle_diff[0] <= angle_in + atan[0]; 
                else
                    angle_diff[0] <= angle_in - atan[0];
            end
            
            else if (~enable_in && angle_microRot_n_r[0])
                angle_diff[0] <= {ANGLE_WIDTH{1'b0}};
        end 
    end
    
    genvar i;        
    generate
        for (i=1;i<CORDIC_STAGES-1;i=i+1) begin:genblk_CRM_angle_diff
            always @(posedge clk or negedge nreset) begin
                if (~nreset)
                    angle_diff[i] <= {ANGLE_WIDTH{1'b0}};
                else if (angle_microRot_n_r[i-1]) begin
                    if (angle_diff[i-1][ANGLE_WIDTH-1])
                        angle_diff[i] <= angle_diff[i-1] + atan[i];
                    else
                        angle_diff[i] <= angle_diff[i-1] - atan[i];
                end
            end
        end
    endgenerate 
        
    wire [CORDIC_STAGES-1:0] micro_rot;
    assign micro_rot[0] = angle_in[ANGLE_WIDTH-1];
    
    generate  
        for (i=1;i<CORDIC_STAGES;i=i+1) begin:genblk_microRot_angle_direct
            assign micro_rot[i] = angle_diff[i-1][ANGLE_WIDTH-1];
        end
    endgenerate
    
    assign micro_rot_out[0] = angle_microRot_n ? micro_rot[0] : micro_rot_in[0];
    
    generate  
        for (i=1;i<CORDIC_STAGES;i=i+1) begin:genblk_microRot_out  
            assign micro_rot_out[i] = angle_microRot_n_r[i-1] ? micro_rot[i] : micro_rot_in[i];
        end
    endgenerate
    
endmodule
