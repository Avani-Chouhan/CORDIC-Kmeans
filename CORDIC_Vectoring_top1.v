`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.02.2017 13:03:05
// Design Name: 
// Module Name: CORDIC_Vectoring_top1
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
module CORDIC_Vectoring_top1 #(
        parameter DATA_WIDTH = 16,
        parameter CORDIC_WIDTH = 22,
        parameter CORDIC_STAGES = 16,
        parameter ANGLE_WIDTH = 16
    ) (        
        input clk,
        input nreset,
        input vec_en,
        input signed [DATA_WIDTH-1:0] x_vec_in,
        input signed [DATA_WIDTH-1:0] y_vec_in,
        input angle_calc_enable_in,   // If final angle value is desired, set this HIGH         
        output signed [DATA_WIDTH-1:0] x_vec_out,
        output output_valid_o,
        output [CORDIC_STAGES-1:0] micro_angle_o,
        output [1:0] quad_out,
        output vec_microRot_out_start,
        output signed [ANGLE_WIDTH-1:0] angle_out
    );
	 	
    wire [DATA_WIDTH-1:0] x_abs;	
    wire [DATA_WIDTH-1:0] y_abs;    
	wire [CORDIC_WIDTH-1:0] x_upscaled;
    wire [CORDIC_WIDTH-1:0] y_upscaled;
	wire upscaled_opvld;
	wire [CORDIC_STAGES*CORDIC_WIDTH-1:0] vect_stage_xin;  // The x-inputs to all the stages
    wire [CORDIC_STAGES*CORDIC_WIDTH-1:0] vect_stage_yin;  // The y-inputs to all the stages
    wire [CORDIC_STAGES-1:0] vect_stage_enable;            // The enable-inputs to all the stages
	wire signed [CORDIC_WIDTH-1:0] x_last_stage_out;     // output from 1last micro-rotation stage
	wire vec_op_vld;    
	wire signed [CORDIC_WIDTH-1:0] x_scaled_o;           // Output after multiplying with 0.627
    wire signed [DATA_WIDTH-1:0] x_downscale; 
    wire downscale_vld;   
    wire [CORDIC_STAGES-1:0] angle_calc_enable;
    wire angle_calc_quad_vld;    
    
    vec_quad_check Vec_Quad_chk(
        .clk (clk),
        .nreset (nreset),
        .enable (vec_en),
        .x_in_MSB (x_vec_in[DATA_WIDTH-1]),            
        .y_in_MSB (y_vec_in[DATA_WIDTH-1]),            
	    .quad_out (quad_out)
	);
	
	absolute_value #(
	   .DATA_WIDTH (DATA_WIDTH)
    ) abs (
        .x_in (x_vec_in),
        .y_in (y_vec_in),
	    .x_out (x_abs),
	    .y_out (y_abs)
	);
	
	ip_upscale #(
        .DATA_WIDTH (DATA_WIDTH),
        .CORDIC_WIDTH (CORDIC_WIDTH)
    ) ip_up(
        .x_in (x_abs),
        .y_in (y_abs),
        .x_out (x_upscaled),
        .y_out (y_upscaled)
    );
	
    assign vect_stage_enable[0] = vec_en;
    assign vect_stage_xin[CORDIC_WIDTH-1:0] = x_upscaled;
    assign vect_stage_yin[CORDIC_WIDTH-1:0] = y_upscaled;

	vec_block_first_stage #(
	    .CORDIC_WIDTH (CORDIC_WIDTH)
    ) Vec_Stage_0(
		.clk (clk),
        .nreset (nreset),
        .enable (vect_stage_enable[0]),
        .x_in (vect_stage_xin[CORDIC_WIDTH-1:0]),
        .y_in (vect_stage_yin[CORDIC_WIDTH-1:0]),
        .x_out (vect_stage_xin[2*CORDIC_WIDTH-1:CORDIC_WIDTH]),
        .y_out (vect_stage_yin[2*CORDIC_WIDTH-1:CORDIC_WIDTH]),
        .micro_rot_o (micro_angle_o[0]),
        .enable_next_stage (vect_stage_enable[1]),
        .vec_microRot_out_start (vec_microRot_out_start)
    );    	   
	
	genvar i;
	generate
        for (i=1;i<CORDIC_STAGES-1;i=i+1) begin: genblk_Vec_Stage_inst
	        vec_block #(
	            .CORDIC_WIDTH (CORDIC_WIDTH),
	            .MICRO_ROT_STAGE (i)
	        ) Vect_Block (
		        .clk (clk),
                .nreset (nreset),
                .enable (vect_stage_enable[i]),
                .x_in (vect_stage_xin[CORDIC_WIDTH*(i+1)-1:CORDIC_WIDTH*i]),
                .y_in (vect_stage_yin[CORDIC_WIDTH*(i+1)-1:CORDIC_WIDTH*i]),
                .x_out (vect_stage_xin[CORDIC_WIDTH*(i+2)-1:CORDIC_WIDTH*(i+1)]),
                .y_out (vect_stage_yin[CORDIC_WIDTH*(i+2)-1:CORDIC_WIDTH*(i+1)]),
                .micro_rot_o (micro_angle_o[i]),
                .enable_next_stage (vect_stage_enable[i+1])
            );
	    end
    endgenerate    
	
	vec_block_last_stage #(
        .CORDIC_WIDTH (CORDIC_WIDTH),
        .MICRO_ROT_STAGE (CORDIC_STAGES-1)
    ) Vec_Stage_Last(
        .clk (clk),
        .nreset (nreset),
        .enable (vect_stage_enable[CORDIC_STAGES-1]),
        .x_in (vect_stage_xin[CORDIC_WIDTH*(CORDIC_STAGES)-1:CORDIC_WIDTH*(CORDIC_STAGES-1)]),
        .y_in (vect_stage_yin[CORDIC_WIDTH*(CORDIC_STAGES)-1:CORDIC_WIDTH*(CORDIC_STAGES-1)]),
        .x_out (x_last_stage_out),
        .micro_rot_o (micro_angle_o[CORDIC_STAGES-1]),
        .op_valid (vec_op_vld)
    );           
	           		
	vec_scaling #(
        .CORDIC_WIDTH (CORDIC_WIDTH)
    ) scaling (
		.en (vec_op_vld),
		.x_in (x_last_stage_out),
		.scale_out (x_scaled_o)
	);
	
	vec_op_downscale #(
        .DATA_WIDTH (DATA_WIDTH),
        .CORDIC_WIDTH (CORDIC_WIDTH)
    ) op_down(
        .clk (clk),
        .nreset (nreset),
        .enable (vec_op_vld),
        .x_in (x_scaled_o),
        .x_out (x_downscale),
        .op_vld (downscale_vld)
    );
	
	// The enable signals to the angle calculation unit should go high after each stage has its
	// outputs ready. this is equivalent to the enable_next outputs from each of the individual 
	// micro-rotation blocks. For the last block, this signal is the vec_op_vld output.
	assign angle_calc_enable = angle_calc_enable_in ? 
	           {vec_op_vld,vect_stage_enable[CORDIC_STAGES-1:1]} : {CORDIC_STAGES{1'b0}};
	           
    // The quadrant input to angle calculation unit is valid when the enable signal to 
    // micro-rotation block 0 is high. 
	assign angle_calc_quad_vld = angle_calc_enable_in ? vect_stage_enable[0] : 2'b00;
	
	vec_angle_calc #(
	   .ANGLE_WIDTH (ANGLE_WIDTH),
	   .CORDIC_STAGES (CORDIC_STAGES)
	) angle_calculation (
	   .clk (clk),
	   .nreset (nreset),
       .enable_in (angle_calc_enable),
       .micro_rot_dir_in (micro_angle_o),
       .quad_in (quad_out),
       .quad_vld_in (angle_calc_quad_vld),
       .angle_out (angle_out)
	);
	      
	// Final Outputs
	assign x_vec_out = x_downscale;
	assign output_valid_o = downscale_vld;		
	
endmodule
