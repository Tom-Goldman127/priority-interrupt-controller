`timescale 1ns / 1ps
module pic_top_tb;

    // signal declarations
    logic clk;
    logic rst_n;    
    logic [7:0] ext_intr;
    logic cpu_we;
    logic [2:0] cpu_addr;
    logic [3:0] cpu_wdata;
    logic irq_ack;
    logic irq;
    logic [2:0] intr_id;

    // clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk; // toggle every 5 ns => 10 ns per cycle
    end

    // DUT Instantiation
    pic_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .ext_intr(ext_intr),
        .cpu_addr(cpu_addr),
        .cpu_we(cpu_we),
        .cpu_wdata(cpu_wdata),
        .irq_ack(irq_ack),
        .irq(irq),
        .intr_id(intr_id)
    );

    // initializing all input signals to 0
    initial begin
        rst_n = 1'b1; // active low
        ext_intr = 8'b0;
        cpu_addr = 3'b0;
        cpu_we = 1'b0;
        cpu_wdata = 4'b0;
        irq_ack = 1'b0;
    

    $display(" Starting PIC Simulation ");

    // ========================================
    // Test 1.1: System Reset
    // ========================================
    $display("Running Test 1.1: System Reset");
    rst_n = 1'b0; // reset the system
    #20; // wait for 2 cycles
    rst_n = 1'b1; // release reset
    #10;

    if (irq === 1'b0 && intr_id === 3'b000) begin
        $display("Test 1.1 Passed: System reset successfully");
    end else begin
        $display("Test 1.1 Failed: System did not reset correctly");
    end

    // ========================================
    // Test 1.2: Single Valid Interrupt
    // ========================================
    $display("Running Test 1.2: Single Valid Interrupt");
    cpu_we = 1'b1; // enable write
    cpu_addr = 3'b000; // select channel 0
    cpu_wdata = 4'b0001; // pripority 1, unmasked
    #10;
    cpu_we = 1'b0; // disable write
    // input an external interrupt on channel 0
    ext_intr[0] = 1'b1;
    #40;
    if (irq === 1'b1 && intr_id === 3'b000) begin 
        $display("Single valid interrupt detected successfully");
    end else begin
        $display("Failed to detect single valid interrupt");
    end

    // handshake logic from the CPU
    ext_intr[0] = 1'b0; // release the interrupt
    #40;
    irq_ack = 1'b1; // aclnowledge the interrupt
    #10;
    irq_ack = 1'b0; // clear acknowledge
    #20;
  
    if (irq === 1'b0) begin
        $display("Test 1.2 Passed: Interrupt acknowledged and cleared");
    end else begin
        $display("Test 1.2 Failed: Interrupt not acknowledged and not cleared");
    end

    // ========================================
    // Test 1.3: Masking Logic
    // ========================================
    $display("Running Test 1.3: Masking Logic");
    cpu_we = 1'b1; // enable write
    cpu_addr = 3'b001; // select channel 1
    cpu_wdata = 4'b1010; // pripority 2, masked
    #10;
    cpu_we = 1'b0; // disable write
    ext_intr[1] = 1'b1; // interrupt channel 1
    #40;
    if (irq === 1'b0) begin
        $display("Test 1.3 Passed: Interrupt was successfully masked and ignored");
    end else begin
        $display("Test 1.3 Failed: Interrupt was not ignored");
    end

    ext_intr[1] = 1'b0; // release interrupt channel 1

    // ========================================
    // Test 1.4: Priority Resolution
    // ========================================
    $display("Running Test 1.4: Priority Resolution");
    cpu_we = 1'b1; // enable write
    cpu_addr = 3'b010; // select channel 2
    cpu_wdata = 4'b0101; // pripority 5, unmasked
    #10;
    cpu_we = 1'b0;
    #10;
    cpu_we = 1'b1;
    cpu_addr = 3'b011; // select channel 3
    cpu_wdata = 4'b0111; // pripority 7, unmasked
    #10;
    cpu_we = 1'b0;
    #10;
    // double interrupt
    ext_intr[2] = 1'b1; // interrupt chanel 2
    ext_intr[3] = 1'b1; // interrupt chanel 3
    #40;
    if (irq === 1'b1 && intr_id === 3'b011) begin
        $display("Test 1.4 : Successfully chose the higher priority");
    end else begin
        $display("Test 1.4 Failed: Failed to choose higher priority");
    end
    ext_intr[3] = 1'b0; // the CPU is going to handle the interrupt on chanel 3
    irq_ack = 1'b1; // aclnowledge the interrupt
    #10;
    irq_ack = 1'b0; // clear acknowledge
    #20;
    // now only the lower priority interrupt is active, we should raise the flag again
    if (irq === 1'b1 && intr_id === 3'b010) begin
        $display("Test 1.4 : Successfully raised the flag again");
        $display("Test 1.4 Passed");
    end else begin
        $display("Test 1.4 Failed: Failed to raise the flag for the lower priority interrupt");
    end
    #20;
    ext_intr[2] = 1'b0; // the CPU is going to handle the interrupt on chanel 2
    irq_ack = 1'b1; // aclnowledge the interrupt
    #10;
    irq_ack = 1'b0; // clear acknowledge
    #20;

    // ========================================
    // Test 1.5: Priority Tie Breaker
    // ========================================
    $display("Running Test 1.5: Priority Tie Breaker");
    cpu_we = 1'b1; // enable write
    cpu_addr = 3'b100; // select channel 4
    cpu_wdata = 4'b0100; // pripority 4, unmasked
    #10;
    cpu_we = 1'b0;
    #10;
    cpu_we = 1'b1; // enable write
    cpu_addr = 3'b101; // select channel 5
    cpu_wdata = 4'b0100; // pripority 4, unmasked
    #10;
    cpu_we = 1'b0;
    #10;
    ext_intr[4] = 1'b1; // interrupt chanel 4
    ext_intr[5] = 1'b1; // interrupt chanel 5
    #40;
    // the CPU should defult the lower index
    if (irq === 1'b1 && intr_id === 3'b100) begin 
        $display("Test 1.5 : Successfully resolved the tie");
    end else begin
        $display("Test 1.5 Failed: Failed to resolve the tie");
    end
    #20;
    ext_intr[4] = 1'b0; // taking down channel 4 
    irq_ack = 1'b1; // aclnowledge the interrupt (4)
    #10;
    irq_ack = 1'b0; // clear acknowledge
    #20;
    // now only channel 5 is active, we should raise the flag again
    if (irq === 1'b1 && intr_id === 3'b101) begin
        $display("Test 1.5 : Successfully raised the flag for the tied channel");
        $display("Test 1.5 Passed");
    end else begin
        $display("Test 1.5 Failed: Failed to raise the flag for channel 5");
    end
    
    ext_intr[5] = 1'b0; // taking down channel 5
    irq_ack = 1'b1;     // acknowledge the interrupt (5)
    #10;
    irq_ack = 1'b0;     // clear acknowledge
    #20;
    
    // ========================================
    // Test 1.6: Short Pulse
    // ========================================
    $display("Running Test 1.6: Short Pulse");
    cpu_we = 1'b1;
    cpu_addr = 3'b001; // select channel 1
    cpu_wdata = 4'b0011; // priority 3
    #10;
    cpu_we = 1'b0;
    #10;
    ext_intr[1] = 1'b1; // interrupt channel 1
    #40;
    ext_intr[1] = 1'b0; // taking down the interrupt before we get the ack from the CPU
    #20;
    if (irq === 1'b1 && intr_id === 3'b001) begin
        $display("Test 1.6 : Successfully saved the right intr_id");
    end else begin
        $display("Test 1.6 Failed: Failed to save the right intr_id");
    end
    irq_ack = 1'b1;
    #10;
    irq_ack = 1'b0;
    #20;

    // ========================================
    // Test 1.7: Simultaneous Ack & New irq:
    // ========================================
    $display("Running Test 1.7: Simultaneous Ack & New irq");
    cpu_we = 1'b1;
    cpu_addr = 3'b110; // select channel 6
    cpu_wdata = 4'b0110; // priority 6
    #10;
    cpu_we = 1'b0;
    #10;
    cpu_we = 1'b1; 
    cpu_addr = 3'b111; // select channel 7
    cpu_wdata = 4'b0111; // priority 7
    #10;
    cpu_we = 1'b0; 
    #10;
    ext_intr[6] = 1'b1; // interrupt channel 6
    #40;
    // simultaneous action (all will happen in the same cycle)
    ext_intr[6] = 1'b0; // taking down channel 6 interrupt
    ext_intr[7] = 1'b1; // interrupting channel 7
    irq_ack = 1'b1; // ack from CPU
    #10;
    irq_ack = 1'b0;
    #40; // we allow enough time for interrupt 7 to reach the encoder
    if (irq === 1'b1 && intr_id === 3'b111) begin
        $display("Test 1.7 Passed : Successfully noticed channel 7");
    end else begin
        $display("Test 1.7 Failed: Failed to notice channel 7");
    end
    ext_intr[7] = 1'b0; // taking down channel 7 interrupt
    irq_ack = 1'b1;
    #10;
    irq_ack = 1'b0;
    #20;
    
    // ========================================
    // Test 1.8: CPU Reconfiguration on the fly
    // ========================================
    $display("Running Test 1.8: CPU Reconfiguration on the fly");
    cpu_we = 1'b1;
    cpu_addr = 3'b010; // select channel 2
    cpu_wdata = 4'b0010; // priority 2
    #10;
    cpu_we = 1'b0;
    #10;
    cpu_we = 1'b1;
    cpu_addr = 3'b011; // select channel 3
    cpu_wdata = 4'b0101; // priority 5
    #10;
    cpu_we = 1'b0;
    #10;
    // causing a collision
    ext_intr[2] = 1'b1; // interrupting channel 2
    ext_intr[3] = 1'b1; // interrupting channel 3
    #40; // channel 3 will win because of the higher priority
    // we will write again to channel 2 "on the fly" and give it a higher priority
    cpu_we = 1'b1;
    cpu_addr = 3'b010; // select channel 2
    cpu_wdata = 4'b0111; // priority 7
    #10;
    cpu_we = 1'b0;
    #40;
    if (irq === 1'b1 && intr_id === 3'b010) begin
        $display("Test 1.8 Passed : Successfully reconfigurated");
    end else begin
        $display("Test 1.8 Failed: Failed to reconfigurate");
    end
    ext_intr[2] = 1'b0; 
    ext_intr[3] = 1'b0; 
    irq_ack = 1'b1;
    #10;
    irq_ack = 1'b0;
    #20;

    // ========================================
    // Test 1.9: Two Consecutive Requests
    // ========================================
    $display("Running Test 1.9: Two Consecutive Requests");
    cpu_we = 1'b1;
    cpu_addr = 3'b011; // select channel 3
    cpu_wdata = 4'b0010; // priority 2
    #10;
    cpu_we = 1'b0;
    #10;
    cpu_we = 1'b1; 
    cpu_addr = 3'b111; // select channel 7
    cpu_wdata = 4'b0111; // priority 7
    #10;
    cpu_we = 1'b0; 
    #10;
    ext_intr[3] = 1'b1; // raise channel 3
    #40;
    ext_intr[7] = 1'b1; // raise channel 7 (the overwrite attempt)
    #40;
    // the CPU should not overwrite the id and ack channel 3
    if (irq === 1'b1 && intr_id === 3'b011) begin
        $display("Test 1.9 Passed : Successfully protected channel 3");
    end else begin
        $display("Test 1.9 Failed: Overwrite occurred! Lost channel 3");
    end
    irq_ack = 1'b1;
    ext_intr[3] = 1'b0; 
    ext_intr[7] = 1'b0; 
    #10;
    irq_ack = 1'b0;
    #20;

    $display("All Tests Completed!");
    $stop; 
end

endmodule


