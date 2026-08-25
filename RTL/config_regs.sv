// =============================================================================
// Module Name:    config_regs
// Description:    Configuration Register File for the Priority Interrupt Controller.
//                 Allows the CPU to configure interrupt priorities and masks.
// =============================================================================

module config_regs (
    input logic clk,  // System clock
    input logic rst_n, // Active low reset

    // CPU write interface
    input logic cpu_we, // Write enable signal
    input logic [2:0] cpu_addr, // Register adress (maps to channel 0-7) (address decoder)
    input logic [3:0] cpu_wdata, // Data to write: bit[3] is mask, bits [2:0] are priority

    // Outputs
    output logic [2:0] reg_priority [8], // 3 bit priority value for each of the 8 channels
    output logic [7:0] reg_mask // 1 bit mask flag for each of the 8 channels
);

    // Internal memory storage: Array of 8 registers, each 4 bits wide.
    // Layout per register: [3] = Mask bit, [2:0] = Priority level.
    logic [3:0] registers [8];  

    // Sequential Logic (D-Flip-Flops): Handling CPU Writes & Reset
    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin
            // Initialization of all registers to zero on reset
            for (int i = 0; i < 8; i++) begin // Unrolling
                registers[i] <= 4'b0000;
            end
    end
    else if (cpu_we) begin // if reset is disabled and write is enable
        // Data is written strictly to the addressed register channel.
        registers[cpu_addr] <= cpu_wdata;
    end
end

// 8*4=32 DFF used

// Combinational Logic: Unpacking and Routing Internal Registers to Outputs
always_comb begin
    for (int i = 0; i < 8; i++) begin // Unrolling
        // Extract bit 3 as the Mask bit for channel i
        reg_mask[i] = registers[i][3];
        // Extract bits 2:0 as the 3-bit Priority level for channel i
        reg_priority[i] = registers[i][2:0];
    end
end

endmodule