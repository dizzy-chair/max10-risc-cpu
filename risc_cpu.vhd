library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- === === === NOTE === === ===
-- This code has been COMMENTED and DOCUMENTED with the help of Artificial
-- Intelligence and was then subject to human revision.

-- Given Prompt: "Please analyze the following set of VHDL files and understand
-- their behavior. Once you have understood what they do, please document the
-- code using comments in the files themselves. Separate components with
-- comments and include a general overview at the top of each file. Read the
-- attached files to understand the 'implicit' or 'architected' parts of the
-- processor."
-- + Attached architecture file
-- + Attached CPU instructions file
-- === === === NOTE === === ===

-- ============================================================
--  Top-level RISC CPU
-- ============================================================
--  Board interface (Terasic DE-series, 50 MHz oscillator):
--    clock_50_mhz  – main 50 MHz clock
--    clear         – asynchronous global reset (active-high)
--    switches      – 8-bit data input from board slide-switches
--    segment_high  – 7-seg display for the high nibble of the
--                    DISP output register (active-low segments)
--    segment_low   – 7-seg display for the low  nibble
--    board_leds    – 8-bit LED output register
--    unused_segs   – remaining 4 seven-segment displays driven
--                    all-off (logic '1' = segment off on common-anode)
--
--  Datapath summary
--  ────────────────
--  1.  clk_div     divides 50 MHz down to CPU_FREQ Hz;
--                  its output is used as a synchronous clock-enable
--                  so only one clock domain (50 MHz) exists on-chip.
--  2.  program_rom contains the instruction program.
--  3.  control_unit decodes each opcode and drives every control line.
--  4.  data_registers holds eight 8-bit general-purpose registers.
--  5.  discrete_alu  performs the selected arithmetic/logic operation.
--  6.  output_reg    latches values to the 7-seg and LED outputs.
--  7.  dec_7seg      converts a 4-bit nibble to 7-segment encoding.
--
--  Components that were stand-alone files in the original design but
--  are simple enough to be inline concurrent statements here:
--    • FullAdder  → pc_plus_1  (numeric_std unsigned addition)
--    • BrEq       → pc_after_beq  (one-line conditional mux)
--    • Increm     → (folded into pc_after_beq logic)
--    • Mux4to1    → alu_in_b, reg_write_data, pc_next  (with/select)
--    • DispOff    → unused_segs <= (others => '1')
-- ============================================================
entity risc_cpu is
    port (
        clock_50_mhz : in  std_logic;
        clear        : in  std_logic;
        switches     : in  std_logic_vector(7 downto 0);
        segment_high : out std_logic_vector(7 downto 0);
        segment_low  : out std_logic_vector(7 downto 0);
        board_leds   : out std_logic_vector(7 downto 0);
        unused_segs  : out std_logic_vector(31 downto 0)   -- 4 extra displays, all off
    );
end risc_cpu;

architecture structural of risc_cpu is

    -- ── Component declarations ────────────────────────────────────

    component clk_div is
        generic (freq_out : natural);
        port (clk_in  : in  std_logic;
              reset   : in  std_logic;
              clk_out : out std_logic);
    end component;

    component program_rom is
        port (addr    : in  std_logic_vector(7 downto 0);
              data_op : out std_logic_vector(3 downto 0);
              data_rs : out std_logic_vector(2 downto 0);
              data_rt : out std_logic_vector(2 downto 0);
              data_rd : out std_logic_vector(2 downto 0);
              data_i  : out std_logic_vector(7 downto 0));
    end component;

    component program_counter is
        port (counter_in  : in  std_logic_vector(7 downto 0);
              clock       : in  std_logic;
              enabled     : in  std_logic;
              reset       : in  std_logic;
              counter_out : out std_logic_vector(7 downto 0));
    end component;

    component control_unit is
        port (operation              : in  std_logic_vector(3 downto 0);
              reg_source_operation   : out std_logic_vector(1 downto 0);
              alu_operation          : out std_logic_vector(2 downto 0);
              write_reg_operation    : out std_logic;
              write_7seg_operation   : out std_logic;
              write_leds_operation   : out std_logic;
              increment_pc_operation : out std_logic;
              beq_operation          : out std_logic;
              jijr_operation         : out std_logic_vector(1 downto 0));
    end component;

    component data_registers is
        port (selector_a  : in  std_logic_vector(2 downto 0);
              selector_b  : in  std_logic_vector(2 downto 0);
              selector_wr : in  std_logic_vector(2 downto 0);
              data_in     : in  std_logic_vector(7 downto 0);
              clock       : in  std_logic;
              enabled     : in  std_logic;
              reset       : in  std_logic;
              signal_we   : in  std_logic;
              output_a    : out std_logic_vector(7 downto 0);
              output_b    : out std_logic_vector(7 downto 0));
    end component;

    component discrete_alu is
        port (input_a   : in  std_logic_vector(7 downto 0);
              input_b   : in  std_logic_vector(7 downto 0);
              operation : in  std_logic_vector(2 downto 0);
              result    : out std_logic_vector(7 downto 0);
              flag_zero : out std_logic);
    end component;

    component output_reg is
        port (data_in  : in  std_logic_vector(7 downto 0);
              clock    : in  std_logic;
              enabled  : in  std_logic;
              write_en : in  std_logic;
              reset    : in  std_logic;
              data_out : out std_logic_vector(7 downto 0));
    end component;

    component dec_7seg is
        port (nibble_in    : in  std_logic_vector(3 downto 0);
              segments_out : out std_logic_vector(7 downto 0));
    end component;

    -- ── Internal signals ─────────────────────────────────────────

    -- Clock
    signal clk_enable    : std_logic;

    -- Program counter
    signal pc_current    : std_logic_vector(7 downto 0);
    signal pc_plus_1     : std_logic_vector(7 downto 0);   -- was FullAdder
    signal pc_after_beq  : std_logic_vector(7 downto 0);   -- was BrEq
    signal pc_next       : std_logic_vector(7 downto 0);   -- final mux (was Mux4to1)

    -- Instruction fields (from ROM)
    signal instr_op  : std_logic_vector(3 downto 0);
    signal instr_rs  : std_logic_vector(2 downto 0);
    signal instr_rt  : std_logic_vector(2 downto 0);
    signal instr_rd  : std_logic_vector(2 downto 0);
    signal instr_imm : std_logic_vector(7 downto 0);

    -- Control signals
    signal ctrl_reg_src    : std_logic_vector(1 downto 0);
    signal ctrl_alu_op     : std_logic_vector(2 downto 0);
    signal ctrl_reg_write  : std_logic;
    signal ctrl_write_7seg : std_logic;
    signal ctrl_write_leds : std_logic;
    signal ctrl_pc_inc     : std_logic;   -- reserved, unused in current ISA
    signal ctrl_beq        : std_logic;
    signal ctrl_jijr       : std_logic_vector(1 downto 0);

    -- Register file
    signal reg_out_a       : std_logic_vector(7 downto 0);
    signal reg_out_b       : std_logic_vector(7 downto 0);
    signal reg_write_data  : std_logic_vector(7 downto 0);  -- was Mux4to1

    -- ALU
    signal alu_in_b        : std_logic_vector(7 downto 0);  -- was Mux4to1
    signal alu_result      : std_logic_vector(7 downto 0);
    signal alu_zero        : std_logic;
    signal beq_taken       : std_logic;

    -- 7-segment data
    signal seg_data        : std_logic_vector(7 downto 0);

begin

    -- ── Clock divider ────────────────────────────────────────────
    -- clk_enable is a single-cycle pulse at CPU_FREQ Hz used as a
    -- synchronous clock-enable for all registered components.
    cpu_clock : clk_div
        generic map (freq_out => 1)   -- 1 Hz for step-by-step observation;
        port map (                    -- increase (e.g. 10 or 100) for faster operation
            clk_in  => clock_50_mhz,
            reset   => clear,
            clk_out => clk_enable
        );

    -- ── Program Counter ──────────────────────────────────────────
    pc : program_counter
        port map (
            counter_in  => pc_next,
            clock       => clock_50_mhz,
            enabled     => clk_enable,
            reset       => clear,
            counter_out => pc_current
        );

    -- PC + 1  (was FullAdder)
    pc_plus_1 <= std_logic_vector(unsigned(pc_current) + 1);

    -- ── Instruction ROM ──────────────────────────────────────────
    rom : program_rom
        port map (
            addr    => pc_current,
            data_op => instr_op,
            data_rs => instr_rs,
            data_rt => instr_rt,
            data_rd => instr_rd,
            data_i  => instr_imm
        );

    -- ── Control Unit ─────────────────────────────────────────────
    ctrl : control_unit
        port map (
            operation              => instr_op,
            reg_source_operation   => ctrl_reg_src,
            alu_operation          => ctrl_alu_op,
            write_reg_operation    => ctrl_reg_write,
            write_7seg_operation   => ctrl_write_7seg,
            write_leds_operation   => ctrl_write_leds,
            increment_pc_operation => ctrl_pc_inc,
            beq_operation          => ctrl_beq,
            jijr_operation         => ctrl_jijr
        );

    -- ── Register File ────────────────────────────────────────────
    -- All register writes address rd; rs and rt are the two read ports.
    regs : data_registers
        port map (
            selector_a  => instr_rs,
            selector_b  => instr_rt,
            selector_wr => instr_rd,
            data_in     => reg_write_data,
            clock       => clock_50_mhz,
            enabled     => clk_enable,
            reset       => clear,
            signal_we   => ctrl_reg_write,
            output_a    => reg_out_a,
            output_b    => reg_out_b
        );

    -- ALU input-B mux  (was Mux4to1, controlled by reg_source_operation)
    --   "00" ADDI  → immediate value
    --   "01" (reserved) → register B
    --   "10" R-type → register B
    --   "11" SW    → switches (don't-care for ALU in this case)
    with ctrl_reg_src select
        alu_in_b <= instr_imm when "00",
                    reg_out_b when "01",
                    reg_out_b when "10",
                    switches  when others;

    -- ── ALU ──────────────────────────────────────────────────────
    alu : discrete_alu
        port map (
            input_a   => reg_out_a,
            input_b   => alu_in_b,
            operation => ctrl_alu_op,
            result    => alu_result,
            flag_zero => alu_zero
        );

    -- Register write-back data mux  (was Mux4to1)
    --   "11" SW instruction: load switches directly into a register.
    --   All other operations write the ALU result.
    with ctrl_reg_src select
        reg_write_data <= alu_result when "00",
                          alu_result when "01",
                          alu_result when "10",
                          switches   when others;

    -- ── Next-PC logic ────────────────────────────────────────────

    -- BEQ branch mux  (was BrEq + Increm)
    --   If the BEQ control line is set AND the ALU zero flag is raised
    --   (meaning rs == rt), jump to the immediate address; otherwise
    --   advance to PC+1.
    beq_taken    <= ctrl_beq and alu_zero;
    pc_after_beq <= instr_imm when beq_taken = '1' else pc_plus_1;

    -- Final next-PC mux  (was Mux4to1, controlled by jijr_operation)
    --   "00" normal / BEQ → pc_after_beq
    --   "01" JR           → rs register value  (jump to register)
    --   "10" JI           → immediate value     (jump to immediate address)
    --   "11" (unused)     → pc_after_beq
    with ctrl_jijr select
        pc_next <= pc_after_beq when "00",
                   reg_out_a    when "01",   -- JR
                   instr_imm    when "10",   -- JI
                   pc_after_beq when others;

    -- ── Output registers and display ─────────────────────────────

    seg_register : output_reg
        port map (
            data_in  => reg_out_a,
            clock    => clock_50_mhz,
            enabled  => clk_enable,
            write_en => ctrl_write_7seg,
            reset    => clear,
            data_out => seg_data
        );

    led_register : output_reg
        port map (
            data_in  => reg_out_a,
            clock    => clock_50_mhz,
            enabled  => clk_enable,
            write_en => ctrl_write_leds,
            reset    => clear,
            data_out => board_leds
        );

    -- 7-segment decoders: high nibble on segment_high, low on segment_low
    seg_hi : dec_7seg
        port map (nibble_in => seg_data(7 downto 4), segments_out => segment_high);

    seg_lo : dec_7seg
        port map (nibble_in => seg_data(3 downto 0), segments_out => segment_low);

    -- Drive remaining four displays off  (was DispOff component)
    -- Common-anode displays: logic '1' turns a segment OFF.
    unused_segs <= (others => '1');

end structural;
