module hazard_detect (
    input  wire [4:0] addrA_D,
    input  wire [4:0] addrB_D,
    input  wire [4:0] addrD_E,
    input  wire       Is_Load_E,
    input  wire       UsesRs1_D,
    input  wire       UsesRs2_D,
    output wire       stall_F, 
    output wire       stall_D,    
    output wire       flush_E      
);
    wire load_use = Is_Load_E && (addrD_E != 5'd0) &&
                    ((UsesRs1_D && (addrA_D == addrD_E)) ||
                     (UsesRs2_D && (addrB_D == addrD_E)));
 
    assign stall_F = load_use;
    assign stall_D = load_use;
    assign flush_E = load_use;
endmodule