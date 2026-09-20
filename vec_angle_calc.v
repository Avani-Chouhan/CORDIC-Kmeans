`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.02.2017 12:05:09
// Design Name: 
// Module Name: vec_angle_calc
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

module vec_angle_calc #(
        parameter ANGLE_WIDTH = 16,
        parameter CORDIC_STAGES = 16
    ) (
        input clk,
        input nreset,
        input [CORDIC_STAGES-1:0] enable_in,
        input [CORDIC_STAGES-1:0] micro_rot_dir_in,
        input [1:0] quad_in,
        input quad_vld_in,
        output reg signed [ANGLE_WIDTH-1:0] angle_out
    );
    // Angles are represented in ANGLE_WIDTH bits, where MSB position (ANGLE_WIDTH-1) is assigned 
    // a weight of -pi and bit position i (0 <= i <= ANGLE_WIDTH-2) is assigned a weight of pi/(2^(ANGLE_WIDTH-1-i)), 
    // i.e the weights are as follows: (From MSB to LSB) --> -pi, pi/2, pi/4, pi/8, pi/16, ...... , pi/(2^(ANGLE_WIDTH-1)).
    // For example, a value of 0110000000000000 is equal to (pi/2 + pi/4 = 3*pi/4). Similarly, 1001000000000000 
    // is equal to (-pi + pi/8 = -7*pi/8).
    
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
        
    genvar i;
    
    // The following register file is to store the angle computed after every micro-rotation stage.
    reg signed [ANGLE_WIDTH-1:0] angle_temp [CORDIC_STAGES-2:0];  
    
    // The first angle will be +/- pi/4
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            angle_temp[0] <= {ANGLE_WIDTH{1'b0}};
        else if (enable_in[0])
            angle_temp[0] <= micro_rot_dir_in[0] ? -atan[0] : atan[0];
    end
    
    // Each angle will be the value of the corresponding tan inverse added to or subtracted from 
    // the angle obtained in the previous stage. 
    generate 
        for (i=1;i<CORDIC_STAGES-1;i=i+1) begin: gen_CVM_angle_add
            always @(posedge clk or negedge nreset) begin
                if (~nreset)
                    angle_temp[i] <= {ANGLE_WIDTH{1'b0}};
                else if (enable_in[i])
                    angle_temp[i] <= micro_rot_dir_in[i] ? angle_temp[i-1]-atan[i] :
                                                                                angle_temp[i-1]+atan[i];
            end
        end
    endgenerate
    
    // This net stores the final angle. This is not a reg but a wire because there is another stage 
    // of combinational logic to compute it's actual value after taking quadrant into consideration.
    // This entire combinational logic is then registered later to be sent as output.
    wire signed [ANGLE_WIDTH-1:0] angle_final; 
    assign angle_final = enable_in[CORDIC_STAGES-1] && micro_rot_dir_in[CORDIC_STAGES-1] ?
                                                  angle_temp[CORDIC_STAGES-2] - atan[CORDIC_STAGES-1] :
                                                  angle_temp[CORDIC_STAGES-2] + atan[CORDIC_STAGES-1];
                                                   
    wire signed [ANGLE_WIDTH-1:0] angle_final_neg; //2's complement of angle_final
    assign angle_final_neg = ~angle_final[ANGLE_WIDTH-1:0] + 1'b1;
                                                   
    // This register file is to pass the quadrant value so that it is available in the final angle calculation.
    reg [1:0] quad_r [CORDIC_STAGES-1:0];
    
    integer k;
    always @(posedge clk or negedge nreset) begin
        if (~nreset) 
            for (k=0;k<CORDIC_STAGES;k=k+1)
                quad_r[k] <= 2'b00;
        else begin
            if (quad_vld_in) 
                quad_r[0] <= quad_in;
            
            for (k=1;k<CORDIC_STAGES;k=k+1)
                quad_r[k] <= enable_in[k-1] ? quad_r[k-1] : quad_r[k];
        end
    end
    
    // Denoting angle_final by theta, the angle output is calculated as follows:
    //
    //     quad_r[CORDIC_STAGES-1][1:0]         Quadrant        angle output         
    //                      00                                          1                     theta       
    //                      01                                          2                   pi - theta
    //                      11                                          3                  -pi + theta
    //                      10                                          4                    -theta
    //---------------------------------------------------------------------------------------------------------------------//       
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            angle_out <= {ANGLE_WIDTH{1'b0}};
        else if (enable_in[CORDIC_STAGES-1]) begin
            case (quad_r[CORDIC_STAGES-1])
                2'b00: angle_out <= angle_final;
                2'b01: angle_out <= {1'b0,angle_final_neg[ANGLE_WIDTH-2:0]}; 
                2'b11: angle_out <= {1'b1,angle_final[ANGLE_WIDTH-2:0]};
                2'b10: angle_out <= {1'b1,angle_final_neg[ANGLE_WIDTH-2:0]};            
            endcase
        end
    end
      
endmodule
