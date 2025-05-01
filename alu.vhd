-------------------------------------------------------------------------------
-- Arithmetic Logic Unit
--
-- This is the ALU for a 16-bit RISC processor that performs various operations
-- based on the 4-bit opcode input and sets status flags accordingly.
--
-- Ports:
--   - op [in]  : 4-bit instruction opcode that selects the operation
--   - i1 [in]  : 16-bit operand 1 (typically accumulator)
--   - i2 [in]  : 16-bit operand 2 (register or immediate value)
--   - o  [out] : 16-bit result of the operation
--   - st [out] : 4-bit status flags (Z, N, C, V)
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity alu is
    port (
        op : in std_logic_vector(3 downto 0);   -- Operation code
        i1 : in std_logic_vector(15 downto 0);  -- Input operand 1
        i2 : in std_logic_vector(15 downto 0);  -- Input operand 2
        o  : out std_logic_vector(15 downto 0); -- Output result
        st : out std_logic_vector(3 downto 0)   -- Status flags (Z, N, C, V)
    );
end entity;

architecture arch of alu is
    -- 17-bit result to capture the carry bit (bit 16)
    signal result : std_logic_vector(16 downto 0);
    
    -- Operation type flags to identify operation for status flag calculations
    signal add : std_logic; -- Addition operation flag
    signal sub : std_logic; -- Subtraction operation flag
    signal lsl : std_logic; -- Left shift operation flag
    signal lsr : std_logic; -- Right shift operation flag
begin
    -- Main processing block - selects operation based on opcode
    process (op, i1, i2)
    begin
        -- Initialize operation flags to default state
        sub <= '0';
        add <= '0';
        lsl <= '0';
        lsr <= '0';
        result(16) <= '0'; -- Clear carry bit
        
        -- Operation selection based on opcode
        case (op) is
            -- Logical operations - Only update N and Z flags
            when "0000" => 
                result <= '0' & (i1 and i2);    -- AND operation: result = i1 AND i2
                
            when "0001" => 
                result <= '0' & (i1 or i2);     -- OR operation: result = i1 OR i2
                
            when "0010" => 
                result <= '0' & (i1 xor i2);    -- XOR operation: result = i1 XOR i2
                
            when "0011" => 
                result <= '0' & (not i2);       -- NOT operation: result = NOT i2
            
            -- Arithmetic operations - Update all flags
            when "0100" => 
                -- Addition: result = i1 + i2, set add flag for overflow detection
                result <= std_logic_vector(signed('0' & i1) + signed('0' & i2)); 
                add <= '1';
                
            when "0101" => 
                -- Subtraction: result = i1 - i2, set sub flag for proper carry handling
                result <= std_logic_vector(signed('0' & i1) - signed('0' & i2)); 
                sub <= '1';
            
            -- Shift operations - Special flag handling for shifts
            when "0110" => 
                -- Left shift: i1 shifted left by i2 positions
                result <= std_logic_vector(signed('0' & i1) sll to_integer(signed(i2))); 
                lsl <= '1';
                
            when "0111" => 
                -- Right shift: i1 shifted right by i2 positions
                result <= std_logic_vector(signed('0' & i1) srl to_integer(signed(i2))); 
                lsr <= '1';
            
            -- Data transfer operations - Copy without modifying flags
            when "1000" => 
                result <= '0' & i2;             -- Copy i2 to output (MTA)
                
            when "1001" => 
                result <= '0' & i1;             -- Copy i1 to output (MTR)
                
            when "1010" => 
                result <= '0' & i2;             -- Copy i2 to output (alternate MTA)
                
            when "1011" => 
                result <= '0' & i1;             -- Copy i1 to output (alternate MTR)
            
            -- Additional arithmetic operations without setting operation flags
            -- (Used for operations like CAL, RET where flags are not modified)
            when "1100" => 
                -- Addition without setting add flag
                result <= std_logic_vector(signed('0' & i1) + signed('0' & i2)); 
                
            when "1101" => 
                -- Subtraction without setting sub flag
                result <= std_logic_vector(signed('0' & i1) - signed('0' & i2)); 
            
            -- More data transfer operations
            when "1110" => 
                result <= '0' & i2;             -- Copy i2 to output
                
            when "1111" => 
                result <= '0' & i2;             -- Copy i2 to output
                
            when others => 
                null;                           -- Default case (should not happen)
        end case;
    end process;
    
    -- Output assignment - Take the 16 LSBs of the result
    o <= result(15 downto 0);
    
    -- Status flags calculation
    
    -- Z flag (Zero flag) - Set when result is zero
    -- st(3) is set to '1' when all bits of the result are 0
    st(3) <= '1' when result(15 downto 0) = x"0000" else '0';
    
    -- N flag (Negative flag) - Set when result is negative (MSB is 1)
    -- st(2) is set to '1' when the signed result is less than 0
    st(2) <= '1' when (signed(result(15 downto 0)) < 0) else '0';
    
    -- C flag (Carry flag) - Indicates carry out for addition or no borrow for subtraction
    -- For addition: carry = result(16)
    -- For subtraction: carry = NOT result(16) (inverted to represent borrow correctly)
    st(1) <= not result(16) when sub = '1' else result(16);
    
    -- V flag (Overflow flag) - Set when signed operation produces incorrect sign
    st(0) <= '1' when (
        -- SHIFT OPERATIONS OVERFLOW: 
        -- Set when a shift operation changes the sign of the number
        (((lsl = '1' or lsr = '1') and  -- For left or right shifts
          (
            -- Case 1: Negative number becomes positive after shift
            (signed(i1) < 0 and signed(result(15 downto 0)) > 0) or 
            -- Case 2: Positive number becomes negative after shift
            (signed(i1) > 0 and signed(result(15 downto 0)) < 0)
          ))) or 
        
        -- ADDITION OVERFLOW:
        -- Set when signed addition produces an incorrect sign
        ((add = '1' and 
          (
            -- Case 1: Two negatives add to give a positive (other than zero)
            (signed(result(15 downto 0)) > 0 and signed(i1) < 0 and signed(i2) < 0) or 
            -- Case 2: Two positives add to give a negative
            (signed(result(15 downto 0)) < 0 and signed(i1) > 0 and signed(i2) > 0)
          ))) or 
        
        -- SUBTRACTION OVERFLOW:
        -- Set when signed subtraction produces an incorrect sign
        ((sub = '1' and 
          (
            -- Case 1: Negative minus positive gives positive
            (signed(result(15 downto 0)) > 0 and signed(i1) < 0 and signed(i2) > 0) or 
            -- Case 2: Positive minus negative gives negative
            (signed(result(15 downto 0)) < 0 and signed(i1) > 0 and signed(i2) < 0)
          ))))
        else '0';
end architecture;