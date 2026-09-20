`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/25/2016 03:29:58 PM
// Design Name: 
// Module Name: constants
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

`define INPUT_TYPE_PAR 0        // Set to 0 for seqeuntial input; 1 for parallel inputs
                                // Sequential input means giving the mixed signals one after the other
                                // Parallel input means giving the mixed signals all at once
`define DATA_WIDTH 32           // width of input and output data
`define N_SAMPLES 2048          // number of samples in the input
`define DIM 4                  // Number of dimensions, ex: 4,5,6, etc.
`define DATA_SCALE_FACTOR 20  // Input data is the actual data scaled by (2^10)

`define CORDIC_WIDTH 38         // width of data after upscaling inside the CORDIC module 
`define CORDIC_STAGES 16        // Number of CORDIC Micro-Rotation Stages    
`define ANGLE_WIDTH 16          // Angle Width of CORDIC; used when Angle is directly given to Rotation Mode.

`define MULT_LATENCY 3          // Multiplier output is available for use on 3rd clock 
                                // after inputs are given. In case some other multiplier 
                                // with different latency is used, please change this accordingly.    

`define SYNTHESIS_TOOL "VIVADO"   
`define CORDIC_LATENCY 18                            
`define NO_OF_CLUSTERS 5