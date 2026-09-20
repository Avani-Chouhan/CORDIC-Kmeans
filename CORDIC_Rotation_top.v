`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    02:00:47 10/31/2015 
// Design Name: 
// Module Name:    CORDIC_Rotation_top 
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
module CORDIC_Rotation_top #(
        parameter DATA_WIDTH = 16,
        parameter CORDIC_WIDTH = 22,
        parameter ANGLE_WIDTH = 16,
        parameter CORDIC_STAGES = 16
    ) (
        input clk,
        input nreset,
        input enable_in,
        input angle_microRot_n,                     // HIGH when angle is directly given; LOW when Micro-rotation is given from Vectoring
        input signed [DATA_WIDTH-1:0] x_in,
        input signed [DATA_WIDTH-1:0] y_in,
        input signed [ANGLE_WIDTH-1:0] angle_in,    // is used only when angle_microRot_n is HIGH
        input [CORDIC_STAGES-1:0] microRot_dir_in,  // Micro Rotation Directions given from Vectoring
        input microRot_vld,                         // Useful in ICA. During Iteration stage, all micro-angles are available after 16 VM cycles, 
                                                              // bu they are used by RM for like 1024 cycles. 
        input [1:0] quad_in,                        // This is used to indicate which quadrant the angle is in, 
                                                              // when it is given as micro rotations from Vectoring block,                                                                                 
        output signed [DATA_WIDTH-1:0] x_out,
        output signed [DATA_WIDTH-1:0] y_out,
        output output_valid_o,
        output rot_active_o
    );
		
	//----------------------------------//
	wire signed [DATA_WIDTH-1:0] x_quadChk_out;	
    wire signed [DATA_WIDTH-1:0] y_quadChk_out;
	wire [CORDIC_STAGES-1:0] micro_rot_quadChk_out;
	wire signed [ANGLE_WIDTH-1:0] angle;
	
	wire signed [CORDIC_WIDTH-1:0] x_upscaled;
	wire signed [CORDIC_WIDTH-1:0] y_upscaled;	
	wire upscaled_opvld;
	
    wire [CORDIC_STAGES-1:0] microRot_dir;
    wire [CORDIC_STAGES-1:0] enable;
    wire [CORDIC_STAGES*CORDIC_WIDTH-1:0] rot_stage_xin;
    wire [CORDIC_STAGES*CORDIC_WIDTH-1:0] rot_stage_yin;            
    wire signed [CORDIC_WIDTH-1:0] rot_lastStage_xout;
    wire signed [CORDIC_WIDTH-1:0] rot_lastStage_yout;
	wire rot_LastStage_opvld;
	wire signed [CORDIC_WIDTH-1:0] x_scaled_out;
	wire signed [CORDIC_WIDTH-1:0] y_scaled_out;	
	wire signed [DATA_WIDTH-1:0] x_downscale;
    wire signed [DATA_WIDTH-1:0] y_downscale;
    wire downscale_vld;
	
	//--------------------------------//	
	quad_chk #(
	    .DATA_WIDTH (DATA_WIDTH),
	    .ANGLE_WIDTH (ANGLE_WIDTH),
	    .CORDIC_STAGES (CORDIC_STAGES)
	) Quad(  
		.x_in (x_in),
		.y_in (y_in),
		.angle_in (angle_in),
		.micro_rot_in (microRot_dir_in),
		.enable (enable_in),
		.angle_microRot_n (angle_microRot_n),
		.quad_in (quad_in),
		.x_out (x_quadChk_out),
		.y_out (y_quadChk_out),
		.angle_out (angle),
		.micro_rot_out (micro_rot_quadChk_out)
	);
	
	ip_upscale #(
        .DATA_WIDTH (DATA_WIDTH),
        .CORDIC_WIDTH (CORDIC_WIDTH)
    ) ip_up(
        //.clk (clk),
        //.nreset (nreset),
       // .enable (enable_in),
        .x_in (x_quadChk_out),
        .y_in (y_quadChk_out),
        .x_out (x_upscaled),
        .y_out (y_upscaled)
        //.op_vld (upscaled_opvld)        
    );
    
    micro_rot_gen #(
        .ANGLE_WIDTH (ANGLE_WIDTH),
        .CORDIC_STAGES (CORDIC_STAGES)
    ) microRot_Gen(
        .clk (clk),
        .nreset (nreset),
       // .enable (enable_in),
        .angle_microRot_n (angle_microRot_n),
        .micro_rot_in (micro_rot_quadChk_out),
		//.microRot_vld (microRot_vld),
        .angle_in (angle),
        .micro_rot_out (microRot_dir)
    );
    
    assign rot_stage_xin[CORDIC_WIDTH-1:0] = x_upscaled;
    assign rot_stage_yin[CORDIC_WIDTH-1:0] = y_upscaled;
    assign enable[0] = upscaled_opvld;
        
	rot_block_first_stage #(
	    .CORDIC_WIDTH (CORDIC_WIDTH)
	) Rot_Stage_0 (
	    .clk (clk),
	    .nreset (nreset),
	    .enable (enable[0]),
	    .x_in (rot_stage_xin[CORDIC_WIDTH-1:0]),
	    .y_in (rot_stage_yin[CORDIC_WIDTH-1:0]),
        .microRot_dir_in (microRot_dir[0]),
        .x_out (rot_stage_xin[CORDIC_WIDTH*2-1:CORDIC_WIDTH]),
        .y_out (rot_stage_yin[CORDIC_WIDTH*2-1:CORDIC_WIDTH]),    
        .enable_next (enable[1]),
        .rot_active (rot_active_o)
	);    	
	     
	genvar i;
	generate
        for (i=1;i<CORDIC_STAGES-1;i=i+1) begin: Rot_Stage
	        rot_block #(
	            .CORDIC_WIDTH (CORDIC_WIDTH),
	            .MICRO_ROT_STAGE (i)
	        ) MicroRot_Stage (
        	    .clk (clk),
                .nreset (nreset),
                .enable (enable[i]),
                .x_in (rot_stage_xin[CORDIC_WIDTH*(i+1)-1:CORDIC_WIDTH*i]),
                .y_in (rot_stage_yin[CORDIC_WIDTH*(i+1)-1:CORDIC_WIDTH*i]),
                .microRot_dir_in (microRot_dir[i]),
                .x_out (rot_stage_xin[CORDIC_WIDTH*(i+2)-1:CORDIC_WIDTH*(i+1)]),
                .y_out (rot_stage_yin[CORDIC_WIDTH*(i+2)-1:CORDIC_WIDTH*(i+1)]),    
                .enable_next (enable[i+1])
            );	            
	    end
	endgenerate

	rot_block_last_stage #(
	    .CORDIC_WIDTH (CORDIC_WIDTH)
	) Rot_Stage_Last (
	    .clk (clk),
	    .nreset (nreset),
	    .enable (enable[CORDIC_STAGES-1]),
	    .x_in (rot_stage_xin[CORDIC_WIDTH*(CORDIC_STAGES)-1:CORDIC_WIDTH*(CORDIC_STAGES-1)]),
	    .y_in (rot_stage_yin[CORDIC_WIDTH*(CORDIC_STAGES)-1:CORDIC_WIDTH*(CORDIC_STAGES-1)]),
        .microRot_dir_in (microRot_dir[CORDIC_STAGES-1]),
        .x_out (rot_lastStage_xout),
        .y_out (rot_lastStage_yout)  
        //.op_vld (rot_LastStage_opvld)
	);    		
	
	output_scale #(
	    .CORDIC_WIDTH (CORDIC_WIDTH)
	) scaling (
		.x_in (rot_lastStage_xout),
		.y_in (rot_lastStage_yout),
		.en (rot_LastStage_opvld),
		.x_out (x_scaled_out),
		.y_out (y_scaled_out)
    );
	 
	op_downscale #(
	    .DATA_WIDTH (DATA_WIDTH),
        .CORDIC_WIDTH (CORDIC_WIDTH)
    ) op_down(
        .clk (clk),
        .nreset (nreset),
        .enable (rot_LastStage_opvld),
		.x_in (x_scaled_out),
		.y_in (y_scaled_out),
		.x_out (x_downscale),
		.y_out (y_downscale),
		.op_vld (downscale_vld)
    );
    	
	// Final Outputs
	assign x_out = x_downscale;
	assign y_out = y_downscale;
    assign output_valid_o = downscale_vld;
    
endmodule
