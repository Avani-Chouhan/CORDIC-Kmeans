`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.02.2017 21:22:29
// Design Name: 
// Module Name: CORDIC_doubly_pipe_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This module contains CORDIC Vectoring and Rotation Blocks.
//                     The angle to Rotation can be given directly or in the form of 
// individual micro-rotation angles. The micro-rotation angles can be given 
// either externally (by the user) or can be directly taken from Vectoring 
// depending on user requirement. 
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module CORDIC_doubly_pipe_top #(
        parameter DATA_WIDTH = 16,
        parameter CORDIC_WIDTH = 22,
        parameter ANGLE_WIDTH = 16,
        parameter CORDIC_STAGES = 16
    ) (
        input clk,
        input nreset,
        // Vectoring Inputs
        input cordic_vec_en,
        input signed [DATA_WIDTH-1:0] cordic_vec_xin,
        input signed [DATA_WIDTH-1:0] cordic_vec_yin,
        input cordic_vec_angle_calc_en,                                        // Enable calculation of total angle from the micro-angles
        // Rotation Inputs
        input cordic_rot_en,
        input signed [DATA_WIDTH-1:0] cordic_rot_xin,
        input signed [DATA_WIDTH-1:0] cordic_rot_yin,
        input cordic_rot_angle_microRot_n,                              // HIGH => Rotation Angle is given directly; LOW => Angle given as micro-rotations
        input signed [ANGLE_WIDTH-1:0] cordic_rot_angle_in,     
        input [CORDIC_STAGES-1:0] cordic_rot_microRot_ext_in,
        input cordic_rot_microRot_ext_vld,                                 // If HIGH => Micro-rotations are given from outside; LOW => Directly from Vectoring
        input [1:0] cordic_rot_quad_in,        
        // Vectoring Outputs
        output cordic_vec_opvld,
        output signed [DATA_WIDTH-1:0] cordic_vec_xout,
        output [1:0] vec_quad,
        output signed [ANGLE_WIDTH-1:0] vec_angle_out,
        output [CORDIC_STAGES-1:0] vec_microRot_dir, 
        output vec_microRot_out_start,
       // Rotation Outputs
        output cordic_rot_opvld,
        output signed [DATA_WIDTH-1:0] cordic_rot_xout,
        output signed [DATA_WIDTH-1:0] cordic_rot_yout
    );
    
    reg [CORDIC_STAGES-1:0] cordic_rot_microRot_ext_r;
    reg [CORDIC_STAGES-1:0] cordic_rot_microRot_ext_vld_r;
    reg [1:0] vec_quad_r;
    
    wire [CORDIC_STAGES-1:0] rot_microRot_dir;
    wire [CORDIC_STAGES-1:0] cordic_rot_microRot;   // Actual Micro-rotation inputs to Rotation Mode
    wire [1:0] rot_quad;
    
    //------------------------------------------------------------------------------------//
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            cordic_rot_microRot_ext_r <= {CORDIC_STAGES{1'b0}};        
        else
            cordic_rot_microRot_ext_r <= cordic_rot_microRot_ext_in;
    end
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            cordic_rot_microRot_ext_vld_r <= {CORDIC_STAGES{1'b0}};
        else
            cordic_rot_microRot_ext_vld_r <= {cordic_rot_microRot_ext_vld_r[CORDIC_STAGES-2:0],
                                                                  cordic_rot_en && cordic_rot_microRot_ext_vld};
    end
        
    genvar i;
    // The micro-rotation inputs to CRM.
    assign cordic_rot_microRot[0] = cordic_rot_microRot_ext_vld ? 
                                                      cordic_rot_microRot_ext_in[0] : vec_microRot_dir[0];
    generate
        for (i=1;i<CORDIC_STAGES;i=i+1) begin:gen_CRM_microRot            
            assign cordic_rot_microRot[i] = cordic_rot_microRot_ext_vld_r[i-1] ? 
                                                              cordic_rot_microRot_ext_in[i] : vec_microRot_dir[i];           
        end    
    endgenerate
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            vec_quad_r <= 2'b00;
        else if (cordic_vec_en)   
            vec_quad_r <= vec_quad;
    end
        
    assign rot_quad = cordic_rot_microRot_ext_vld ? cordic_rot_quad_in : vec_quad_r;
    
    CORDIC_Vectoring_top1 #(
        .DATA_WIDTH (DATA_WIDTH),
        .CORDIC_WIDTH (CORDIC_WIDTH),
        .CORDIC_STAGES (CORDIC_STAGES),
        .ANGLE_WIDTH (ANGLE_WIDTH)
    ) CORDIC_Vectoring_Mode(        
        .clk (clk),
        .nreset (nreset),
        .vec_en (cordic_vec_en),
        .x_vec_in (cordic_vec_xin),
        .y_vec_in (cordic_vec_yin),
        .angle_calc_enable_in (cordic_vec_angle_calc_en),
        .x_vec_out (cordic_vec_xout),
        .output_valid_o (cordic_vec_opvld),
        .micro_angle_o (vec_microRot_dir),
        .quad_out (vec_quad),
        .vec_microRot_out_start (vec_microRot_out_start),
        .angle_out (vec_angle_out)        
    );
     
    CORDIC_Rotation_top #(
        .DATA_WIDTH (DATA_WIDTH),
        .CORDIC_WIDTH (CORDIC_WIDTH),
        .ANGLE_WIDTH (ANGLE_WIDTH),
        .CORDIC_STAGES (CORDIC_STAGES)
    ) CORDIC_Rotation_Mode(
        .clk (clk),
        .nreset (nreset),
        .enable_in (cordic_rot_en),
        .angle_microRot_n (cordic_rot_angle_microRot_n),                     // HIGH when angle is directly given; LOW when Micro-rotation is given from Vectoring
        .x_in (cordic_rot_xin),
        .y_in (cordic_rot_yin),
        .angle_in (cordic_rot_angle_in),
        .microRot_dir_in (cordic_rot_microRot),
        .quad_in (rot_quad),
        .x_out (cordic_rot_xout),
        .y_out (cordic_rot_yout),
        .output_valid_o (cordic_rot_opvld)
    );
       
endmodule