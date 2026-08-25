module pic_top (
    input logic clk,
    input logic rst_n,
    input logic [7:0] ext_intr, // External interrupt signals (8 channels)
    input logic cpu_we, // Write enable signal for CPU configuration
    input logic [2:0] cpu_addr, // Register address for CPU configuration (maps to channel 0-7)
    input logic [3:0] cpu_wdata, // Data to write: bit[3] is mask, bits [2:0] are priority
    input logic irq_ack, // Interrupt acknowledge signal from the CPU
    output logic irq, // Interrupt request signal (flag) to the CPU
    output logic [2:0] intr_id // Interrupt ID output to the CPU (indicates which channel is active)   
);

// Internal signals
logic [7:0] sync_intr; // Synchronized interrupt signals from the sync_register module
logic [2:0] reg_priority [8]; // Priority levels from the config_regs module
logic [7:0] reg_mask; // Mask bits from the config_regs module
logic valid_irq; // Indicates if there is a valid interrupt request 
logic [2:0] next_id; // signal to hold the right id that would be sent to the CPU (Register)

// Instansiation
sync_register my_sync_register (
    .clk(clk),
    .rst_n(rst_n),
    .ext_intr(ext_intr),
    .sync_intr(sync_intr)
);

config_regs my_config_regs (
    .clk(clk),
    .rst_n(rst_n),
    .cpu_addr(cpu_addr),
    .cpu_we(cpu_we),
    .cpu_wdata(cpu_wdata),
    .reg_mask(reg_mask),
    .reg_priority(reg_priority)
);

priority_encoder my_priority_encoder ( 
    // We neglect the clk and rst_n because this is a combinational block
    .reg_mask(reg_mask),
    .reg_priority(reg_priority),
    .sync_intr(sync_intr),
    .valid_irq(valid_irq),
    .winning_id(next_id)   // Output the winning interrupt ID to the CPU
);

// Sequential logic for generating the interrupt request signal (flag)
always_ff @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin // Reset clears the flag
        irq <= 1'b0;
        intr_id <= 3'b000;
    end else if (irq_ack) begin // When the cpu acknowledged a signal we clear the flag
        irq <= 1'b0;
    end else if (valid_irq == 1 && irq == 0) begin // If there is a valid interrupt request and there is none already waiting, we set the flag
        irq <= 1'b1;
        intr_id <= next_id;
    end   
end

endmodule
