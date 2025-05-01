library ieee;                                     -- Import IEEE library
use ieee.std_logic_1164.all;                      -- Use standard logic package for basic logic types

-- Entity declaration defines the interface of the control unit
entity control is
	port (
		clk : in std_logic;                   -- Clock signal input
		rst : in std_logic;                   -- Reset signal input
		status : in std_logic_vector(3 downto 0); -- Status register input (4 bits)
		instr_cond : in std_logic_vector(3 downto 0); -- Condition bits from instruction
		instr_op : in std_logic_vector(3 downto 0);   -- Operation code from instruction
		instr_updt : in std_logic;            -- Status update flag from instruction
		instr_ce : out std_logic;             -- Instruction register clock enable
		status_ce : out std_logic;            -- Status register clock enable
		acc_ce : out std_logic;               -- Accumulator register clock enable
		pc_ce : out std_logic;                -- Program counter clock enable
		rpc_ce : out std_logic;               -- Return program counter clock enable
		rx_ce : out std_logic;                -- Index register clock enable
		ram_we : out std_logic;               -- RAM write enable
		sel_ram_addr : out std_logic;         -- Select RAM address source
		sel_op1 : out std_logic;              -- Select operand 1 source
		sel_rf_din : out std_logic_vector(1 downto 0) -- Select register file data input
	);
end entity;

architecture arch of control is
	-- Define the states of the control unit's state machine
	type etat is (fetch1, fetch2, decode, exec, store);
	signal next_state: etat;                      -- Next state signal 
	signal etat_courant: etat := fetch1;          -- Current state signal with initial value

	-- Function to verify if instruction should be executed based on condition and status
	function verif(instr_cond : std_logic_vector(3 downto 0); status : std_logic_vector(3 downto 0))
        return std_logic is
	begin
  		case (instr_cond) is
			when "0000" => return '0';           -- Always false
			when "0001" => return '1';           -- Always true
			when "0010" => return (status(3));   -- Negative flag
			when "0011" => return (not(status(3))); -- Not negative
			when "0100" => return (not(status(3)) and not(status(2))); -- Zero nor negative (positive)
			when "0101" => return (status(3) or status(2)); -- Negative or zero
			when "0110" => return (status(2));   -- Zero flag
			when "0111" => return (not(status(2))); -- Not zero
			when "1000" => return (status(1));   -- Carry flag
			when "1001" => return (not(status(1))); -- Not carry
			when "1010" => return (status(0));   -- Overflow flag
			when "1011" => return (not(status(0))); -- Not overflow
			when others => return '1';           -- Default case returns true
		end case;
	end verif;
begin
	-- Next state logic - defines the state transitions
	next_state <= fetch2 when etat_courant = fetch1 else -- From fetch1 to fetch2
	           decode when etat_courant = fetch2 else    -- From fetch2 to decode
	           exec when etat_courant = decode else      -- From decode to exec
	           store when etat_courant = exec else       -- From exec to store
	           fetch1 when etat_courant = store else     -- From store back to fetch1
	           etat_courant;                             -- Default: stay in current state

	-- Process p1: Combinational logic for control signals based on current state
	p1 : process(etat_courant, instr_op, instr_cond, status, instr_updt)
	begin
		-- Default values for all control signals (avoid latches)
		instr_ce <= '0';
		status_ce <= '0';
		acc_ce <= '0';
		pc_ce <= '0';
		rpc_ce <= '0';
		rx_ce <= '0';
		ram_we <= '0';
		sel_ram_addr <= '0';
		sel_op1 <= '0'; 
		sel_rf_din <= "00";
		
		-- State machine implementation
		case etat_courant is
			when fetch1 =>  -- First fetch state: setup for instruction fetch
					instr_ce <= '0';     -- Disable instruction register
					status_ce <= '0';    -- Disable status register
					acc_ce <= '0';       -- Disable accumulator
					pc_ce <= '0';        -- Disable program counter
					rpc_ce <= '0';       -- Disable return program counter
					rx_ce <= '0';        -- Disable index register
					ram_we <= '0';       -- Disable RAM write
					sel_ram_addr <= '0'; -- Select PC as RAM address
					sel_op1 <= '0';      -- Select accumulator as operand 1
					sel_rf_din <= "00";  -- Select ALU output for register file
					
			when fetch2 =>  -- Second fetch state: load instruction
					instr_ce <= '1';     -- Enable instruction register to load
					status_ce <= '0';    -- Keep status register disabled
					acc_ce <= '0';       -- Keep accumulator disabled
					pc_ce <= '0';        -- Keep program counter disabled
					rpc_ce <= '0';       -- Keep return program counter disabled
					rx_ce <= '0';        -- Keep index register disabled
					ram_we <= '0';       -- Keep RAM write disabled
					sel_ram_addr <= '0'; -- Keep selecting PC as RAM address
					sel_op1 <= '0';      -- Keep selecting accumulator as operand 1
					sel_rf_din <= "00";  -- Keep selecting ALU output for register file
					
			when decode =>  -- Decode state: determine what to do based on instruction
					if(verif(instr_cond, status) = '0') then -- If condition is false
						-- Keep all signals disabled (instruction not executed)
						instr_ce <= '0';
						status_ce <= '0';
						acc_ce <= '0';
						pc_ce <= '0';
						rpc_ce <= '0';
						rx_ce <= '0';
						ram_we <= '0';
						sel_ram_addr <= '0';
						sel_op1 <= '0'; 
						sel_rf_din <= "00";
					elsif(instr_op(3 downto 2) = "11") then -- Jump/branch instructions
						instr_ce <= '0';     -- Keep instruction register disabled
						status_ce <= '0';    -- Keep status register disabled
						acc_ce <= '0';       -- Keep accumulator disabled
						pc_ce <= '0';        -- Keep program counter disabled
						rpc_ce <= '0';       -- Keep return program counter disabled
						rx_ce <= '0';        -- Keep index register disabled
						ram_we <= '0';       -- Keep RAM write disabled
						sel_ram_addr <= '0'; -- Keep selecting PC as RAM address
						sel_op1 <= '1';      -- Select immediate value as operand 1
						sel_rf_din <= "00";  -- Keep selecting ALU output for register file
					else                     -- Other instructions
						-- Keep all signals disabled (preparing for execution)
						instr_ce <= '0';
						status_ce <= '0';
						acc_ce <= '0';
						pc_ce <= '0';
						rpc_ce <= '0';
						rx_ce <= '0';
						ram_we <= '0';
						sel_ram_addr <= '0';
						sel_op1 <= '0'; 
						sel_rf_din <= "00";
					end if;
					
			when exec => -- Execute state: perform the operation
				if(verif(instr_cond, status) = '0') then -- If condition is false
					-- Only increment PC, skip instruction execution
					instr_ce <= '0';     -- Keep instruction register disabled
					status_ce <= '0';    -- Keep status register disabled
					acc_ce <= '0';       -- Keep accumulator disabled
					pc_ce <= '1';        -- Enable program counter to increment
					rpc_ce <= '0';       -- Keep return program counter disabled
					rx_ce <= '0';        -- Keep index register disabled
					ram_we <= '0';       -- Keep RAM write disabled
					sel_ram_addr <= '0'; -- Keep selecting PC as RAM address
					sel_op1 <= '0';      -- Keep selecting accumulator as operand 1
					sel_rf_din <= "10";  -- Select PC+1 for register file
				else                     -- If condition is true
					-- Default setup for most instructions
					status_ce <= instr_updt; -- Update status if needed
					acc_ce <= '0';       -- Keep accumulator disabled
					instr_ce <= '0';     -- Keep instruction register disabled
					rpc_ce <= '0';       -- Keep return program counter disabled
					rx_ce <= '0';        -- Keep index register disabled
					ram_we <= '0';       -- Keep RAM write disabled
					sel_ram_addr <= '0'; -- Keep selecting PC as RAM address
					sel_op1 <= '0';      -- Keep selecting accumulator as operand 1
					sel_rf_din <="10";   -- Select PC+1 for register file
					pc_ce <= '1';        -- Enable program counter to increment
					
					-- Instruction-specific settings
					if (instr_op = "1000") then -- LOAD instruction
						status_ce <= '0';    -- Don't update status
						sel_ram_addr <= '1'; -- Select address from instruction
					elsif (instr_op = "1001") then -- STORE instruction
						status_ce <= '0';    -- Don't update status
						sel_ram_addr <= '1'; -- Select address from instruction
						ram_we <= '1';       -- Enable RAM write
					elsif (instr_op = "1111") then -- RET instruction (return)
						status_ce <= '0';    -- Don't update status
						pc_ce <= '0';        -- Don't increment PC
						rpc_ce <= '1';       -- Enable return PC (for jump)
					elsif (instr_op = "1100" or instr_op ="1101" or instr_op ="1110") then -- Jump instructions
						status_ce <= '0';    -- Don't update status
					end if;
				end if;
				
			when store => -- Store state: save results of operation
				if (verif(instr_cond, status) = '0') then -- If condition is false
					-- Keep all signals disabled (instruction skipped)
					instr_ce <= '0';
					status_ce <= '0';
					acc_ce <= '0';
					pc_ce <= '0';
					rpc_ce <= '0';
					rx_ce <= '0';
					ram_we <= '0';
					sel_ram_addr <= '0';
					sel_op1 <= '0'; 
					sel_rf_din <= "00";
				else                     -- If condition is true
					-- Default setup for most instructions
					status_ce <= '0';    -- Keep status register disabled
					acc_ce <= '1';       -- Enable accumulator to store result
					instr_ce <= '0';     -- Keep instruction register disabled
					rpc_ce <= '0';       -- Keep return program counter disabled
					rx_ce <= '0';        -- Keep index register disabled
					ram_we <= '0';       -- Keep RAM write disabled
					sel_ram_addr <= '0'; -- Keep selecting PC as RAM address
					sel_op1 <= '0';      -- Keep selecting accumulator as operand 1
					sel_rf_din <="00";   -- Select ALU output for register file
					pc_ce <= '0';        -- Keep program counter disabled
					
					-- Instruction-specific settings
					if (instr_op(3 downto 2) = "11") then -- Jump/branch instructions
						pc_ce <= '1';        -- Enable program counter (for jump)
						acc_ce <= '0';       -- Don't update accumulator
					elsif (instr_op = "1011") then -- MOV RX,ACC instruction
						rx_ce <= '1';        -- Enable index register to store
						acc_ce <= '0';       -- Don't update accumulator
					elsif (instr_op = "1001") then -- STORE instruction
						acc_ce <= '0';       -- Don't update accumulator
					elsif (instr_op = "1000") then -- LOAD instruction
						sel_rf_din <="01";   -- Select RAM data for register file
					end if;
				end if;
		end case;
	end process p1;
	
	-- Process p2: Sequential logic for state transitions
	p2 : process (clk, rst)
	begin
		if (rst = '1') then              -- Asynchronous reset
			etat_courant <= fetch1;      -- Reset to initial state
		elsif (clk'event and clk = '1') then -- Rising clock edge
			etat_courant <= next_state;  -- Update current state
		end if;
	end process p2;
end architecture;