module sync_register (
    input logic clk, // System clock
    input logic rst_n, // Active low reset
    input logic [7:0] ext_intr, // External interrupt signals (8 channels)
    output logic [7:0] sync_intr // Synchronized interrupt signals
);

// Internal signals (Vectors for synchronization stages)
logic [7:0] sync_ff1;
logic [7:0] sync_ff2;

// Sequential Logic
always_ff @(posedge clk or negedge rst_n) begin
    // On reset, clear the synchronization flip-flops
    if (!rst_n) begin
        sync_ff1 <= 8'b00000000;
        sync_ff2 <= 8'b00000000;
    end
    else begin
        // First stage of synchronization: Capture external interrupts
        sync_ff1 <= ext_intr;
        // Second stage of synchronization: Capture the output of the first stage
        sync_ff2 <= sync_ff1;
    end
end

// Synchronized output is taken from the second stage flip-flop
assign sync_intr = sync_ff2;

endmodule

// 8(bits)*2=16 DFF used, Each goes through 2 stages of synchronization to ensure metastability is mitigated.

    

