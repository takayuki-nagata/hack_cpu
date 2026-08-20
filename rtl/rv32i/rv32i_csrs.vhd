-- Copyright 2026 Takayuki Nagata All Rights Reserved.
-- RISC-V RV32I Machine-Mode CSRs (Zicsr) & Trap Unit

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.rv32i_types.all;

entity rv32i_csrs is
    Port (
        clk            : in  std_logic;
        reset          : in  std_logic;
        
        -- CSR Read / Write Interface
        csr_addr       : in  std_logic_vector(11 downto 0);
        csr_wdata      : in  std_logic_vector(31 downto 0);
        csr_op         : in  std_logic_vector(2 downto 0);
        csr_rdata      : out std_logic_vector(31 downto 0);
        
        -- Trap & Exception Interface
        trap_entry     : in  std_logic;
        trap_cause     : in  std_logic_vector(31 downto 0);
        trap_pc        : in  std_logic_vector(31 downto 0);
        trap_val       : in  std_logic_vector(31 downto 0);
        trap_return    : in  std_logic; -- MRET
        
        -- Interrupt Inputs
        timer_irq_in   : in  std_logic;
        ext_irq_in     : in  std_logic;
        sw_irq_in      : in  std_logic;
        
        -- System Outputs
        irq_pending    : out std_logic;
        mtvec_out      : out std_logic_vector(31 downto 0);
        mepc_out       : out std_logic_vector(31 downto 0)
    );
end rv32i_csrs;

architecture Behavioral of rv32i_csrs is

    -- CSR Internal Registers
    signal mstatus  : std_logic_vector(31 downto 0) := (others => '0'); -- [3]: MIE, [7]: MPIE
    signal mie      : std_logic_vector(31 downto 0) := (others => '0'); -- [7]: MTIE, [11]: MEIE, [3]: MSIE
    signal mtvec    : std_logic_vector(31 downto 0) := (others => '0');
    signal mscratch : std_logic_vector(31 downto 0) := (others => '0');
    signal mepc     : std_logic_vector(31 downto 0) := (others => '0');
    signal mcause   : std_logic_vector(31 downto 0) := (others => '0');
    signal mtval    : std_logic_vector(31 downto 0) := (others => '0');
    signal mip      : std_logic_vector(31 downto 0) := (others => '0');

    signal read_val : std_logic_vector(31 downto 0);

begin

    -- Output signals
    mtvec_out <= mtvec;
    mepc_out  <= mepc;

    -- Update MIP register from external interrupt lines
    mip(7)  <= timer_irq_in;
    mip(11) <= ext_irq_in;
    mip(3)  <= sw_irq_in;

    -- Interrupt pending check: Global MIE='1' and at least one enabled IRQ pending
    process(mstatus, mie, mip)
        variable global_mie : std_logic;
        variable pending    : std_logic_vector(31 downto 0);
    begin
        global_mie := mstatus(3); -- MIE bit
        pending := mie and mip;
        if global_mie = '1' and (pending(7) = '1' or pending(11) = '1' or pending(3) = '1') then
            irq_pending <= '1';
        else
            irq_pending <= '0';
        end if;
    end process;

    -- CSR Combinational Read Mux
    process(csr_addr, mstatus, mie, mtvec, mscratch, mepc, mcause, mtval, mip)
    begin
        case csr_addr is
            when CSR_MSTATUS   => read_val <= mstatus;
            when CSR_MISA      => read_val <= x"40000100"; -- RV32I (Base 32-bit integer ISA)
            when CSR_MIE       => read_val <= mie;
            when CSR_MTVEC     => read_val <= mtvec;
            when CSR_MSCRATCH  => read_val <= mscratch;
            when CSR_MEPC      => read_val <= mepc;
            when CSR_MCAUSE    => read_val <= mcause;
            when CSR_MTVAL     => read_val <= mtval;
            when CSR_MIP       => read_val <= mip;
            when others        => read_val <= (others => '0');
        end case;
    end process;

    csr_rdata <= read_val;

    -- CSR Synchronous State Update & Trap Handling
    process(clk)
        variable write_val : std_logic_vector(31 downto 0);
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mstatus  <= (others => '0');
                mie      <= (others => '0');
                mtvec    <= (others => '0');
                mscratch <= (others => '0');
                mepc     <= (others => '0');
                mcause   <= (others => '0');
                mtval    <= (others => '0');
            else
                -- 1. Trap Entry Priority (Hardware Interrupt or ECALL/Exception)
                if trap_entry = '1' then
                    mepc       <= trap_pc;
                    mcause     <= trap_cause;
                    mtval      <= trap_val;
                    mstatus(7) <= mstatus(3); -- MPIE <= MIE
                    mstatus(3) <= '0';        -- Disable MIE on trap entry

                -- 2. Trap Exit (MRET Instruction)
                elsif trap_return = '1' then
                    mstatus(3) <= mstatus(7); -- MIE <= MPIE
                    mstatus(7) <= '1';        -- Set MPIE to '1'

                -- 3. Explicit CSR Write Instruction Execution
                elsif csr_op /= "000" then
                    -- Compute Write Value based on CSR Operation
                    case csr_op is
                        when FUNCT3_CSRRW | FUNCT3_CSRRWI =>
                            write_val := csr_wdata;
                        when FUNCT3_CSRRS | FUNCT3_CSRRSI =>
                            write_val := read_val or csr_wdata;
                        when FUNCT3_CSRRC | FUNCT3_CSRRCI =>
                            write_val := read_val and (not csr_wdata);
                        when others =>
                            write_val := read_val;
                    end case;

                    -- Update Target CSR
                    case csr_addr is
                        when CSR_MSTATUS   => mstatus  <= write_val;
                        when CSR_MIE       => mie      <= write_val;
                        when CSR_MTVEC     => mtvec    <= write_val;
                        when CSR_MSCRATCH  => mscratch <= write_val;
                        when CSR_MEPC      => mepc     <= write_val;
                        when CSR_MCAUSE    => mcause   <= write_val;
                        when CSR_MTVAL     => mtval    <= write_val;
                        when others        => null;
                    end case;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
