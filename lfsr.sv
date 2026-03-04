// LFSR generator
// This function is useful in both encoder and decoder
module lfsr #(parameter N=4)(
  input               clk,
                      reset,		  // active low
  input       [  1:0] load,           // [1]: lfsr_data = seed_mask; [0]: tap_ptrn = seed_mask
  input       [N-1:0] seed_mask,      // initial state or tap pattern
  output logic[N-1:0] lfsr_data,	  // current state
  output logic        lfsr_done);	  // current state = initial state set by load[1]

  // define local vars; feedback bit, local data, tap pattern, start
  logic feedback_bit;
  logic [N-1:0] lfsr_reg;
  logic [N-1:0] tap_ptrn;
  logic [N-1:0] start_seed;

  // set equal local register and output data
  assign lfsr_data = lfsr_reg;

  // define all taps as a function, from 2 - 8 bits
  function automatic logic [N-1:0] tap_ptrns(input int n);
    case(n)
      2: return 2'b11;
      3: return 3'b110;
      4: return 4'b1100;
      5: return 5'b10100;
      6: return 6'b110000;
      7: return 7'b1100000;
      8: return 8'b10111000;
      default: return {N{1'b1}};
    endcase
  endfunction

  // xor operation on tap pattern to get feedback bit
  always_comb begin
    feedback_bit = 1'b0;
    for (int i = 0; i < N; i++) begin
      if (tap_ptrn[i]) begin
        feedback_bit = feedback_bit ^ lfsr_reg[i];
      end
    end
  end

// on clock signal
  always_ff @(posedge clk) begin
    
    // check reset and change all vals to 1, get tap pattern
    if (!reset) begin
      lfsr_reg     <= {N{1'b1}};
      tap_ptrn  <= tap_ptrns(N);
      start_seed   <= {N{1'b1}};
      lfsr_done    <= 1'b0;
    end

    // if first, load seed value
    else if (load[1]) begin
      lfsr_reg     <= seed_mask;
      start_seed   <= seed_mask;
      lfsr_done    <= 1'b0;
    end
    // get tap pattern and load
    else if (load[0]) begin
      tap_ptrn  <= seed_mask;
      lfsr_done    <= 1'b0;
    end
    // otherwise shift register left and get place lsb feedback bit
    else begin
      lfsr_reg <= {lfsr_reg[N-2:0], feedback_bit};

      // check for full cycle completion, set done high
      if ({lfsr_reg[N-2:0], feedback_bit} == start_seed) begin
        lfsr_done <= 1'b1;
      end
    end
  end

endmodule