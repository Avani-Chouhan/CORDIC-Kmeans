`timescale 1ns / 1ps


module k_means_top #( parameter INPUT_TYPE_PAR = 0,        
                      parameter DATA_WIDTH = 16,           
                      parameter N_SAMPLES = 1212,          
                      parameter DIM = 4,
                      parameter DATA_SCALE_FACTOR = 20,
                      parameter CORDIC_WIDTH = 22,         
                      parameter CORDIC_STAGES = 16,        
                      parameter ANGLE_WIDTH = 16,          
                      parameter MULT_LATENCY = 3 ,         
                      parameter NO_OF_PTS = 10,      
                      parameter NO_OF_CLUSTERS = 6,
                      parameter CORDIC_LATENCY = 18,  
                      parameter SIMULATION = "NO",        
                      parameter SYNTHESIS_TOOL = "VIVADO",
                      parameter DIM_WIDTH = clogb2(DIM-1),                      
                      parameter NO_OF_CLUSTERS_WIDTH = clogb2(NO_OF_CLUSTERS-1),
                      parameter NO_OF_PTS_WIDTH = clogb2(NO_OF_PTS-1)                     
                       
                     )
    (       
        input clk,
        input nreset,
        input signed [DATA_WIDTH-1:0] data_in,
        input data_vld_in,
        output output_vld,
        output [NO_OF_CLUSTERS_WIDTH-1:0] cluster_no_out
    );


    // The following function calculates 
    // the ceiling of log2 of an integer.
    //
    function integer clogb2;
        input integer depth;
            for (clogb2=0; depth>0; clogb2=clogb2+1)
                depth = depth >> 1; // Iteratively right-shifts depth by 1 bit until it becomes zero, 
                                    //incrementing clogb2 at each iteration. 
                                    //The final value of clogb2 represents the ceiling logarithm base 2 
                                    //of the original depth value. 
    endfunction
    
//    localparam DIM_WIDTH = clogb2(DIM-1),              // to represent (DIM-1) how many bits are 
                                                          //required = DIM_WIDTH
//               NO_OF_CLUSTERS_WIDTH = clogb2(NO_OF_CLUSTERS-1), // similarly.......
//               NO_OF_PTS_WIDTH = clogb2(NO_OF_PTS-1);              // similarly.......
    //-------------------------------------------------------------------------------------//
    // Data Memory 
    wire signed [DATA_WIDTH-1:0] data_mem_rdata;
    wire data_mem_rdata_vld;
    wire [NO_OF_PTS-1:0] data_mem_wren;
    wire [DIM_WIDTH-1:0] data_mem_wraddr;        
    wire signed [DATA_WIDTH-1:0] data_mem_wrdata;
    wire [NO_OF_PTS-1:0] data_mem_rden;
    wire [DIM_WIDTH-1:0] data_mem_rdaddr;    
    
    // Current Centroid memory          
    wire signed [DATA_WIDTH-1:0] centroid_rdata0;
    wire signed [DATA_WIDTH-1:0] centroid_rdata1;
    wire [1:0] centroid_rdata_vld;        
    wire [NO_OF_CLUSTERS-1:0] centroid_wren;
    wire [DIM_WIDTH-1:0] centroid_wraddr; 
    wire signed [DATA_WIDTH-1:0] centroid_wrdata;
    wire [NO_OF_CLUSTERS-1:0] centroid_rden;
    wire [DIM_WIDTH-1:0] centroid_rdaddr0;   
    wire [DIM_WIDTH-1:0] centroid_rdaddr1;        
    wire centroid_rdaddr1_vld;
    
    // Old Centroid memory          
    wire signed [DATA_WIDTH-1:0] centroid_old_rdata0;        
    wire signed [DATA_WIDTH-1:0] centroid_old_rdata1;            
    wire [NO_OF_CLUSTERS-1:0] centroid_old_wren;
    wire [DIM_WIDTH-1:0] centroid_old_wraddr; 
    wire signed [DATA_WIDTH-1:0] centroid_old_wrdata;
    wire [NO_OF_CLUSTERS-1:0] centroid_old_rden;
    
    // Temporary memory
    wire signed [DATA_WIDTH-1:0] temp_mem_rdata;
    wire temp_mem_rdata_vld;
    wire temp_mem_wren;
    wire [DIM_WIDTH-1:0] temp_mem_wraddr;    
    wire signed [DATA_WIDTH-1:0] temp_mem_wrdata;
    wire temp_mem_rden;
    wire [DIM_WIDTH-1:0] temp_mem_rdaddr;
    
    // Cluster Computation
    wire cluster_comp_opvld;    
    wire [NO_OF_CLUSTERS_WIDTH-1:0] cluster_comp_out;        
    wire cluster_comp_data_vld;
    wire signed [DATA_WIDTH-1:0] cluster_comp_data_in;
    
    // Centroid computation
    wire centroid_comp_opvld;
    wire signed [DATA_WIDTH-1:0] centroid_comp_out;
    wire centroid_comp_data_vld_in;
    wire signed [DATA_WIDTH-1:0] centroid_comp_data_in;
    wire [NO_OF_CLUSTERS_WIDTH-1:0] centroid_comp_cluster_no_in;
    
    // CORDIC Vectoring Mode
    wire cordic_vec_opvld;
    wire signed [DATA_WIDTH-1:0] cordic_vec_xout;
    wire cordic_vec_en;
    wire signed [DATA_WIDTH-1:0] cordic_vec_xin;
    wire signed [DATA_WIDTH-1:0] cordic_vec_yin;               
    
    //-------------------------------------------------------------------------------------------//
    
    k_means_control #(        // submodules...
        .DATA_WIDTH (DATA_WIDTH),
        .DIM (DIM),
        .NO_OF_PTS (NO_OF_PTS),
        .NO_OF_CLUSTERS (NO_OF_CLUSTERS),
        .CORDIC_LATENCY (CORDIC_LATENCY)
    ) k_means_Control_Unit (   
        .clk (clk),        // ip 1
        .nreset (nreset),  // ip 2
        .data_vld_in (data_vld_in), //ip 3
        .data_in (data_in), //ip 4
        .output_vld (output_vld), // op 5
        .cluster_no_out (cluster_no_out),  // op 6  
         
         // Data Memory    
        .data_mem_rdata (data_mem_rdata), // ip 7
        .data_mem_rdata_vld (data_mem_rdata_vld), // ip 8
        .data_mem_wren (data_mem_wren), //op 9
        .data_mem_wraddr (data_mem_wraddr), //op 10
        .data_mem_wrdata (data_mem_wrdata), //op 11
        .data_mem_rden (data_mem_rden), //op 12
        .data_mem_rdaddr (data_mem_rdaddr), //op 13 
        
        // Current Centroid memory 
        .centroid_rdata0_in (centroid_rdata0),  // ip 14
        .centroid_rdata1_in (centroid_rdata1), // ip 15
        .centroid_rdata_vld (centroid_rdata_vld), // ip 16
        .centroid_wren (centroid_wren), // op 17
        .centroid_wraddr (centroid_wraddr), // op 18
        .centroid_wrdata (centroid_wrdata), // op 19 
        .centroid_rden (centroid_rden),  //op 20
        .centroid_rdaddr0 (centroid_rdaddr0),    // op 21
        .centroid_rdaddr1 (centroid_rdaddr1),     // op 22   
        .centroid_rdaddr1_vld (centroid_rdaddr1_vld),  // op 23
        
        // Old Centroid memory 
        .centroid_old_rdata0_in (centroid_old_rdata0),   // ip 24     
        .centroid_old_rdata1_in (centroid_old_rdata1),    // ip 25      
        .centroid_old_wren (centroid_old_wren),         // op 26  
        .centroid_old_wraddr (centroid_old_wraddr),     // op 27  
        .centroid_old_wrdata (centroid_old_wrdata),      // op 28 
        .centroid_old_rden (centroid_old_rden),          // op 29 
        
        // Temporary memory 
        .temp_mem_rdata (temp_mem_rdata),          // ip 30
        .temp_mem_rdata_vld (temp_mem_rdata_vld),  // ip 31
        .temp_mem_wren (temp_mem_wren),            // op 32
        .temp_mem_wraddr (temp_mem_wraddr),        // op 33
        .temp_mem_wrdata (temp_mem_wrdata),        // op 34
        .temp_mem_rden (temp_mem_rden),            // op 35
        .temp_mem_rdaddr (temp_mem_rdaddr),        // op 36
        
        // Cluster Computation
        .cluster_comp_opvld (cluster_comp_opvld),  // ip 37 
        .cluster_comp_out (cluster_comp_out),      // ip 38   
        .cluster_comp_data_vld (cluster_comp_data_vld), // op 39
        .cluster_comp_data_in (cluster_comp_data_in),   // op 40
        
        // Centroid computation 
        .centroid_comp_opvld (centroid_comp_opvld),  // ip 41
        .centroid_comp_out (centroid_comp_out),      // ip 42
        .centroid_comp_data_vld_in (centroid_comp_data_vld_in),    // op 43
        .centroid_comp_data_in (centroid_comp_data_in),            // op 44
        .centroid_comp_cluster_no_in (centroid_comp_cluster_no_in),// op 45 
         
         // CORDIC Vectoring Mode  
        .cordic_vec_opvld (cordic_vec_opvld), // ip 46
        .cordic_vec_xout (cordic_vec_xout),   // ip 47
        .cordic_vec_en (cordic_vec_en),   // op 48
        .cordic_vec_xin (cordic_vec_xin), // op 49
        .cordic_vec_yin (cordic_vec_yin)  // op 50      
    );
    
    //submodule 1: 
    k_means_memory_top #(   
        .DATA_WIDTH (DATA_WIDTH),
        .DIM (DIM),
        .NO_OF_PTS (NO_OF_PTS),
        .NO_OF_CLUSTERS (NO_OF_CLUSTERS),
        .SYNTHESIS_TOOL (SYNTHESIS_TOOL),
        .SIMULATION (SIMULATION)
    ) k_Means_Memory_Wrapper (
        .clk (clk),         // ip 1
        .nreset (nreset),   // ip 2     
        .data_mem_wrdata_in (data_mem_wrdata),     // ip 51  (op 11)                                                                        
        .data_mem_wren_in (data_mem_wren),         // ip 52  (op 9)
        .data_mem_wraddr_in (data_mem_wraddr),     // ip 53  (op 10)      
        .data_mem_rden_in (data_mem_rden),         // ip 54  (op 12) 
        .data_mem_rdaddr_in (data_mem_rdaddr),     // ip 55  (op 13)
                                                             
        .temp_mem_wren_in (temp_mem_wren),         // ip 56   (op 32)
        .temp_mem_wrdata_in (temp_mem_wrdata),     // ip 57   (op 34) 
        .temp_mem_wraddr_in (temp_mem_wraddr),     // ip 58   (op 33)
        .temp_mem_rden_in (temp_mem_rden),         // ip 59   (op 35)
        .temp_mem_rdaddr_in (temp_mem_rdaddr),     // ip 60   (op 36)
        
        .centroid_mem_wren_in (centroid_wren),          // ip 61  (op 17)
        .centroid_mem_wrdata_in (centroid_wrdata),      // ip 62  (op 19)                                                                       
        .centroid_mem_wraddr_in (centroid_wraddr),      // ip 63  (op 18)     
        .centroid_mem_rden_in (centroid_rden),          // ip 64  (op 20)
        .centroid_rdaddr0_in (centroid_rdaddr0),        // ip 65  (op 21)   
        .centroid_rdaddr1_in (centroid_rdaddr1),        // ip 66  (op 22)  
        .centroid_rdaddr1_vld_in (centroid_rdaddr1_vld),// ip 67  (op 23)
        
        .centroid_old_mem_wren_in (centroid_old_wren),     // ip 68   (op 26)
        .centroid_old_mem_rden_in (centroid_old_rden),     // ip 69   (op 29) 
        .centroid_old_mem_wrdata_in (centroid_old_wrdata), // ip 70   (op 28)
        .centroid_old_mem_wraddr_in (centroid_old_wraddr), // ip 71   (op 27)
        
        .data_mem_rdata_o (data_mem_rdata),                 // op 72  (ip 7)
        .temp_mem_rdata_o (temp_mem_rdata),                 // op 73  (ip 30)
        .temp_mem_rdata_vld_o (temp_mem_rdata_vld),         // op 74  (ip 31)
        .data_mem_rdata_vld_o (data_mem_rdata_vld),         // op 75  (ip 8)
        .centroid_mem_rdata_vld_o (centroid_rdata_vld),     // op 76  (ip 16)
        .centroid_mem_rdata0_o (centroid_rdata0),           // op 77  (ip 14)
        .centroid_mem_rdata1_o (centroid_rdata1),           // op 78  (ip 15)
        .centroid_old_mem_rdata0_o (centroid_old_rdata0),   // op 79  (ip 24)
        .centroid_old_mem_rdata1_o (centroid_old_rdata1)    // op 80  (ip 25)                          
    );
    
     //submodule 2: 
    cluster_computation #(
        .DATA_WIDTH (DATA_WIDTH),
        .NO_OF_CLUSTERS (NO_OF_CLUSTERS),
        .NO_OF_CLUSTERS_WIDTH (NO_OF_CLUSTERS_WIDTH)
    ) Cluster_Computation_Unit(
        .clk (clk),         // ip 1
        .nreset (nreset),   // ip 2
        .data_vld_in (cluster_comp_data_vld), // ip 81 (op 39)
        .data_in (cluster_comp_data_in),      // ip 82 (op 40)
        .output_vld (cluster_comp_opvld),     // op 83 (ip 37)
        .cluster_no_out (cluster_comp_out)    // op 84 (ip 38)
    );
    
    //submodule 3:
    centroid_computation #(
        .DATA_WIDTH (DATA_WIDTH),
        .DIM_WIDTH (DIM_WIDTH),
        .NO_OF_CLUSTERS (NO_OF_CLUSTERS),
        .NO_OF_CLUSTERS_WIDTH (NO_OF_CLUSTERS_WIDTH),
        .NO_OF_PTS (NO_OF_PTS),
        .NO_OF_PTS_WIDTH (NO_OF_PTS_WIDTH)
    ) Centroid_Computation_Unit (    
        .clk (clk),         // ip 1
        .nreset (nreset),   // ip 2
        .data_vld_in (centroid_comp_data_vld_in),       // ip 85  
        .data_in (centroid_comp_data_in),               // ip 86  
        .cluster_no_in (centroid_comp_cluster_no_in),   // ip 87  
        .output_vld (centroid_comp_opvld),               // op 88 
        .centroid_out (centroid_comp_out)                // op 89 
    );
    
    //submodule 3:
    SCICA_CORDIC_wrapper #(
        .DATA_WIDTH (DATA_WIDTH),
        .CORDIC_WIDTH (CORDIC_WIDTH),
        .ANGLE_WIDTH (ANGLE_WIDTH),
        .CORDIC_STAGES (CORDIC_STAGES)
    ) CORDIC_top (
        .clk (clk),         // ip 1
        .nreset (nreset),   // ip 2
        .scica_stage_in (2'b11),                     // ip 90           // 00 - EVD, 01 - ICA, 10 - FFT, 11 - k-Means
         // EVD Vectoring wires                      
        .evd_cordic_vec_en (1'b0),                   // ip 91
        .evd_cordic_vec_xin ({DATA_WIDTH{1'b0}}),    // ip 92
        .evd_cordic_vec_yin ({DATA_WIDTH{1'b0}}),    // ip 93
        .evd_cordic_vec_angle_calc_en (1'b0),        // ip 94
        // EVD Rotation wires
        .evd_cordic_rot1_en(1'b0),                        // ip 95 
        .evd_cordic_rot1_xin ({DATA_WIDTH{1'b0}}),        // ip 96 
        .evd_cordic_rot1_yin ({DATA_WIDTH{1'b0}}),        // ip 97 
        .evd_cordic_rot1_angle_microRot_n(1'b0),          // ip 98 
        .evd_cordic_rot1_angle_in ({ANGLE_WIDTH{1'b0}}),  // ip 99 
        .evd_cordic_rot2_en(1'b0),                        // ip 100
        .evd_cordic_rot2_xin ({DATA_WIDTH{1'b0}}),        // ip 101
        .evd_cordic_rot2_yin ({DATA_WIDTH{1'b0}}),        // ip 102
        .evd_cordic_rot2_angle_microRot_n (1'b0),         // ip 103
        // ICA Vectoring wires
        .ica_cordic_vec_en (1'b0),                    // ip 104    
        .ica_cordic_vec_xin ({DATA_WIDTH{1'b0}}),     // ip 105
        .ica_cordic_vec_yin ({DATA_WIDTH{1'b0}}),     // ip 106
        .ica_cordic_vec_angle_calc_en (1'b0),         // ip 107       
        // ICA Rotation wires
        .ica_cordic_rot1_en (1'b0),                                 // ip 108
        .ica_cordic_rot1_xin ({DATA_WIDTH{1'b0}}),                  // ip 109
        .ica_cordic_rot1_yin ({DATA_WIDTH{1'b0}}),                  // ip 110
        .ica_cordic_rot1_angle_in ({ANGLE_WIDTH{1'b0}}),            // ip 111
        .ica_cordic_rot1_angle_microRot_n (1'b0),                   // ip 112
        .ica_cordic_rot1_microRot_ext_in ({CORDIC_STAGES{1'b0}}),   // ip 113            //External micro rotation wire for CORDIC-1 
                                                                                          //Rotation
        .ica_cordic_rot1_microRot_ext_vld (1'b0),                   // ip 114
        .ica_cordic_rot1_quad_in (2'b00),                           // ip 115
        .ica_cordic_rot2_en (1'b0),                                 // ip 116
        .ica_cordic_rot2_xin ({DATA_WIDTH{1'b0}}),                  // ip 117
        .ica_cordic_rot2_yin ({DATA_WIDTH{1'b0}}),                  // ip 118
        .ica_cordic_rot2_quad_in (2'b00),                           // ip 119
        .ica_cordic_rot2_microRot_in ({CORDIC_STAGES{1'b0}}),       // ip 110
        // FFT Rotation wires                                       
        .fft_cordic_rot_en (1'b0),                           // ip 111      
        .fft_cordic_rot_xin ({DATA_WIDTH{1'b0}}),            // ip 112
        .fft_cordic_rot_yin ({DATA_WIDTH{1'b0}}),            // ip 113
        .fft_cordic_rot_angle_in ({ANGLE_WIDTH{1'b0}}),      // ip 114      
        // K-Means Vectoring wires
        .kmeans_cordic_vec_en (cordic_vec_en),              // ip 115
        .kmeans_cordic_vec_xin (cordic_vec_xin),            // ip 116
        .kmeans_cordic_vec_yin (cordic_vec_yin),            // ip 117
        // CORDIC Vectoring wires
        .cordic_vec_opvld (cordic_vec_opvld),  // op 118
        .cordic_vec_xout (cordic_vec_xout),    // op 119
        .cordic_vec_microRot_out (),           // op 120
        .cordic_vec_quad_out (),               // op 121
        .cordic_vec_microRot_out_start (),     // op 122
        .cordic_vec_angle_out (),              // op 123
        //CORDIC Rotation wires
        .cordic_rot1_opvld (),              // op 124  
        .cordic_rot1_xout (),               // op 125
        .cordic_rot1_yout (),               // op 126
        .cordic_rot2_opvld (),              // op 127
        .cordic_rot2_xout (),               // op 128
        .cordic_rot2_yout ()                // op 129
    );
        
endmodule
