// =============================================================================
// Module Name:    priority_encoder
// Description:    Combinational logic block that evaluates active and unmasked 
//                 interrupts, compares their priority levels, and outputs the 
//                 channel ID of the highest-priority request.
// =============================================================================

module priority_encoder(
    input logic [7:0] sync_intr,
    input logic [7:0] reg_mask,
    input logic [2:0] reg_priority [8],
    output logic valid_irq,
    output logic [2:0] winning_id
);

// Internal signal to hold the current highest priority 
logic [2:0] current_max_pri; 

always_comb begin 
    // Initialize outputs and tracking variables
    valid_irq = 1'b0;
    current_max_pri = 3'b000;
    winning_id = 3'b000;

    // iterate through all channels to find the highest priority active and unmasked interrupt
    for (int i = 0; i < 8; i++) begin
        if (sync_intr[i] == 1'b1 && reg_mask[i] == 1'b0) begin // Check if the interrupt is active and not masked
            if (valid_irq == 1'b0 || reg_priority[i] > current_max_pri) begin // If this is the first valid interrupt or has a higher priority than the current max
                valid_irq = 1'b1; // Set valid_irq to indicate a valid interrupt has been found
                current_max_pri = reg_priority[i]; // Update the highest priority level
                winning_id = i; // Update the corresponding channel ID
            end
        end
    end
end
endmodule