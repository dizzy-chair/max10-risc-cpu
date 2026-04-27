library ieee;
use ieee.std_logic_1164.all;

-- Control Unit: decodes a 4-bit opcode and drives every control line.
--
-- Instruction set reference (opcode → mnemonic):
--   0000 ADD  rd, rs, rt     0001 SUB  rd, rs, rt
--   0010 AND  rd, rs, rt     0011 OR   rd, rs, rt
--   0100 XOR  rd, rs, rt     0101 NOT  rd, rs
--   0110 SHL  rd, rs         0111 SHR  rd, rs
--   1000 ADDI rd, rs, imm    1001 (reserved / pass-through)
--   1010 BEQ  rs, rt, imm    1011 JI   imm
--   1100 JR   rs             1101 DISP rs  (write to 7-segment display)
--   1110 LED  rs  (write to LEDs)   1111 SW rd (load switches into register)
--
-- Internal encoding of `ctrl` (12 bits):
--   [11:10] reg_src   [9:7] alu_op   [6] reg_write
--   [5]  write_7seg   [4]  write_leds   [3] increment_pc (unused, held for future use)
--   [2]  beq          [1:0] jijr
entity control_unit is
    port (
        operation              : in  std_logic_vector(3 downto 0);
        reg_source_operation   : out std_logic_vector(1 downto 0);
        alu_operation          : out std_logic_vector(2 downto 0);
        write_reg_operation    : out std_logic;
        write_7seg_operation   : out std_logic;
        write_leds_operation   : out std_logic;
        increment_pc_operation : out std_logic;
        beq_operation          : out std_logic;
        jijr_operation         : out std_logic_vector(1 downto 0)
    );
end control_unit;

architecture behavior of control_unit is
    signal ctrl : std_logic_vector(11 downto 0);
begin

    decode: process(operation)
    begin
        case operation is
            --                   RegSrc ALUOp WR 7S LE Pi BQ JiJr
            when "0000" => ctrl <= "10" & "000" & '1' & '0' & '0' & '0' & '0' & "00";  -- ADD
            when "0001" => ctrl <= "10" & "001" & '1' & '0' & '0' & '0' & '0' & "00";  -- SUB
            when "0010" => ctrl <= "10" & "010" & '1' & '0' & '0' & '0' & '0' & "00";  -- AND
            when "0011" => ctrl <= "10" & "011" & '1' & '0' & '0' & '0' & '0' & "00";  -- OR
            when "0100" => ctrl <= "10" & "100" & '1' & '0' & '0' & '0' & '0' & "00";  -- XOR
            when "0101" => ctrl <= "10" & "101" & '1' & '0' & '0' & '0' & '0' & "00";  -- NOT
            when "0110" => ctrl <= "10" & "110" & '1' & '0' & '0' & '0' & '0' & "00";  -- SHL
            when "0111" => ctrl <= "10" & "111" & '1' & '0' & '0' & '0' & '0' & "00";  -- SHR
            when "1000" => ctrl <= "00" & "000" & '1' & '0' & '0' & '0' & '0' & "00";  -- ADDI (imm as B)
            when "1001" => ctrl <= "01" & "000" & '1' & '0' & '0' & '0' & '0' & "00";  -- reserved
            when "1010" => ctrl <= "00" & "001" & '0' & '0' & '0' & '0' & '1' & "00";  -- BEQ  (SUB to compare)
            when "1011" => ctrl <= "00" & "000" & '0' & '0' & '0' & '0' & '0' & "10";  -- JI
            when "1100" => ctrl <= "00" & "000" & '0' & '0' & '0' & '0' & '0' & "01";  -- JR
            when "1101" => ctrl <= "00" & "000" & '0' & '1' & '0' & '0' & '0' & "00";  -- DISP
            when "1110" => ctrl <= "00" & "000" & '0' & '0' & '1' & '0' & '0' & "00";  -- LED
            when "1111" => ctrl <= "11" & "000" & '1' & '0' & '0' & '0' & '0' & "00";  -- SW (read switches)
            when others => ctrl <= (others => '0');
        end case;
    end process decode;

    reg_source_operation   <= ctrl(11 downto 10);
    alu_operation          <= ctrl(9  downto 7);
    write_reg_operation    <= ctrl(6);
    write_7seg_operation   <= ctrl(5);
    write_leds_operation   <= ctrl(4);
    increment_pc_operation <= ctrl(3);
    beq_operation          <= ctrl(2);
    jijr_operation         <= ctrl(1  downto 0);

end behavior;
