module forward_unit(
    input [4:0] addrA_E, addrB_E,
    input [4:0] addrD_M, addrD_W,
    input RegWEn_M, RegWEn_W,
    output reg [1:0] fwdA, fwdB
);

    always @(*) begin 
        fwdA = 2'b00;
        if (RegWEn_M && (addrD_M != 5'b0) && (addrD_M == addrA_E)) begin 
            fwdA = 2'b10; // Forward from MEM stage
        end else if (RegWEn_W && (addrD_W != 5'b0) && (addrD_W == addrA_E)) begin 
            fwdA = 2'b01; // Forward from WB stage
        end

        fwdB = 2'b00;
        if (RegWEn_M && (addrD_M != 5'b0) && (addrD_M == addrB_E)) begin 
            fwdB = 2'b10; // Forward from MEM stage
        end else if (RegWEn_W && (addrD_W != 5'b0) && (addrD_W == addrB_E)) begin 
            fwdB = 2'b01; // Forward from WB stage
        end
    end
endmodule