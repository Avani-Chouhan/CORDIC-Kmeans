`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.04.2017 14:31:38
// Design Name: 
// Module Name: k_means_memory_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Let N = no. of data points, DIM = Dimension of each point, and Nc = No. of clusters.
//                     This memory wrapper is designed specifically for SCICA, where D >> N. There are 4 types of memory:
// 1. Data Memory - N memory blocks of size (DIM X DATA_WIDTH) - used tos tore each data point.
// 2. Temporary memory - 1 block of size (DIM X DATA_WIDTH) - used to store intermediate CORDIC Vectoring outputs.
// 3. Centroid Memory - Nc blocks of size (DIM X DATA_WIDTH) - used to store current centroid values.
// 4. Old Centroid Memory - Nc blocks of size (DIM X DATA_WIDTH) - used to store centroid values from previous iteration.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module k_means_memory_top #(
        parameter DATA_WIDTH = 16,
        parameter DIM = 128,
        parameter NO_OF_PTS = 10,
        parameter NO_OF_CLUSTERS = 5,
        parameter SYNTHESIS_TOOL = "VIVADO",
        parameter SIMULATION = "NO",
        parameter DIM_WIDTH = clogb2(DIM-1),
        parameter NO_OF_CLUSTERS_WIDTH = clogb2(NO_OF_CLUSTERS-1),
        parameter NO_OF_PTS_WIDTH = clogb2(NO_OF_PTS-1),
           parameter RDEN_EVEN_WIDTH = NO_OF_CLUSTERS/2+NO_OF_CLUSTERS[0],
           parameter RDEN_ODD_WIDTH = NO_OF_CLUSTERS/2
    ) (
        input clk,
        input nreset,        
        
        input signed [DATA_WIDTH-1:0] data_mem_wrdata_in,                                                                               
        input [NO_OF_PTS-1:0] data_mem_wren_in,
        input [DIM_WIDTH-1:0] data_mem_wraddr_in,             
        input [NO_OF_PTS-1:0] data_mem_rden_in,
        input [DIM_WIDTH-1:0] data_mem_rdaddr_in,             

        input temp_mem_wren_in,         
        input signed [DATA_WIDTH-1:0] temp_mem_wrdata_in,
        input [DIM_WIDTH-1:0] temp_mem_wraddr_in,
        input temp_mem_rden_in,
        input [DIM_WIDTH-1:0] temp_mem_rdaddr_in,

        input [NO_OF_CLUSTERS-1:0] centroid_mem_wren_in,
        input signed [DATA_WIDTH-1:0] centroid_mem_wrdata_in,                                                                               
        input [DIM_WIDTH-1:0] centroid_mem_wraddr_in,             
        input [NO_OF_CLUSTERS-1:0] centroid_mem_rden_in,
        input [DIM_WIDTH-1:0] centroid_rdaddr0_in,             
        input [DIM_WIDTH-1:0] centroid_rdaddr1_in,             
        input centroid_rdaddr1_vld_in,
        
        input [NO_OF_CLUSTERS-1:0] centroid_old_mem_wren_in,         
        input [NO_OF_CLUSTERS-1:0] centroid_old_mem_rden_in,         
        input signed [DATA_WIDTH-1:0] centroid_old_mem_wrdata_in,
        input [DIM_WIDTH-1:0] centroid_old_mem_wraddr_in,
        
        output reg signed [DATA_WIDTH-1:0] data_mem_rdata_o,
        output reg signed [DATA_WIDTH-1:0] temp_mem_rdata_o,
        output reg data_mem_rdata_vld_o,        
        output reg temp_mem_rdata_vld_o,
        output reg [1:0] centroid_mem_rdata_vld_o,
        output reg signed [DATA_WIDTH-1:0] centroid_mem_rdata0_o,
        output reg signed [DATA_WIDTH-1:0] centroid_mem_rdata1_o,
        output reg signed [DATA_WIDTH-1:0] centroid_old_mem_rdata0_o,
        output reg signed [DATA_WIDTH-1:0] centroid_old_mem_rdata1_o                        
    );                        

    // Data memory inputs
    reg [NO_OF_PTS-1:0] wean;
    reg signed [DATA_WIDTH-1:0] data_mem_wrdata;
    reg [DIM_WIDTH-1:0] data_mem_wraddr;
    reg [NO_OF_PTS-1:0] oeb;
    reg [DIM_WIDTH-1:0] data_mem_rdaddr;
    
    // Temporary memory inputs      
    reg [DIM_WIDTH-1:0] temp_mem_wraddr;
    reg temp_mem_wean;
    reg signed [DATA_WIDTH-1:0] temp_mem_wrdata;
    reg temp_mem_oeb;
    reg [DIM_WIDTH-1:0] temp_mem_rdaddr;
    
    // Current Centroid memory inputs
    reg [DIM_WIDTH-1:0] centroid_mem_wraddr;
    reg [NO_OF_CLUSTERS-1:0] centroid_mem_wean;
    reg signed [DATA_WIDTH-1:0] centroid_mem_wrdata;
    reg [NO_OF_CLUSTERS-1:0] centroid_mem_oeb;
    reg [DIM_WIDTH-1:0] centroid_mem_rdaddr_odd;
    reg [DIM_WIDTH-1:0] centroid_mem_rdaddr_even;
    wire [RDEN_EVEN_WIDTH-1:0] centroid_rden_even;
    wire [RDEN_ODD_WIDTH-1:0] centroid_rden_odd;

    // Old Centroid memory inputs
    reg [DIM_WIDTH-1:0] centroid_old_mem_wraddr;
    reg [NO_OF_CLUSTERS-1:0] centroid_old_mem_wean;
    reg signed [DATA_WIDTH-1:0] centroid_old_mem_wrdata;
    reg [NO_OF_CLUSTERS-1:0] centroid_old_mem_oeb;

    // Read data from all the memories
    wire [DATA_WIDTH-1:0] data_mem_rddata [NO_OF_PTS-1:0];
    wire [DATA_WIDTH-1:0] temp_mem_rddata;
    wire [DATA_WIDTH-1:0] centroid_mem_rddata [NO_OF_CLUSTERS-1:0];
    wire [DATA_WIDTH-1:0] centroid_old_mem_rddata [NO_OF_CLUSTERS-1:0];
    
    // Other signals
    // The following function calculates 
    // the ceiling of log2 of an integer.
    function integer clogb2;
        input integer depth;
            for (clogb2=0; depth>0; clogb2=clogb2+1)
                depth = depth >> 1;
    endfunction

   // localparam DIM_WIDTH = clogb2(DIM-1),
                      //NO_OF_CLUSTERS_WIDTH = clogb2(NO_OF_CLUSTERS-1),
                      //NO_OF_PTS_WIDTH = clogb2(NO_OF_PTS-1),
                      //RDEN_EVEN_WIDTH = NO_OF_CLUSTERS/2+NO_OF_CLUSTERS[0],
                      //RDEN_ODD_WIDTH = NO_OF_CLUSTERS/2;
         
    reg [RDEN_EVEN_WIDTH-1:0] centroid_rden_even_r;
    reg [RDEN_ODD_WIDTH-1:0] centroid_rden_odd_r;

    wire [NO_OF_PTS_WIDTH-1:0] data_mem_rden_enc;
    wire [$clog2(NO_OF_CLUSTERS/2+NO_OF_CLUSTERS[0])-1:0] centroid_rden_even_enc;
    wire [$clog2(NO_OF_CLUSTERS/2)-1:0] centroid_rden_odd_enc;
    wire signed [DATA_WIDTH-1:0] centroid_rddata_even [RDEN_EVEN_WIDTH-1:0];
    wire signed [DATA_WIDTH-1:0] centroid_rdata_odd [RDEN_ODD_WIDTH-1:0];
    wire signed [DATA_WIDTH-1:0] centroid_old_rddata_even [RDEN_EVEN_WIDTH-1:0];
    wire signed [DATA_WIDTH-1:0] centroid_old_rdata_odd [RDEN_ODD_WIDTH-1:0];
     
    //------------------------------------------------------------------------------------//
    
    ///////////////////////////////////////////////////////////////////////////////////////
    //-----------------------------Data Memory---------------------------------//
    ///////////////////////////////////////////////////////////////////////////////////////

    // Separate Data memories are instantiated, but the output sent 
    // is only one dpeending on which memory was read. Since only 
    // one memory will be erad at a time, this will be acceptable.
    
    always @(negedge clk or negedge nreset) begin
        if (~nreset) begin
            wean <= {NO_OF_PTS{1'b1}};
            data_mem_wrdata <= {DATA_WIDTH{1'b0}};
            data_mem_wraddr <= {DIM_WIDTH{1'b0}};
            data_mem_rdaddr <= {DIM_WIDTH{1'b0}};
        end

        else begin
            wean <= ~data_mem_wren_in;
            data_mem_wrdata <= data_mem_wrdata_in;        
            data_mem_wraddr <= data_mem_wraddr_in;
            data_mem_rdaddr <= data_mem_rdaddr_in;
        end
    end

    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            oeb <= {NO_OF_PTS{1'b0}};
        else 
            oeb <= data_mem_rden_in;
    end
                            
    // Instantiate the separate data memory units    
    genvar i;
    
    generate 
        if ((SIMULATION == "NO") && (SYNTHESIS_TOOL == "VIVADO")) begin: gen_Vivado_syn            
            for (i=0;i<NO_OF_PTS;i=i+1) begin: gen_data_mem
                RAM_SDP #(
                    .RAM_WIDTH (DATA_WIDTH),                    // Specify RAM data width
                    .RAM_DEPTH (2**DIM_WIDTH),                  // Specify RAM depth (number of entries)
                    .RAM_TYPE ("LOW_LATENCY")
                ) Data_Mem (  
                    .addra (data_mem_wraddr_in),                           // Write address bus, width determined from RAM_DEPTH
                    .addrb (data_mem_rdaddr_in),                        // Read address bus, width determined from RAM_DEPTH
                    .dina (data_mem_wrdata_in),               // RAM input data
                    .clk (clk),                                 // Clock
                    .wea (data_mem_wren_in[i]),                               // Write enable
                    .enb (data_mem_rden_in[i]),                              // Read Enable, for additional power savings, disable when not in use
                    .rst (~nreset),                             // Output reset (does not affect memory contents)
                    .regceb (1'b0),                             // Output register enable
                    .doutb (data_mem_rddata[i])   // RAM output data
                );
            end
        end

//        else begin: gen_faraday_memory
//            for (i=0;i<NO_OF_PTS-1;i=i+1) begin: genblk_faraday_memory
////                SJ180_128X16X1CM4 Data_Mem (
////                    .A0(data_mem_wraddr[0]), .A1(data_mem_wraddr[1]), .A2(data_mem_wraddr[2]), .A3(data_mem_wraddr[3]), 
////                    .A4(data_mem_wraddr[4]), .A5(data_mem_wraddr[5]), .A6(data_mem_wraddr[6]), 
////                    .B0(data_mem_rdaddr[0]), .B1(data_mem_rdaddr[1]), .B2(data_mem_rdaddr[2]), .B3(data_mem_rdaddr[3]), 
////                    .B4(data_mem_rdaddr[4]), .B5(data_mem_rdaddr[5]),.B6(data_mem_rdaddr[6]),
////                    .DIA0(data_mem_wrdata[0]), .DIA1(data_mem_wrdata[1]), .DIA2(data_mem_wrdata[2]), 
////                    .DIA3(data_mem_wrdata[3]), .DIA4(data_mem_wrdata[4]), .DIA5(data_mem_wrdata[5]), 
////                    .DIA6(data_mem_wrdata[6]), .DIA7(data_mem_wrdata[7]), .DIA8(data_mem_wrdata[8]),
////                    .DIA9(data_mem_wrdata[9]), .DIA10(data_mem_wrdata[10]), .DIA11(data_mem_wrdata[11]),
////                    .DIA12(data_mem_wrdata[12]), .DIA13(data_mem_wrdata[13]),.DIA14(data_mem_wrdata[14]),
////                    .DIA15(data_mem_wrdata[15]), .DOB0(data_mem_rddata[DATA_WIDTH*i]), .DOB1(data_mem_rddata[i][1]),
////                    .DOB2(data_mem_rddata[i][2]), .DOB3(data_mem_rddata[i][3]), .DOB4(data_mem_rddata[i][4]),
////                    .DOB5(data_mem_rddata[i][5]), .DOB6(data_mem_rddata[i][6]), .DOB7(data_mem_rddata[i][7]),
////                    .DOB8(data_mem_rddata[i][8]), .DOB9(data_mem_rddata[i][9]), .DOB10(data_mem_rddata[i][10]), 
////                    .DOB11(data_mem_rddata[i][11]), .DOB12(data_mem_rddata[i][12]), .DOB13(data_mem_rddata[i][13]),
////                    .DOB14(data_mem_rddata[i][14]), .DOB15(data_mem_rddata[i][15]), .DOA0(), .DOA1(), .DOA2(), .DOA3(),
////                    .DOA4(), .DOA5(), .DOA6(), .DOA7(), .DOA8(), .DOA9(), .DOA10(), .DOA11(), .DOA12(), .DOA13(), .DOA14(), .DOA15(), 
////                    .DIB0(1'b0), .DIB1(1'b0), .DIB2(1'b0), .DIB3(1'b0), .DIB4(1'b0), .DIB5(1'b0), .DIB6(1'b0), .DIB7(1'b0), .DIB8(1'b0),
////                    .DIB9(1'b0), .DIB10(1'b0), .DIB11(1'b0), .DIB12(1'b0), .DIB13(1'b0), .DIB14(1'b0), .DIB15(1'b0), .WEAN(wean[i]), .WEBN(1'b1),
////                    .CKA(clk), .CKB(clk), .CSA(1'b1), .CSB(1'b1), .OEA(1'b0), .OEB(oeb[i])
////                );
//
//                SJ180_128X32X1CM4 Data_Mem (
//                    .A0(data_mem_wraddr[0]), .A1(data_mem_wraddr[1]), .A2(data_mem_wraddr[2]), .A3(data_mem_wraddr[3]), 
//                    .A4(data_mem_wraddr[4]), .A5(data_mem_wraddr[5]), .A6(data_mem_wraddr[6]), 
//                    .B0(data_mem_rdaddr[0]), .B1(data_mem_rdaddr[1]), .B2(data_mem_rdaddr[2]), .B3(data_mem_rdaddr[3]), 
//                    .B4(data_mem_rdaddr[4]), .B5(data_mem_rdaddr[5]), .B6(data_mem_rdaddr[6]),
                    
//                    .DIA0(data_mem_wrdata[0]), .DIA1(data_mem_wrdata[1]), .DIA2(data_mem_wrdata[2]), 
//                    .DIA3(data_mem_wrdata[3]), .DIA4(data_mem_wrdata[4]), .DIA5(data_mem_wrdata[5]), 
//                    .DIA6(data_mem_wrdata[6]), .DIA7(data_mem_wrdata[7]), .DIA8(data_mem_wrdata[8]),
//                    .DIA9(data_mem_wrdata[9]), .DIA10(data_mem_wrdata[10]), .DIA11(data_mem_wrdata[11]),
//                    .DIA12(data_mem_wrdata[12]), .DIA13(data_mem_wrdata[13]),.DIA14(data_mem_wrdata[14]),
//                    .DIA15(data_mem_wrdata[15]), .DIA16(data_mem_wrdata[16]), .DIA17(data_mem_wrdata[17]), 
//                    .DIA18(data_mem_wrdata[18]), .DIA19(data_mem_wrdata[19]), .DIA20(data_mem_wrdata[20]), 
//                    .DIA21(data_mem_wrdata[21]), .DIA22(data_mem_wrdata[22]), .DIA23(data_mem_wrdata[23]),
//                    .DIA24(data_mem_wrdata[24]), .DIA25(data_mem_wrdata[25]), .DIA26(data_mem_wrdata[26]),
//                    .DIA27(data_mem_wrdata[27]), .DIA28(data_mem_wrdata[28]), .DIA29(data_mem_wrdata[29]), 
//                    .DIA30(data_mem_wrdata[30]), .DIA31(data_mem_wrdata[31]), 
                
//                    .DOB0(data_mem_rddata[i][0]), .DOB1(data_mem_rddata[i][1]),
//                    .DOB2(data_mem_rddata[i][2]), .DOB3(data_mem_rddata[i][3]), .DOB4(data_mem_rddata[i][4]),
//                    .DOB5(data_mem_rddata[i][5]), .DOB6(data_mem_rddata[i][6]), .DOB7(data_mem_rddata[i][7]),
//                    .DOB8(data_mem_rddata[i][8]), .DOB9(data_mem_rddata[i][9]), .DOB10(data_mem_rddata[i][10]), 
//                    .DOB11(data_mem_rddata[i][11]), .DOB12(data_mem_rddata[i][12]), .DOB13(data_mem_rddata[i][13]),
//                    .DOB14(data_mem_rddata[i][14]), .DOB15(data_mem_rddata[i][15]), .DOB16(data_mem_rddata[i][16]), 
//                    .DOB17(data_mem_rddata[i][17]), .DOB18(data_mem_rddata[i][18]), .DOB19(data_mem_rddata[i][19]), 
//                    .DOB20(data_mem_rddata[i][20]), .DOB21(data_mem_rddata[i][21]), .DOB22(data_mem_rddata[i][22]), 
//                    .DOB23(data_mem_rddata[i][23]), .DOB24(data_mem_rddata[i][24]), .DOB25(data_mem_rddata[i][25]),
//                    .DOB26(data_mem_rddata[i][26]), .DOB27(data_mem_rddata[i][27]), .DOB28(data_mem_rddata[i][28]), 
//                    .DOB29(data_mem_rddata[i][29]), .DOB30(data_mem_rddata[i][30]), .DOB31(data_mem_rddata[i][31]),
            
//                    .DOA0(), .DOA1(), .DOA2(), .DOA3(), .DOA4(), .DOA5(), .DOA6(), .DOA7(), 
//                    .DOA8(), .DOA9(), .DOA10(), .DOA11(), .DOA12(), .DOA13(), .DOA14(), .DOA15(), 
//                    .DOA16(),.DOA17(),.DOA18(),.DOA19(), .DOA20(),.DOA21(),.DOA22(),.DOA23(),
//                    .DOA24(), .DOA25(),.DOA26(),.DOA27(), .DOA28(),.DOA29(),.DOA30(),.DOA31(),
                
//                    .DIB0(1'b0), .DIB1(1'b0), .DIB2(1'b0), .DIB3(1'b0), .DIB4(1'b0), .DIB5(1'b0), .DIB6(1'b0), .DIB7(1'b0), .DIB8(1'b0), 
//                    .DIB9(1'b0), .DIB10(1'b0), .DIB11(1'b0), .DIB12(1'b0), .DIB13(1'b0), .DIB14(1'b0), .DIB15(1'b0), .DIB16(1'b0), .DIB17(1'b0), 
//                    .DIB18(1'b0), .DIB19(1'b0), .DIB20(1'b0), .DIB21(1'b0), .DIB22(1'b0), .DIB23(1'b0), .DIB24(1'b0), .DIB25(1'b0), .DIB26(1'b0),
//                    .DIB27(1'b0), .DIB28(1'b0),.DIB29(1'b0),.DIB30(1'b0),.DIB31(1'b0),
//                    .WEAN(wean[i]), .WEBN(1'b1), .CKA(clk), .CKB(clk), .CSA(1'b1), .CSB(1'b1), .OEA(1'b0), .OEB(oeb[i])
//                );
//            end            
//        end
    endgenerate

    //-------------------------------------------------------------------------------//    
    // The following encoder is just to encode the data_mem_rden which is 
    // in one-hot format. This encoded value is used to select the rdata output.
    encoder #(
        .INPUT_WIDTH (NO_OF_PTS)
    ) data_mem_rden_encode (
//        .clk (clk),
//        .nreset (nreset),
        .enc_in (oeb),
        .enc_out (data_mem_rden_enc)
    );
    
    // Data and Temporary Memory Outputs
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin        
            data_mem_rdata_vld_o <= 1'b0;
            data_mem_rdata_o <= {DATA_WIDTH{1'b0}};
        end
        
        else begin
            data_mem_rdata_vld_o <= |oeb;
            
            if (|oeb)
                data_mem_rdata_o <= data_mem_rddata[data_mem_rden_enc];        
        end
    end
    
    //---------------------------------------------------------------------------------------//
    
    ///////////////////////////////////////////////////////////////////////////////////////
    //-------------------------Temporary Memory-----------------------------//
    ///////////////////////////////////////////////////////////////////////////////////////
    
    always @(negedge clk or negedge nreset) begin
        if (~nreset) begin
            temp_mem_wean <= 1'b1;
            temp_mem_wraddr <= {DIM_WIDTH{1'b0}};
            temp_mem_wrdata <= {DATA_WIDTH{1'b0}};
            temp_mem_rdaddr <= {DIM_WIDTH{1'b0}};
        end

        else begin
            temp_mem_wean <= ~temp_mem_wren_in;
            temp_mem_wraddr <= temp_mem_wraddr_in;
            temp_mem_wrdata <= temp_mem_wrdata_in;
            temp_mem_rdaddr <= temp_mem_rdaddr_in;
        end
    end

    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            temp_mem_oeb <= 1'b0;
        else
            temp_mem_oeb <= temp_mem_rden_in;
    end

    // Instantiate the Temporary Memory    
    generate 
        if ((SIMULATION == "NO") && (SYNTHESIS_TOOL == "VIVADO")) begin: gen_Vivado_syn_temp_mem            
            RAM_SDP #(
                .RAM_WIDTH (DATA_WIDTH),                   // Specify RAM data width
                .RAM_DEPTH (2**DIM_WIDTH),                 // Specify RAM depth (number of entries)
                .RAM_TYPE ("LOW_LATENCY")
            ) Temporary_Mem(  
                .addra (temp_mem_wraddr_in),                          // Write address bus, width determined from RAM_DEPTH
                .addrb (temp_mem_rdaddr_in),                       // Read address bus, width determined from RAM_DEPTH
                .dina (temp_mem_wrdata_in),                 // RAM input data
                .clk (clk),                                // Clock
                .wea (temp_mem_wren_in),                     // Write enable
                .enb (temp_mem_rden_in),                       // Read Enable, for additional power savings, disable when not in use
                .rst (~nreset),                            // Output reset (does not affect memory contents)
                .regceb (1'b0),                            // Output register enable
                .doutb (temp_mem_rddata)                 // RAM output data
            );
        end
        
//        else begin: gen_temp_mem_faraday
////            SJ180_128X16X1CM4 Temporary_Mem (
////                .A0(temp_mem_wraddr[0]), .A1(temp_mem_wraddr[1]), .A2(temp_mem_wraddr[2]), .A3(temp_mem_wraddr[3]), 
////                .A4(temp_mem_wraddr[4]), .A5(temp_mem_wraddr[5]), .A6(temp_mem_wraddr[6]),  
////                .B0(temp_mem_rdaddr_r[0]), .B1(temp_mem_rdaddr_r[1]), .B2(temp_mem_rdaddr_r[2]), .B3(temp_mem_rdaddr_r[3]), 
////                .B4(temp_mem_rdaddr_r[4]), .B5(temp_mem_rdaddr_r[5]), .B6(temp_mem_rdaddr_r[6]),
////                .DIA0(temp_mem_wrdata[0]), .DIA1(temp_mem_wrdata[1]), .DIA2(temp_mem_wrdata[2]), 
////                .DIA3(temp_mem_wrdata[3]), .DIA4(temp_mem_wrdata[4]), .DIA5(temp_mem_wrdata[5]), 
////                .DIA6(temp_mem_wrdata[6]), .DIA7(temp_mem_wrdata[7]), .DIA8(temp_mem_wrdata[8]),
////                .DIA9(temp_mem_wrdata[9]), .DIA10(temp_mem_wrdata[10]), .DIA11(temp_mem_wrdata[11]),
////                .DIA12(temp_mem_wrdata[12]), .DIA13(temp_mem_wrdata[13]),.DIA14(temp_mem_wrdata[14]),
////                .DIA15(temp_mem_wrdata[15]), .DOB0(temp_mem_rddata[0]), .DOB1(temp_mem_rddata[1]),
////                .DOB2(temp_mem_rddata[2]), .DOB3(temp_mem_rddata[3]), .DOB4(temp_mem_rddata[4]),
////                .DOB5(temp_mem_rddata[5]), .DOB6(temp_mem_rddata[6]), .DOB7(temp_mem_rddata[7]),
////                .DOB8(temp_mem_rddata[8]), .DOB9(temp_mem_rddata[9]), .DOB10(temp_mem_rddata[10]), 
////                .DOB11(temp_mem_rddata[11]), .DOB12(temp_mem_rddata[12]), .DOB13(temp_mem_rddata[13]),
////                .DOB14(temp_mem_rddata[14]), .DOB15(temp_mem_rddata[15]), .DOA0(), .DOA1(), .DOA2(), .DOA3(),
////                .DOA4(), .DOA5(), .DOA6(), .DOA7(), .DOA8(), .DOA9(), .DOA10(), .DOA11(), .DOA12(), .DOA13(), .DOA14(), .DOA15(), 
////                .DIB0(1'b0), .DIB1(1'b0), .DIB2(1'b0), .DIB3(1'b0), .DIB4(1'b0), .DIB5(1'b0), .DIB6(1'b0), .DIB7(1'b0), .DIB8(1'b0),
////                .DIB9(1'b0), .DIB10(1'b0), .DIB11(1'b0), .DIB12(1'b0), .DIB13(1'b0), .DIB14(1'b0), .DIB15(1'b0), .WEAN(temp_mem_wean), .WEBN(1'b1),
////                .CKA(clk), .CKB(clk), .CSA(1'b1), .CSB(1'b1), .OEA(1'b0), .OEB(temp_mem_oeb)
////            );
//
//            SJ180_1024X32X1CM4 Temporary_Mem (
//                .A0(temp_mem_wraddr[0]), .A1(temp_mem_wraddr[1]), .A2(temp_mem_wraddr[2]), .A3(temp_mem_wraddr[3]), 
//                .A4(temp_mem_wraddr[4]), .A5(temp_mem_wraddr[5]), .A6(temp_mem_wraddr[6]), 
//                .B0(temp_mem_rdaddr[0]), .B1(temp_mem_rdaddr[1]), .B2(temp_mem_rdaddr[2]), .B3(temp_mem_rdaddr[3]), 
//                .B4(temp_mem_rdaddr[4]), .B5(temp_mem_rdaddr[5]), .B6(temp_mem_rdaddr[6]), 
                    
//                .DIA0(temp_mem_wrdata[0]), .DIA1(temp_mem_wrdata[1]), .DIA2(temp_mem_wrdata[2]), 
//                .DIA3(temp_mem_wrdata[3]), .DIA4(temp_mem_wrdata[4]), .DIA5(temp_mem_wrdata[5]), 
//                .DIA6(temp_mem_wrdata[6]), .DIA7(temp_mem_wrdata[7]), .DIA8(temp_mem_wrdata[8]),
//                .DIA9(temp_mem_wrdata[9]), .DIA10(temp_mem_wrdata[10]), .DIA11(temp_mem_wrdata[11]),
//                .DIA12(temp_mem_wrdata[12]), .DIA13(temp_mem_wrdata[13]),.DIA14(temp_mem_wrdata[14]),
//                .DIA15(temp_mem_wrdata[15]), .DIA16(temp_mem_wrdata[16]), .DIA17(temp_mem_wrdata[17]),
//                .DIA18(temp_mem_wrdata[18]), .DIA19(temp_mem_wrdata[19]), .DIA20(temp_mem_wrdata[20]), 
//                .DIA21(temp_mem_wrdata[21]), .DIA22(temp_mem_wrdata[22]), .DIA23(temp_mem_wrdata[23]),
//                .DIA24(temp_mem_wrdata[24]), .DIA25(temp_mem_wrdata[25]), .DIA26(temp_mem_wrdata[26]),
//                .DIA27(temp_mem_wrdata[27]), .DIA28(temp_mem_wrdata[28]), .DIA29(temp_mem_wrdata[29]), 
//                .DIA30(temp_mem_wrdata[30]), .DIA31(temp_mem_wrdata[31]), 
                    
//                .DOB0(temp_mem_rddata[0]), .DOB1(temp_mem_rddata[1]),
//                .DOB2(temp_mem_rddata[2]), .DOB3(temp_mem_rddata[3]), .DOB4(temp_mem_rddata[4]),
//                .DOB5(temp_mem_rddata[5]), .DOB6(temp_mem_rddata[6]), .DOB7(temp_mem_rddata[7]),
//                .DOB8(temp_mem_rddata[8]), .DOB9(temp_mem_rddata[9]), .DOB10(temp_mem_rddata[10]), 
//                .DOB11(temp_mem_rddata[11]), .DOB12(temp_mem_rddata[12]), .DOB13(temp_mem_rddata[13]),
//                .DOB14(temp_mem_rddata[14]), .DOB15(temp_mem_rddata[15]), .DOB16(temp_mem_rddata[16]), 
//                .DOB17(temp_mem_rddata[17]), .DOB18(temp_mem_rddata[18]), .DOB19(temp_mem_rddata[19]), 
//                .DOB20(temp_mem_rddata[20]), .DOB21(temp_mem_rddata[21]), .DOB22(temp_mem_rddata[22]), 
//                .DOB23(temp_mem_rddata[23]), .DOB24(temp_mem_rddata[24]), .DOB25(temp_mem_rddata[25]),
//                .DOB26(temp_mem_rddata[26]), .DOB27(temp_mem_rddata[27]), .DOB28(temp_mem_rddata[28]), 
//                .DOB29(temp_mem_rddata[29]), .DOB30(temp_mem_rddata[30]), .DOB31(temp_mem_rddata[31]),
                
//                .DOA0(), .DOA1(), .DOA2(), .DOA3(), .DOA4(), .DOA5(), .DOA6(), .DOA7(),  
//                .DOA8(), .DOA9(), .DOA10(), .DOA11(), .DOA12(), .DOA13(), .DOA14(), .DOA15(), 
//                .DOA16(),.DOA17(),.DOA18(),.DOA19(), .DOA20(),.DOA21(),.DOA22(),.DOA23(),
//                .DOA24(),.DOA25(),.DOA26(),.DOA27(), .DOA28(),.DOA29(),.DOA30(),.DOA31(),
                                                    
//                .DIB0(1'b0), .DIB1(1'b0), .DIB2(1'b0), .DIB3(1'b0), .DIB4(1'b0), .DIB5(1'b0), .DIB6(1'b0), .DIB7(1'b0), .DIB8(1'b0),
//                .DIB9(1'b0), .DIB10(1'b0), .DIB11(1'b0), .DIB12(1'b0), .DIB13(1'b0), .DIB14(1'b0), .DIB15(1'b0), .DIB16(1'b0), 
//                .DIB18(1'b0), .DIB19(1'b0), .DIB20(1'b0), .DIB21(1'b0), .DIB22(1'b0), .DIB23(1'b0), .DIB24(1'b0), 
//                .DIB25(1'b0), .DIB26(1'b0), .DIB27(1'b0), .DIB28(1'b0),.DIB29(1'b0),.DIB30(1'b0),.DIB31(1'b0),
            
//                .WEAN(temp_mem_wean), .WEBN(1'b1), .CKA(clk), .CKB(clk), .CSA(1'b1), .CSB(1'b1), .OEA(1'b0), .OEB(temp_mem_oeb)
//            );
    endgenerate

    // Temporary Memory Outputs
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            temp_mem_rdata_vld_o <= 1'b0;
            temp_mem_rdata_o <= {DATA_WIDTH{1'b0}};
        end
        
        else begin
            temp_mem_rdata_vld_o <= temp_mem_oeb;
            
            if (temp_mem_oeb) 
                temp_mem_rdata_o <= temp_mem_rddata;
        end
    end
    
    //------------------------------------------------------------------------------------//
    
    ///////////////////////////////////////////////////////////////////////////////////////
    //--------------------------Centroid Memory-------------------------------//
    ///////////////////////////////////////////////////////////////////////////////////////
    
    // There are two read addresses - one for odd memory index blocks, 
    // another for the even ones. This is because during level 0 of memory
    // read, two memoriues are read simultaneously. Therefore, there are
    // two outputs - one multiplexing all the odd numbered outputs and 
    // the other multiplexing all the even numbered outputs

    always @(negedge clk or negedge nreset) begin
        if (~nreset) begin
            centroid_mem_wean <= {NO_OF_CLUSTERS{1'b1}};
            centroid_mem_wraddr <= {DIM_WIDTH{1'b0}};
            centroid_mem_wrdata <= {DATA_WIDTH{1'b0}};
            centroid_mem_rdaddr_odd <= {DIM_WIDTH{1'b0}};
            centroid_mem_rdaddr_even <= {DIM_WIDTH{1'b0}};
        end

        else begin
            centroid_mem_wean <= ~centroid_mem_wren_in;
            centroid_mem_wraddr <= centroid_mem_wraddr_in;
            centroid_mem_wrdata <= centroid_mem_wrdata_in;
            centroid_mem_rdaddr_odd <= centroid_rdaddr1_vld_in ? 
                                centroid_rdaddr1_in : centroid_rdaddr0_in;                        
            centroid_mem_rdaddr_even <= centroid_rdaddr0_in;                      
        end
    end

    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            centroid_mem_oeb <= {NO_OF_CLUSTERS{1'b0}};
        else
            centroid_mem_oeb <= centroid_mem_rden_in;
    end
    
    // Instantiate the Centroid memory units    
    generate 
        if ((SIMULATION == "NO") && (SYNTHESIS_TOOL == "VIVADO")) begin: gen_Vivado_syn_centr            
            for (i=0;i<NO_OF_CLUSTERS;i=i+1) begin: gen_centroid_mem
                if (i[0]) begin: centroid_odd
                    RAM_SDP #(
                        .RAM_WIDTH (DATA_WIDTH),                    // Specify RAM data width
                        .RAM_DEPTH (2**DIM_WIDTH),                  // Specify RAM depth (number of entries)
                        .RAM_TYPE ("LOW_LATENCY")
                    ) Centroid_Mem_odd (  
                        .addra (centroid_mem_wraddr_in),                           // Write address bus, width determined from RAM_DEPTH
                        .addrb (centroid_rdaddr1_vld_in ? 
                                    centroid_rdaddr1_in : centroid_rdaddr0_in),                        // Read address bus, width determined from RAM_DEPTH
                        .dina (centroid_mem_wrdata_in),               // RAM input data
                        .clk (clk),                                 // Clock
                        .wea (centroid_mem_wren_in[i]),                               // Write enable
                        .enb (centroid_mem_rden_in[i]),                              // Read Enable, for additional power savings, disable when not in use
                        .rst (~nreset),                             // Output reset (does not affect memory contents)
                        .regceb (1'b0),                             // Output register enable
                        .doutb (centroid_mem_rddata[i])   // RAM output data
                    );
                end
                
                else begin: centroid_even
                    RAM_SDP #(
                        .RAM_WIDTH (DATA_WIDTH),                    // Specify RAM data width
                        .RAM_DEPTH (2**DIM_WIDTH),                  // Specify RAM depth (number of entries)
                        .RAM_TYPE ("LOW_LATENCY")
                    ) Centroid_Mem_even (  
                        .addra (centroid_mem_wraddr_in),                           // Write address bus, width determined from RAM_DEPTH
                        .addrb (centroid_rdaddr0_in),                        // Read address bus, width determined from RAM_DEPTH
                        .dina (centroid_mem_wrdata_in),               // RAM input data
                        .clk (clk),                                 // Clock
                        .wea (centroid_mem_wren_in[i]),                               // Write enable
                        .enb (centroid_mem_rden_in[i]),                              // Read Enable, for additional power savings, disable when not in use
                        .rst (~nreset),                             // Output reset (does not affect memory contents)
                        .regceb (1'b0),                             // Output register enable
                        .doutb (centroid_mem_rddata[i])   // RAM output data
                    );
                end            
            end
        end            

//        else begin: gen_centroid_memory
//            for (i=0;i<NO_OF_CLUSTERS;i=i+1) begin: genblk_centroid_memory
////                if (i[0]) begin: centroid_odd
////                      SJ180_128X16X1CM4 Centroid_mem_odd (
////                        .A0(centroid_mem_wraddr[0]), .A1(centroid_mem_wraddr[1]), .A2(centroid_mem_wraddr[2]), .A3(centroid_mem_wraddr[3]), 
////                        .A4(centroid_mem_wraddr[4]), .A5(centroid_mem_wraddr[5]), .A6(centroid_mem_wraddr[6]), 
////                        .B0(centroid_mem_rdaddr_odd[0]), .B1(centroid_mem_rdaddr_odd[1]), .B2(centroid_mem_rdaddr_odd[2]), .B3(centroid_mem_rdaddr_odd[3]), 
////                        .B4(centroid_mem_rdaddr_odd[4]), .B5(centroid_mem_rdaddr_odd[5]),.B6(centroid_mem_rdaddr_odd[6]),
////                        .DIA0(centroid_mem_wrdata[0]), .DIA1(centroid_mem_wrdata[1]), .DIA2(centroid_mem_wrdata[2]), 
////                        .DIA3(centroid_mem_wrdata[3]), .DIA4(centroid_mem_wrdata[4]), .DIA5(centroid_mem_wrdata[5]), 
////                        .DIA6(centroid_mem_wrdata[6]), .DIA7(centroid_mem_wrdata[7]), .DIA8(centroid_mem_wrdata[8]),
////                        .DIA9(centroid_mem_wrdata[9]), .DIA10(centroid_mem_wrdata[10]), .DIA11(centroid_mem_wrdata[11]),
////                        .DIA12(centroid_mem_wrdata[12]), .DIA13(centroid_mem_wrdata[13]),.DIA14(centroid_mem_wrdata[14]),
////                        .DIA15(centroid_mem_wrdata[15]), .DOB0(centroid_mem_rddata[DATA_WIDTH*i]), .DOB1(centroid_mem_rddata[i][1]),
////                        .DOB2(centroid_mem_rddata[i][2]), .DOB3(centroid_mem_rddata[i][3]), .DOB4(centroid_mem_rddata[i][4]),
////                        .DOB5(centroid_mem_rddata[i][5]), .DOB6(centroid_mem_rddata[i][6]), .DOB7(centroid_mem_rddata[i][7]),
////                        .DOB8(centroid_mem_rddata[i][8]), .DOB9(centroid_mem_rddata[i][9]), .DOB10(centroid_mem_rddata[i][10]), 
////                        .DOB11(centroid_mem_rddata[i][11]), .DOB12(centroid_mem_rddata[i][12]), .DOB13(centroid_mem_rddata[i][13]),
////                        .DOB14(centroid_mem_rddata[i][14]), .DOB15(centroid_mem_rddata[i][15]), .DOA0(), .DOA1(), .DOA2(), .DOA3(),
////                        .DOA4(), .DOA5(), .DOA6(), .DOA7(), .DOA8(), .DOA9(), .DOA10(), .DOA11(), .DOA12(), .DOA13(), .DOA14(), .DOA15(), 
////                        .DIB0(1'b0), .DIB1(1'b0), .DIB2(1'b0), .DIB3(1'b0), .DIB4(1'b0), .DIB5(1'b0), .DIB6(1'b0), .DIB7(1'b0), .DIB8(1'b0),
////                        .DIB9(1'b0), .DIB10(1'b0), .DIB11(1'b0), .DIB12(1'b0), .DIB13(1'b0), .DIB14(1'b0), .DIB15(1'b0), .WEAN(centroid_mem_wean[i]), .WEBN(1'b1),
////                        .CKA(clk), .CKB(clk), .CSA(1'b1), .CSB(1'b1), .OEA(1'b0), .OEB(centroid_mem_oeb[i])
////                );
////                end  
////                
////                else begin:                                  
////                    SJ180_128X16X1CM4 Centroid_odd (
////                        .A0(centroid_mem_wraddr[0]), .A1(centroid_mem_wraddr[1]), .A2(centroid_mem_wraddr[2]), .A3(centroid_mem_wraddr[3]), 
////                        .A4(centroid_mem_wraddr[4]), .A5(centroid_mem_wraddr[5]), .A6(centroid_mem_wraddr[6]), 
////                        .B0(centroid_mem_rdaddr_even[0]), .B1(centroid_mem_rdaddr_even[1]), .B2(centroid_mem_rdaddr_even[2]), .B3(centroid_mem_rdaddr_even[3]), 
////                        .B4(centroid_mem_rdaddr_even[4]), .B5(centroid_mem_rdaddr_even[5]),.B6(centroid_mem_rdaddr_even[6]),
////                        .DIA0(centroid_mem_wrdata[0]), .DIA1(centroid_mem_wrdata[1]), .DIA2(centroid_mem_wrdata[2]), 
////                        .DIA3(centroid_mem_wrdata[3]), .DIA4(centroid_mem_wrdata[4]), .DIA5(centroid_mem_wrdata[5]), 
////                        .DIA6(centroid_mem_wrdata[6]), .DIA7(centroid_mem_wrdata[7]), .DIA8(centroid_mem_wrdata[8]),
////                        .DIA9(centroid_mem_wrdata[9]), .DIA10(centroid_mem_wrdata[10]), .DIA11(centroid_mem_wrdata[11]),
////                        .DIA12(centroid_mem_wrdata[12]), .DIA13(centroid_mem_wrdata[13]),.DIA14(centroid_mem_wrdata[14]),
////                        .DIA15(centroid_mem_wrdata[15]), .DOB0(centroid_mem_rddata[DATA_WIDTH*i]), .DOB1(centroid_mem_rddata[i][1]),
////                        .DOB2(centroid_mem_rddata[i][2]), .DOB3(centroid_mem_rddata[i][3]), .DOB4(centroid_mem_rddata[i][4]),
////                        .DOB5(centroid_mem_rddata[i][5]), .DOB6(centroid_mem_rddata[i][6]), .DOB7(centroid_mem_rddata[i][7]),
////                        .DOB8(centroid_mem_rddata[i][8]), .DOB9(centroid_mem_rddata[i][9]), .DOB10(centroid_mem_rddata[i][10]), 
////                        .DOB11(centroid_mem_rddata[i][11]), .DOB12(centroid_mem_rddata[i][12]), .DOB13(centroid_mem_rddata[i][13]),
////                        .DOB14(centroid_mem_rddata[i][14]), .DOB15(centroid_mem_rddata[i][15]), .DOA0(), .DOA1(), .DOA2(), .DOA3(),
////                        .DOA4(), .DOA5(), .DOA6(), .DOA7(), .DOA8(), .DOA9(), .DOA10(), .DOA11(), .DOA12(), .DOA13(), .DOA14(), .DOA15(), 
////                        .DIB0(1'b0), .DIB1(1'b0), .DIB2(1'b0), .DIB3(1'b0), .DIB4(1'b0), .DIB5(1'b0), .DIB6(1'b0), .DIB7(1'b0), .DIB8(1'b0),
////                        .DIB9(1'b0), .DIB10(1'b0), .DIB11(1'b0), .DIB12(1'b0), .DIB13(1'b0), .DIB14(1'b0), .DIB15(1'b0), .WEAN(centroid_mem_wean[i]), .WEBN(1'b1),
////                        .CKA(clk), .CKB(clk), .CSA(1'b1), .CSB(1'b1), .OEA(1'b0), .OEB(centroid_mem_oeb[i])
////                );
////                end  
                
//                if (i[0]) begin: centroid_mem_odd
//                    SJ180_128X32X1CM4 Centroid_odd (
//                        .A0(centroid_mem_wraddr[0]), .A1(centroid_mem_wraddr[1]), .A2(centroid_mem_wraddr[2]), .A3(centroid_mem_wraddr[3]), 
//                        .A4(centroid_mem_wraddr[4]), .A5(centroid_mem_wraddr[5]), .A6(centroid_mem_wraddr[6]), 
//                        .B0(centroid_mem_rdaddr_odd[0]), .B1(centroid_mem_rdaddr_odd[1]), .B2(centroid_mem_rdaddr_odd[2]), .B3(centroid_mem_rdaddr_odd[3]), 
//                        .B4(centroid_mem_rdaddr_odd[4]), .B5(centroid_mem_rdaddr_odd[5]), .B6(centroid_mem_rdaddr_odd[6]),
                        
//                        .DIA0(centroid_mem_wrdata[0]), .DIA1(centroid_mem_wrdata[1]), .DIA2(centroid_mem_wrdata[2]), 
//                        .DIA3(centroid_mem_wrdata[3]), .DIA4(centroid_mem_wrdata[4]), .DIA5(centroid_mem_wrdata[5]), 
//                        .DIA6(centroid_mem_wrdata[6]), .DIA7(centroid_mem_wrdata[7]), .DIA8(centroid_mem_wrdata[8]),
//                        .DIA9(centroid_mem_wrdata[9]), .DIA10(centroid_mem_wrdata[10]), .DIA11(centroid_mem_wrdata[11]),
//                        .DIA12(centroid_mem_wrdata[12]), .DIA13(centroid_mem_wrdata[13]),.DIA14(centroid_mem_wrdata[14]),
//                        .DIA15(centroid_mem_wrdata[15]), .DIA16(centroid_mem_wrdata[16]), .DIA17(centroid_mem_wrdata[17]), 
//                        .DIA18(centroid_mem_wrdata[18]), .DIA19(centroid_mem_wrdata[19]), .DIA20(centroid_mem_wrdata[20]), 
//                        .DIA21(centroid_mem_wrdata[21]), .DIA22(centroid_mem_wrdata[22]), .DIA23(centroid_mem_wrdata[23]),
//                        .DIA24(centroid_mem_wrdata[24]), .DIA25(centroid_mem_wrdata[25]), .DIA26(centroid_mem_wrdata[26]),
//                        .DIA27(centroid_mem_wrdata[27]), .DIA28(centroid_mem_wrdata[28]), .DIA29(centroid_mem_wrdata[29]), 
//                        .DIA30(centroid_mem_wrdata[30]), .DIA31(centroid_mem_wrdata[31]), 
                            
//                        .DOB0(centroid_mem_rddata[i][0]), .DOB1(centroid_mem_rddata[i][1]),
//                        .DOB2(centroid_mem_rddata[i][2]), .DOB3(centroid_mem_rddata[i][3]), .DOB4(centroid_mem_rddata[i][4]),
//                        .DOB5(centroid_mem_rddata[i][5]), .DOB6(centroid_mem_rddata[i][6]), .DOB7(centroid_mem_rddata[i][7]),
//                        .DOB8(centroid_mem_rddata[i][8]), .DOB9(centroid_mem_rddata[i][9]), .DOB10(centroid_mem_rddata[i][10]), 
//                        .DOB11(centroid_mem_rddata[i][11]), .DOB12(centroid_mem_rddata[i][12]), .DOB13(centroid_mem_rddata[i][13]),
//                        .DOB14(centroid_mem_rddata[i][14]), .DOB15(centroid_mem_rddata[i][15]), .DOB16(centroid_mem_rddata[i][16]), 
//                        .DOB17(centroid_mem_rddata[i][17]), .DOB18(centroid_mem_rddata[i][18]), .DOB19(centroid_mem_rddata[i][19]), 
//                        .DOB20(centroid_mem_rddata[i][20]), .DOB21(centroid_mem_rddata[i][21]), .DOB22(centroid_mem_rddata[i][22]), 
//                        .DOB23(centroid_mem_rddata[i][23]), .DOB24(centroid_mem_rddata[i][24]), .DOB25(centroid_mem_rddata[i][25]),
//                        .DOB26(centroid_mem_rddata[i][26]), .DOB27(centroid_mem_rddata[i][27]), .DOB28(centroid_mem_rddata[i][28]), 
//                        .DOB29(centroid_mem_rddata[i][29]), .DOB30(centroid_mem_rddata[i][30]), .DOB31(centroid_mem_rddata[i][31]),
                           
//                        .DOA0(), .DOA1(), .DOA2(), .DOA3(), .DOA4(), .DOA5(), .DOA6(), .DOA7(), 
//                        .DOA8(), .DOA9(), .DOA10(), .DOA11(), .DOA12(), .DOA13(), .DOA14(), .DOA15(), 
//                        .DOA16(),.DOA17(),.DOA18(),.DOA19(), .DOA20(),.DOA21(),.DOA22(),.DOA23(),
//                        .DOA24(), .DOA25(),.DOA26(),.DOA27(), .DOA28(),.DOA29(),.DOA30(),.DOA31(),
                               
//                        .DIB0(1'b0), .DIB1(1'b0), .DIB2(1'b0), .DIB3(1'b0), .DIB4(1'b0), .DIB5(1'b0), .DIB6(1'b0), .DIB7(1'b0), .DIB8(1'b0), 
//                        .DIB9(1'b0), .DIB10(1'b0), .DIB11(1'b0), .DIB12(1'b0), .DIB13(1'b0), .DIB14(1'b0), .DIB15(1'b0), .DIB16(1'b0), .DIB17(1'b0), 
//                        .DIB18(1'b0), .DIB19(1'b0), .DIB20(1'b0), .DIB21(1'b0), .DIB22(1'b0), .DIB23(1'b0), .DIB24(1'b0), .DIB25(1'b0), .DIB26(1'b0),
//                        .DIB27(1'b0), .DIB28(1'b0),.DIB29(1'b0),.DIB30(1'b0),.DIB31(1'b0),
//                        .WEAN(centroid_mem_wean[i]), .WEBN(1'b1), .CKA(clk), .CKB(clk), .CSA(1'b1), .CSB(1'b1), .OEA(1'b0), .OEB(centroid_mem_oeb[i])
//                    );
//                end
                                
//                else begin: centroid_mem_even
//                    SJ180_128X32X1CM4 Centroid_even (
//                        .A0(centroid_mem_wraddr[0]), .A1(centroid_mem_wraddr[1]), .A2(centroid_mem_wraddr[2]), .A3(centroid_mem_wraddr[3]), 
//                        .A4(centroid_mem_wraddr[4]), .A5(centroid_mem_wraddr[5]), .A6(centroid_mem_wraddr[6]), 
//                        .B0(centroid_mem_rdaddr_even[0]), .B1(centroid_mem_rdaddr_even[1]), .B2(centroid_mem_rdaddr_even[2]), .B3(centroid_mem_rdaddr_even[3]), 
//                        .B4(centroid_mem_rdaddr_even[4]), .B5(centroid_mem_rdaddr_even[5]), .B6(centroid_mem_rdaddr_even[6]),
                                
//                        .DIA0(centroid_mem_wrdata[0]), .DIA1(centroid_mem_wrdata[1]), .DIA2(centroid_mem_wrdata[2]), 
//                        .DIA3(centroid_mem_wrdata[3]), .DIA4(centroid_mem_wrdata[4]), .DIA5(centroid_mem_wrdata[5]), 
//                        .DIA6(centroid_mem_wrdata[6]), .DIA7(centroid_mem_wrdata[7]), .DIA8(centroid_mem_wrdata[8]),
//                        .DIA9(centroid_mem_wrdata[9]), .DIA10(centroid_mem_wrdata[10]), .DIA11(centroid_mem_wrdata[11]),
//                        .DIA12(centroid_mem_wrdata[12]), .DIA13(centroid_mem_wrdata[13]),.DIA14(centroid_mem_wrdata[14]),
//                        .DIA15(centroid_mem_wrdata[15]), .DIA16(centroid_mem_wrdata[16]), .DIA17(centroid_mem_wrdata[17]), 
//                        .DIA18(centroid_mem_wrdata[18]), .DIA19(centroid_mem_wrdata[19]), .DIA20(centroid_mem_wrdata[20]), 
//                        .DIA21(centroid_mem_wrdata[21]), .DIA22(centroid_mem_wrdata[22]), .DIA23(centroid_mem_wrdata[23]),
//                        .DIA24(centroid_mem_wrdata[24]), .DIA25(centroid_mem_wrdata[25]), .DIA26(centroid_mem_wrdata[26]),
//                        .DIA27(centroid_mem_wrdata[27]), .DIA28(centroid_mem_wrdata[28]), .DIA29(centroid_mem_wrdata[29]), 
//                        .DIA30(centroid_mem_wrdata[30]), .DIA31(centroid_mem_wrdata[31]), 
                        
//                        .DOB0(centroid_mem_rddata[i][0]), .DOB1(centroid_mem_rddata[i][1]),
//                        .DOB2(centroid_mem_rddata[i][2]), .DOB3(centroid_mem_rddata[i][3]), .DOB4(centroid_mem_rddata[i][4]),
//                        .DOB5(centroid_mem_rddata[i][5]), .DOB6(centroid_mem_rddata[i][6]), .DOB7(centroid_mem_rddata[i][7]),
//                        .DOB8(centroid_mem_rddata[i][8]), .DOB9(centroid_mem_rddata[i][9]), .DOB10(centroid_mem_rddata[i][10]), 
//                        .DOB11(centroid_mem_rddata[i][11]), .DOB12(centroid_mem_rddata[i][12]), .DOB13(centroid_mem_rddata[i][13]),
//                        .DOB14(centroid_mem_rddata[i][14]), .DOB15(centroid_mem_rddata[i][15]), .DOB16(centroid_mem_rddata[i][16]), 
//                        .DOB17(centroid_mem_rddata[i][17]), .DOB18(centroid_mem_rddata[i][18]), .DOB19(centroid_mem_rddata[i][19]), 
//                        .DOB20(centroid_mem_rddata[i][20]), .DOB21(centroid_mem_rddata[i][21]), .DOB22(centroid_mem_rddata[i][22]), 
//                        .DOB23(centroid_mem_rddata[i][23]), .DOB24(centroid_mem_rddata[i][24]), .DOB25(centroid_mem_rddata[i][25]),
//                        .DOB26(centroid_mem_rddata[i][26]), .DOB27(centroid_mem_rddata[i][27]), .DOB28(centroid_mem_rddata[i][28]), 
//                        .DOB29(centroid_mem_rddata[i][29]), .DOB30(centroid_mem_rddata[i][30]), .DOB31(centroid_mem_rddata[i][31]),
                        
//                        .DOA0(), .DOA1(), .DOA2(), .DOA3(), .DOA4(), .DOA5(), .DOA6(), .DOA7(), 
//                        .DOA8(), .DOA9(), .DOA10(), .DOA11(), .DOA12(), .DOA13(), .DOA14(), .DOA15(), 
//                        .DOA16(),.DOA17(),.DOA18(),.DOA19(), .DOA20(),.DOA21(),.DOA22(),.DOA23(),
//                        .DOA24(), .DOA25(),.DOA26(),.DOA27(), .DOA28(),.DOA29(),.DOA30(),.DOA31(),
                            
//                        .DIB0(1'b0), .DIB1(1'b0), .DIB2(1'b0), .DIB3(1'b0), .DIB4(1'b0), .DIB5(1'b0), .DIB6(1'b0), .DIB7(1'b0), .DIB8(1'b0), 
//                        .DIB9(1'b0), .DIB10(1'b0), .DIB11(1'b0), .DIB12(1'b0), .DIB13(1'b0), .DIB14(1'b0), .DIB15(1'b0), .DIB16(1'b0), .DIB17(1'b0), 
//                        .DIB18(1'b0), .DIB19(1'b0), .DIB20(1'b0), .DIB21(1'b0), .DIB22(1'b0), .DIB23(1'b0), .DIB24(1'b0), .DIB25(1'b0), .DIB26(1'b0),
//                        .DIB27(1'b0), .DIB28(1'b0),.DIB29(1'b0),.DIB30(1'b0),.DIB31(1'b0),
//                        .WEAN(centroid_mem_wean[i]), .WEBN(1'b1), .CKA(clk), .CKB(clk), .CSA(1'b1), .CSB(1'b1), .OEA(1'b0), .OEB(centroid_mem_oeb[i])
//                    );
//                end
//            end
//        end
    endgenerate

    generate
        for (i=0;i<NO_OF_CLUSTERS;i=i+1) begin: gen_centroid_rden
            if (i[0]) begin: gen_centroid_rden_odd
                assign centroid_rden_odd[i/2] = centroid_mem_rden_in[i];
            end
            
            else begin: gen_centroid_rden_even
                assign centroid_rden_even[i/2] = centroid_mem_rden_in[i];
            end
        end
    endgenerate
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            centroid_rden_even_r <= {RDEN_EVEN_WIDTH{1'b0}};
            centroid_rden_odd_r <= {RDEN_ODD_WIDTH{1'b0}};
        end
        
        else begin
            centroid_rden_even_r <= centroid_rden_even;
            centroid_rden_odd_r <= centroid_rden_odd;            
        end
    end
    
    // The following encoder is just to encode the centroid_mem_rden which is 
    // in one-hot format. This encoded value is used to select the rdata output.
    encoder #(
        .INPUT_WIDTH (RDEN_ODD_WIDTH)
    ) centroid_mem_rden_enc_odd (
        .enc_in (centroid_rden_odd_r),
        .enc_out (centroid_rden_odd_enc)
    );

    encoder #(
        .INPUT_WIDTH (RDEN_EVEN_WIDTH)
    ) centroid_mem_rden_enc_even (
        .enc_in (centroid_rden_even_r),
        .enc_out (centroid_rden_even_enc)
    );
    
    generate
        for (i=0;i<NO_OF_CLUSTERS;i=i+1) begin: genblk_centroid_rdata_odd
            if (i[0]) begin: gen_centroid_old_rdata_odd
                assign centroid_rdata_odd[i/2] = centroid_mem_rddata[i];
            end
            
            else begin: genblk_centroid_old_rddata_even
                assign centroid_rddata_even[i/2] = centroid_mem_rddata[i];
            end
        end
    endgenerate

    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin        
            centroid_mem_rdata_vld_o <= 2'b00;
            centroid_mem_rdata0_o <= {DATA_WIDTH{1'b0}};
            centroid_mem_rdata1_o <= {DATA_WIDTH{1'b0}};
        end
        
        else begin
            centroid_mem_rdata_vld_o <={|centroid_rden_odd_r, |centroid_rden_even_r};
            
            if (|centroid_rden_even_r)
                centroid_mem_rdata0_o <= centroid_rddata_even[centroid_rden_even_enc];
            if (|centroid_rden_odd_r)
                centroid_mem_rdata1_o <= centroid_rdata_odd[centroid_rden_odd_enc];
        end
    end
    

    ///////////////////////////////////////////////////////////////////////////////////////
    //-----------------------Old Centroid Memory----------------------------//
    ///////////////////////////////////////////////////////////////////////////////////////

    always @(negedge clk or negedge nreset) begin
        if (~nreset) begin
            centroid_old_mem_wean <= {NO_OF_CLUSTERS{1'b1}};
            centroid_old_mem_wraddr <= {DIM_WIDTH{1'b0}};
            centroid_old_mem_wrdata <= {DATA_WIDTH{1'b0}};        
        end

        else begin
            centroid_old_mem_wean <= ~centroid_old_mem_wren_in;
            centroid_old_mem_wraddr <= centroid_old_mem_wraddr_in;
            centroid_old_mem_wrdata <= centroid_old_mem_wrdata_in;
        end
    end

    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            centroid_old_mem_oeb <= {NO_OF_CLUSTERS{1'b0}};
        else
            centroid_old_mem_oeb <= centroid_old_mem_rden_in;
    end


    // Instantiate the Old Centroid memory units    
    generate 
        if ((SIMULATION == "NO") && (SYNTHESIS_TOOL == "VIVADO")) begin: gen_Vivado_syn_centroid_old            
            for (i=0;i<NO_OF_CLUSTERS;i=i+1) begin: gen_centroid_old_mem
                if (i[0]) begin: centroid_old_mem_odd
                    RAM_SDP #(
                        .RAM_WIDTH (DATA_WIDTH),                    // Specify RAM data width
                        .RAM_DEPTH (2**DIM_WIDTH),                  // Specify RAM depth (number of entries)
                        .RAM_TYPE ("LOW_LATENCY")
                    ) Centroid_Old_odd (  
                        .addra (centroid_old_mem_wraddr_in),                           // Write address bus, width determined from RAM_DEPTH
                        .addrb (centroid_rdaddr1_vld_in ? 
                                    centroid_rdaddr1_in : centroid_rdaddr0_in),                        // Read address bus, width determined from RAM_DEPTH
                        .dina (centroid_old_mem_wrdata_in),               // RAM input data
                        .clk (clk),                                 // Clock
                        .wea (centroid_old_mem_wren_in[i]),                               // Write enable
                        .enb (centroid_old_mem_rden_in[i]),                              // Read Enable, for additional power savings, disable when not in use
                        .rst (~nreset),                             // Output reset (does not affect memory contents)
                        .regceb (1'b0),                             // Output register enable
                        .doutb (centroid_old_mem_rddata[i])   // RAM output data
                    );
                end
                
                else begin: centroid_old_mem_even
                    RAM_SDP #(
                        .RAM_WIDTH (DATA_WIDTH),                    // Specify RAM data width
                        .RAM_DEPTH (2**DIM_WIDTH),                  // Specify RAM depth (number of entries)
                        .RAM_TYPE ("LOW_LATENCY")
                    ) Centroid_Old_even (  
                        .addra (centroid_old_mem_wraddr_in),                           // Write address bus, width determined from RAM_DEPTH
                        .addrb (centroid_rdaddr0_in),                        // Read address bus, width determined from RAM_DEPTH
                        .dina (centroid_old_mem_wrdata_in),               // RAM input data
                        .clk (clk),                                 // Clock
                        .wea (centroid_old_mem_wren_in[i]),                               // Write enable
                        .enb (centroid_old_mem_rden_in[i]),                              // Read Enable, for additional power savings, disable when not in use
                        .rst (~nreset),                             // Output reset (does not affect memory contents)
                        .regceb (1'b0),                             // Output register enable
                        .doutb (centroid_old_mem_rddata[i])   // RAM output data
                    );
                end            
            end
        end            

//        else begin: gen_centroid_old_memory
//            for (i=0;i<DIM-1;i=i+1) begin: genblk_centroid_old_memory
////                if (i[0]) begin: centroid_old_mem_odd
////                      SJ180_1024X16X1CM4 Centroid_Old_odd (
////                        .A0(centroid_old_mem_wraddr[0]), .A1(centroid_old_mem_wraddr[1]), .A2(centroid_old_mem_wraddr[2]), .A3(centroid_old_mem_wraddr[3]), 
////                        .A4(centroid_old_mem_wraddr[4]), .A5(centroid_old_mem_wraddr[5]), .A6(centroid_old_mem_wraddr[6]), 
////                        .B0(centroid_mem_rdaddr_odd[0]), .B1(centroid_mem_rdaddr_odd[1]), .B2(centroid_mem_rdaddr_odd[2]), .B3(centroid_mem_rdaddr_odd[3]), 
////                        .B4(centroid_mem_rdaddr_odd[4]), .B5(centroid_mem_rdaddr_odd[5]),.B6(centroid_mem_rdaddr_odd[6]),
////                        .DIA0(centroid_old_mem_wrdata[0]), .DIA1(centroid_old_mem_wrdata[1]), .DIA2(centroid_old_mem_wrdata[2]), 
////                        .DIA3(centroid_old_mem_wrdata[3]), .DIA4(centroid_old_mem_wrdata[4]), .DIA5(centroid_old_mem_wrdata[5]), 
////                        .DIA6(centroid_old_mem_wrdata[6]), .DIA7(centroid_old_mem_wrdata[7]), .DIA8(centroid_old_mem_wrdata[8]),
////                        .DIA9(centroid_old_mem_wrdata[9]), .DIA10(centroid_old_mem_wrdata[10]), .DIA11(centroid_old_mem_wrdata[11]),
////                        .DIA12(centroid_old_mem_wrdata[12]), .DIA13(centroid_old_mem_wrdata[13]),.DIA14(centroid_old_mem_wrdata[14]),
////                        .DIA15(centroid_old_mem_wrdata[15]), .DOB0(centroid_old_mem_rddata[DATA_WIDTH*i]), .DOB1(centroid_old_mem_rddata[i][1]),
////                        .DOB2(centroid_old_mem_rddata[i][2]), .DOB3(centroid_old_mem_rddata[i][3]), .DOB4(centroid_old_mem_rddata[i][4]),
////                        .DOB5(centroid_old_mem_rddata[i][5]), .DOB6(centroid_old_mem_rddata[i][6]), .DOB7(centroid_old_mem_rddata[i][7]),
////                        .DOB8(centroid_old_mem_rddata[i][8]), .DOB9(centroid_old_mem_rddata[i][9]), .DOB10(centroid_old_mem_rddata[i][10]), 
////                        .DOB11(centroid_old_mem_rddata[i][11]), .DOB12(centroid_old_mem_rddata[i][12]), .DOB13(centroid_old_mem_rddata[i][13]),
////                        .DOB14(centroid_old_mem_rddata[i][14]), .DOB15(centroid_old_mem_rddata[i][15]), .DOA0(), .DOA1(), .DOA2(), .DOA3(),
////                        .DOA4(), .DOA5(), .DOA6(), .DOA7(), .DOA8(), .DOA9(), .DOA10(), .DOA11(), .DOA12(), .DOA13(), .DOA14(), .DOA15(), 
////                        .DIB0(1'b0), .DIB1(1'b0), .DIB2(1'b0), .DIB3(1'b0), .DIB4(1'b0), .DIB5(1'b0), .DIB6(1'b0), .DIB7(1'b0), .DIB8(1'b0),
////                        .DIB9(1'b0), .DIB10(1'b0), .DIB11(1'b0), .DIB12(1'b0), .DIB13(1'b0), .DIB14(1'b0), .DIB15(1'b0), .WEAN(centroid_old_mem_wean[i]), .WEBN(1'b1),
////                        .CKA(clk), .CKB(clk), .CSA(1'b1), .CSB(1'b1), .OEA(1'b0), .OEB(centroid_old_mem_oeb[i])
////                );
////                end  
////                
////                else begin:                                  
////                    SJ180_1024X16X1CM4 Centroid_Old_odd (
////                        .A0(centroid_old_mem_wraddr[0]), .A1(centroid_old_mem_wraddr[1]), .A2(centroid_old_mem_wraddr[2]), .A3(centroid_old_mem_wraddr[3]), 
////                        .A4(centroid_old_mem_wraddr[4]), .A5(centroid_old_mem_wraddr[5]), .A6(centroid_old_mem_wraddr[6]), 
////                        .B0(centroid_mem_rdaddr_even[0]), .B1(centroid_mem_rdaddr_even[1]), .B2(centroid_mem_rdaddr_even[2]), .B3(centroid_mem_rdaddr_even[3]), 
////                        .B4(centroid_mem_rdaddr_even[4]), .B5(centroid_mem_rdaddr_even[5]),.B6(centroid_mem_rdaddr_even[6]),
////                        .DIA0(centroid_old_mem_wrdata[0]), .DIA1(centroid_old_mem_wrdata[1]), .DIA2(centroid_old_mem_wrdata[2]), 
////                        .DIA3(centroid_old_mem_wrdata[3]), .DIA4(centroid_old_mem_wrdata[4]), .DIA5(centroid_old_mem_wrdata[5]), 
////                        .DIA6(centroid_old_mem_wrdata[6]), .DIA7(centroid_old_mem_wrdata[7]), .DIA8(centroid_old_mem_wrdata[8]),
////                        .DIA9(centroid_old_mem_wrdata[9]), .DIA10(centroid_old_mem_wrdata[10]), .DIA11(centroid_old_mem_wrdata[11]),
////                        .DIA12(centroid_old_mem_wrdata[12]), .DIA13(centroid_old_mem_wrdata[13]),.DIA14(centroid_old_mem_wrdata[14]),
////                        .DIA15(centroid_old_mem_wrdata[15]), .DOB0(centroid_old_mem_rddata[DATA_WIDTH*i]), .DOB1(centroid_old_mem_rddata[i][1]),
////                        .DOB2(centroid_old_mem_rddata[i][2]), .DOB3(centroid_old_mem_rddata[i][3]), .DOB4(centroid_old_mem_rddata[i][4]),
////                        .DOB5(centroid_old_mem_rddata[i][5]), .DOB6(centroid_old_mem_rddata[i][6]), .DOB7(centroid_old_mem_rddata[i][7]),
////                        .DOB8(centroid_old_mem_rddata[i][8]), .DOB9(centroid_old_mem_rddata[i][9]), .DOB10(centroid_old_mem_rddata[i][10]), 
////                        .DOB11(centroid_old_mem_rddata[i][11]), .DOB12(centroid_old_mem_rddata[i][12]), .DOB13(centroid_old_mem_rddata[i][13]),
////                        .DOB14(centroid_old_mem_rddata[i][14]), .DOB15(centroid_old_mem_rddata[i][15]), .DOA0(), .DOA1(), .DOA2(), .DOA3(),
////                        .DOA4(), .DOA5(), .DOA6(), .DOA7(), .DOA8(), .DOA9(), .DOA10(), .DOA11(), .DOA12(), .DOA13(), .DOA14(), .DOA15(), 
////                        .DIB0(1'b0), .DIB1(1'b0), .DIB2(1'b0), .DIB3(1'b0), .DIB4(1'b0), .DIB5(1'b0), .DIB6(1'b0), .DIB7(1'b0), .DIB8(1'b0),
////                        .DIB9(1'b0), .DIB10(1'b0), .DIB11(1'b0), .DIB12(1'b0), .DIB13(1'b0), .DIB14(1'b0), .DIB15(1'b0), .WEAN(centroid_old_mem_wean[i]), .WEBN(1'b1),
////                        .CKA(clk), .CKB(clk), .CSA(1'b1), .CSB(1'b1), .OEA(1'b0), .OEB(centroid_old_mem_oeb[i])
////                );
////                end  
                
//                if (i[0]) begin: centroid_old_mem_odd
//                    SJ180_128X32X1CM4 Centroid_Old_odd (
//                        .A0(centroid_old_mem_wraddr[0]), .A1(centroid_old_mem_wraddr[1]), .A2(centroid_old_mem_wraddr[2]), .A3(centroid_old_mem_wraddr[3]), 
//                        .A4(centroid_old_mem_wraddr[4]), .A5(centroid_old_mem_wraddr[5]), .A6(centroid_old_mem_wraddr[6]), 
//                        .B0(centroid_mem_rdaddr_odd[0]), .B1(centroid_mem_rdaddr_odd[1]), .B2(centroid_mem_rdaddr_odd[2]), .B3(centroid_mem_rdaddr_odd[3]), 
//                        .B4(centroid_mem_rdaddr_odd[4]), .B5(centroid_mem_rdaddr_odd[5]), .B6(centroid_mem_rdaddr_odd[6]),
                           
//                        .DIA0(centroid_old_mem_wrdata[0]), .DIA1(centroid_old_mem_wrdata[1]), .DIA2(centroid_old_mem_wrdata[2]), 
//                        .DIA3(centroid_old_mem_wrdata[3]), .DIA4(centroid_old_mem_wrdata[4]), .DIA5(centroid_old_mem_wrdata[5]), 
//                        .DIA6(centroid_old_mem_wrdata[6]), .DIA7(centroid_old_mem_wrdata[7]), .DIA8(centroid_old_mem_wrdata[8]),
//                        .DIA9(centroid_old_mem_wrdata[9]), .DIA10(centroid_old_mem_wrdata[10]), .DIA11(centroid_old_mem_wrdata[11]),
//                        .DIA12(centroid_old_mem_wrdata[12]), .DIA13(centroid_old_mem_wrdata[13]),.DIA14(centroid_old_mem_wrdata[14]),
//                        .DIA15(centroid_old_mem_wrdata[15]), .DIA16(centroid_old_mem_wrdata[16]), .DIA17(centroid_old_mem_wrdata[17]), 
//                        .DIA18(centroid_old_mem_wrdata[18]), .DIA19(centroid_old_mem_wrdata[19]), .DIA20(centroid_old_mem_wrdata[20]), 
//                        .DIA21(centroid_old_mem_wrdata[21]), .DIA22(centroid_old_mem_wrdata[22]), .DIA23(centroid_old_mem_wrdata[23]),
//                        .DIA24(centroid_old_mem_wrdata[24]), .DIA25(centroid_old_mem_wrdata[25]), .DIA26(centroid_old_mem_wrdata[26]),
//                        .DIA27(centroid_old_mem_wrdata[27]), .DIA28(centroid_old_mem_wrdata[28]), .DIA29(centroid_old_mem_wrdata[29]), 
//                        .DIA30(centroid_old_mem_wrdata[30]), .DIA31(centroid_old_mem_wrdata[31]), 
                            
//                        .DOB0(centroid_old_mem_rddata[i][0]), .DOB1(centroid_old_mem_rddata[i][1]),
//                        .DOB2(centroid_old_mem_rddata[i][2]), .DOB3(centroid_old_mem_rddata[i][3]), .DOB4(centroid_old_mem_rddata[i][4]),
//                        .DOB5(centroid_old_mem_rddata[i][5]), .DOB6(centroid_old_mem_rddata[i][6]), .DOB7(centroid_old_mem_rddata[i][7]),
//                        .DOB8(centroid_old_mem_rddata[i][8]), .DOB9(centroid_old_mem_rddata[i][9]), .DOB10(centroid_old_mem_rddata[i][10]), 
//                        .DOB11(centroid_old_mem_rddata[i][11]), .DOB12(centroid_old_mem_rddata[i][12]), .DOB13(centroid_old_mem_rddata[i][13]),
//                        .DOB14(centroid_old_mem_rddata[i][14]), .DOB15(centroid_old_mem_rddata[i][15]), .DOB16(centroid_old_mem_rddata[i][16]), 
//                        .DOB17(centroid_old_mem_rddata[i][17]), .DOB18(centroid_old_mem_rddata[i][18]), .DOB19(centroid_old_mem_rddata[i][19]), 
//                        .DOB20(centroid_old_mem_rddata[i][20]), .DOB21(centroid_old_mem_rddata[i][21]), .DOB22(centroid_old_mem_rddata[i][22]), 
//                        .DOB23(centroid_old_mem_rddata[i][23]), .DOB24(centroid_old_mem_rddata[i][24]), .DOB25(centroid_old_mem_rddata[i][25]),
//                        .DOB26(centroid_old_mem_rddata[i][26]), .DOB27(centroid_old_mem_rddata[i][27]), .DOB28(centroid_old_mem_rddata[i][28]), 
//                        .DOB29(centroid_old_mem_rddata[i][29]), .DOB30(centroid_old_mem_rddata[i][30]), .DOB31(centroid_old_mem_rddata[i][31]),
                            
//                        .DOA0(), .DOA1(), .DOA2(), .DOA3(), .DOA4(), .DOA5(), .DOA6(), .DOA7(), 
//                        .DOA8(), .DOA9(), .DOA10(), .DOA11(), .DOA12(), .DOA13(), .DOA14(), .DOA15(), 
//                        .DOA16(),.DOA17(),.DOA18(),.DOA19(), .DOA20(),.DOA21(),.DOA22(),.DOA23(),
//                        .DOA24(), .DOA25(),.DOA26(),.DOA27(), .DOA28(),.DOA29(),.DOA30(),.DOA31(),
                                
//                        .DIB0(1'b0), .DIB1(1'b0), .DIB2(1'b0), .DIB3(1'b0), .DIB4(1'b0), .DIB5(1'b0), .DIB6(1'b0), .DIB7(1'b0), .DIB8(1'b0), 
//                        .DIB9(1'b0), .DIB10(1'b0), .DIB11(1'b0), .DIB12(1'b0), .DIB13(1'b0), .DIB14(1'b0), .DIB15(1'b0), .DIB16(1'b0), .DIB17(1'b0), 
//                        .DIB18(1'b0), .DIB19(1'b0), .DIB20(1'b0), .DIB21(1'b0), .DIB22(1'b0), .DIB23(1'b0), .DIB24(1'b0), .DIB25(1'b0), .DIB26(1'b0),
//                        .DIB27(1'b0), .DIB28(1'b0),.DIB29(1'b0),.DIB30(1'b0),.DIB31(1'b0),
//                        .WEAN(centroid_old_mem_wean[i]), .WEBN(1'b1), .CKA(clk), .CKB(clk), .CSA(1'b1), .CSB(1'b1), .OEA(1'b0), .OEB(centroid_old_mem_oeb[i])
//                    );
//                end
                               
//                else begin: centroid_old_mem_even
//                    SJ180_128X32X1CM4 Centroid_Old_even (
//                        .A0(centroid_old_mem_wraddr[0]), .A1(centroid_old_mem_wraddr[1]), .A2(centroid_old_mem_wraddr[2]), .A3(centroid_old_mem_wraddr[3]), 
//                        .A4(centroid_old_mem_wraddr[4]), .A5(centroid_old_mem_wraddr[5]), .A6(centroid_old_mem_wraddr[6]), 
//                        .B0(centroid_mem_rdaddr_even[0]), .B1(centroid_mem_rdaddr_even[1]), .B2(centroid_mem_rdaddr_even[2]), .B3(centroid_mem_rdaddr_even[3]), 
//                        .B4(centroid_mem_rdaddr_even[4]), .B5(centroid_mem_rdaddr_even[5]), .B6(centroid_mem_rdaddr_even[6]),
                                
//                        .DIA0(centroid_old_mem_wrdata[0]), .DIA1(centroid_old_mem_wrdata[1]), .DIA2(centroid_old_mem_wrdata[2]), 
//                        .DIA3(centroid_old_mem_wrdata[3]), .DIA4(centroid_old_mem_wrdata[4]), .DIA5(centroid_old_mem_wrdata[5]), 
//                        .DIA6(centroid_old_mem_wrdata[6]), .DIA7(centroid_old_mem_wrdata[7]), .DIA8(centroid_old_mem_wrdata[8]),
//                        .DIA9(centroid_old_mem_wrdata[9]), .DIA10(centroid_old_mem_wrdata[10]), .DIA11(centroid_old_mem_wrdata[11]),
//                        .DIA12(centroid_old_mem_wrdata[12]), .DIA13(centroid_old_mem_wrdata[13]),.DIA14(centroid_old_mem_wrdata[14]),
//                        .DIA15(centroid_old_mem_wrdata[15]), .DIA16(centroid_old_mem_wrdata[16]), .DIA17(centroid_old_mem_wrdata[17]), 
//                        .DIA18(centroid_old_mem_wrdata[18]), .DIA19(centroid_old_mem_wrdata[19]), .DIA20(centroid_old_mem_wrdata[20]), 
//                        .DIA21(centroid_old_mem_wrdata[21]), .DIA22(centroid_old_mem_wrdata[22]), .DIA23(centroid_old_mem_wrdata[23]),
//                        .DIA24(centroid_old_mem_wrdata[24]), .DIA25(centroid_old_mem_wrdata[25]), .DIA26(centroid_old_mem_wrdata[26]),
//                        .DIA27(centroid_old_mem_wrdata[27]), .DIA28(centroid_old_mem_wrdata[28]), .DIA29(centroid_old_mem_wrdata[29]), 
//                        .DIA30(centroid_old_mem_wrdata[30]), .DIA31(centroid_old_mem_wrdata[31]), 
                        
//                        .DOB0(centroid_old_mem_rddata[i][0]), .DOB1(centroid_old_mem_rddata[i][1]),
//                        .DOB2(centroid_old_mem_rddata[i][2]), .DOB3(centroid_old_mem_rddata[i][3]), .DOB4(centroid_old_mem_rddata[i][4]),
//                        .DOB5(centroid_old_mem_rddata[i][5]), .DOB6(centroid_old_mem_rddata[i][6]), .DOB7(centroid_old_mem_rddata[i][7]),
//                        .DOB8(centroid_old_mem_rddata[i][8]), .DOB9(centroid_old_mem_rddata[i][9]), .DOB10(centroid_old_mem_rddata[i][10]), 
//                        .DOB11(centroid_old_mem_rddata[i][11]), .DOB12(centroid_old_mem_rddata[i][12]), .DOB13(centroid_old_mem_rddata[i][13]),
//                        .DOB14(centroid_old_mem_rddata[i][14]), .DOB15(centroid_old_mem_rddata[i][15]), .DOB16(centroid_old_mem_rddata[i][16]), 
//                        .DOB17(centroid_old_mem_rddata[i][17]), .DOB18(centroid_old_mem_rddata[i][18]), .DOB19(centroid_old_mem_rddata[i][19]), 
//                        .DOB20(centroid_old_mem_rddata[i][20]), .DOB21(centroid_old_mem_rddata[i][21]), .DOB22(centroid_old_mem_rddata[i][22]), 
//                        .DOB23(centroid_old_mem_rddata[i][23]), .DOB24(centroid_old_mem_rddata[i][24]), .DOB25(centroid_old_mem_rddata[i][25]),
//                        .DOB26(centroid_old_mem_rddata[i][26]), .DOB27(centroid_old_mem_rddata[i][27]), .DOB28(centroid_old_mem_rddata[i][28]), 
//                        .DOB29(centroid_old_mem_rddata[i][29]), .DOB30(centroid_old_mem_rddata[i][30]), .DOB31(centroid_old_mem_rddata[i][31]),
                        
//                        .DOA0(), .DOA1(), .DOA2(), .DOA3(), .DOA4(), .DOA5(), .DOA6(), .DOA7(), 
//                        .DOA8(), .DOA9(), .DOA10(), .DOA11(), .DOA12(), .DOA13(), .DOA14(), .DOA15(), 
//                        .DOA16(),.DOA17(),.DOA18(),.DOA19(), .DOA20(),.DOA21(),.DOA22(),.DOA23(),
//                        .DOA24(), .DOA25(),.DOA26(),.DOA27(), .DOA28(),.DOA29(),.DOA30(),.DOA31(),
                            
//                        .DIB0(1'b0), .DIB1(1'b0), .DIB2(1'b0), .DIB3(1'b0), .DIB4(1'b0), .DIB5(1'b0), .DIB6(1'b0), .DIB7(1'b0), .DIB8(1'b0), 
//                        .DIB9(1'b0), .DIB10(1'b0), .DIB11(1'b0), .DIB12(1'b0), .DIB13(1'b0), .DIB14(1'b0), .DIB15(1'b0), .DIB16(1'b0), .DIB17(1'b0), 
//                        .DIB18(1'b0), .DIB19(1'b0), .DIB20(1'b0), .DIB21(1'b0), .DIB22(1'b0), .DIB23(1'b0), .DIB24(1'b0), .DIB25(1'b0), .DIB26(1'b0),
//                        .DIB27(1'b0), .DIB28(1'b0),.DIB29(1'b0),.DIB30(1'b0),.DIB31(1'b0),
//                        .WEAN(centroid_old_mem_wean[i]), .WEBN(1'b1), .CKA(clk), .CKB(clk), .CSA(1'b1), .CSB(1'b1), .OEA(1'b0), .OEB(centroid_old_mem_oeb[i])
//                    );
//                end
//            end
//        end
    endgenerate
        
    generate
        for (i=0;i<NO_OF_CLUSTERS;i=i+1) begin: genblk_centroid_old_rdata_odd
            if (i[0]) begin: gen_centroid_old_rdata_odd
                assign centroid_old_rdata_odd[i/2] = centroid_old_mem_rddata[i];
            end
            
            else begin: genblk_centroid_old_rddata_even
                assign centroid_old_rddata_even[i/2] = centroid_old_mem_rddata[i];
            end
        end
    endgenerate
            
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin        
            centroid_old_mem_rdata0_o <= {DATA_WIDTH{1'b0}};
            centroid_old_mem_rdata1_o <= {DATA_WIDTH{1'b0}};
        end
        
        else begin
            if (|centroid_old_mem_oeb && |centroid_rden_even_r)
                centroid_old_mem_rdata0_o <= centroid_old_rddata_even[centroid_rden_even_enc];
            if (centroid_old_mem_oeb && |centroid_rden_odd_r)
                centroid_old_mem_rdata1_o <= centroid_old_rdata_odd[centroid_rden_odd_enc];
        end
    end

    
endmodule