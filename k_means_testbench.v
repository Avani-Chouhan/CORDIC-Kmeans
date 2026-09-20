`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.04.2017 17:11:20
// Design Name: 
// Module Name: k_means_testbench
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

`include "C:/Users/ashle/Downloads/kmeans_codes/kmeans_rtl_swati/constants.v"

module k_means_testbench;    
    
    parameter DATA_WIDTH = `DATA_WIDTH;
    parameter NO_OF_CLUSTERS = `NO_OF_CLUSTERS;
    parameter  NO_OF_CLUSTERS_WIDTH = $clog2(NO_OF_CLUSTERS);

    reg clk, nreset;
    reg signed [DATA_WIDTH-1 :0] data_in;
    reg data_vld_in;
    wire output_vld  ;
    wire [NO_OF_CLUSTERS_WIDTH-1:0] cluster_no_out;
    
    k_means_top k_means_top_inst(       
        .clk (clk),
        .nreset (nreset),
        .data_in (data_in),
        .data_vld_in (data_vld_in),
        .output_vld (output_vld),
        .cluster_no_out (cluster_no_out)
    );
    
	integer fp_in =0 , status =0 ;


    initial begin
        // Initialize Inputs
        clk = 0;
        nreset = 0;
        data_in = 0;
        fp_in = $fopen("C:\\Users\\ashle\\Downloads\\kmeans_codes\\kmeans_rtl_swati\\k_means_input.txt","r");
        //$readmemh("data_inmemory.mem" ,mem);
        // Wait 100 ns for global reset to finish
        #100;
        
        // Add stimulus here
        nreset = 1'b1;
    end
    
    initial begin
     data_vld_in = 1'b0;
       repeat(1) @ (posedge clk);
     while ( !($feof(fp_in)))  
     begin @ (negedge clk);
        status = $fscanf(fp_in,"%d\n",data_in[DATA_WIDTH-1:0]);
          data_vld_in = 1'b1;
      end
        $fclose(fp_in);
      repeat(1) @ (negedge clk);        
       data_vld_in = 0;
      
    end
    
    reg op_vld_r = 1'b0;
   always @(posedge clk)
      op_vld_r <= output_vld;
        
   always @(posedge clk) begin
       if (op_vld_r && ~output_vld) begin
           repeat (5) @(posedge clk);
          //$stop;
      end
         end    
    
  always 
     #100 clk <= ~clk;

endmodule
