-- Copyright 2026 Takayuki Nagata All Rights Reserved.
-- RISC-V RV32I Top-Level Single-Cycle CPU Core

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.rv32i_types.all;

entity rv32i_cpu is
    Port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        instr_in    : in  std_logic_vector(31 downto 0);
        data_in     : in  std_logic_vector(31 downto 0);
        pc_out      : out std_logic_vector(31 downto 0);
        data_addr   : out std_logic_vector(31 downto 0);
        data_out    : out std_logic_vector(31 downto 0);
        mem_write   : out std_logic;
        timer_irq_in: in  std_logic := '0';
        ext_irq_in  : in  std_logic := '0';
        sw_irq_in   : in  std_logic := '0'
    );
end rv32i_cpu;

architecture Behavioral of rv32i_cpu is

    component rv32i_decode
        Port (
            instruction : in  std_logic_vector(31 downto 0);
            opcode      : out std_logic_vector(6 downto 0);
            rd          : out std_logic_vector(4 downto 0);
            funct3      : out std_logic_vector(2 downto 0);
            rs1         : out std_logic_vector(4 downto 0);
            rs2         : out std_logic_vector(4 downto 0);
            funct7      : out std_logic_vector(6 downto 0);
            imm         : out std_logic_vector(31 downto 0);
            csr_addr    : out std_logic_vector(11 downto 0);
            uimm        : out std_logic_vector(31 downto 0)
        );
    end component;

    component rv32i_csrs
        Port (
            clk            : in  std_logic;
            reset          : in  std_logic;
            csr_addr       : in  std_logic_vector(11 downto 0);
            csr_wdata      : in  std_logic_vector(31 downto 0);
            csr_op         : in  std_logic_vector(2 downto 0);
            csr_rdata      : out std_logic_vector(31 downto 0);
            trap_entry     : in  std_logic;
            trap_cause     : in  std_logic_vector(31 downto 0);
            trap_pc        : in  std_logic_vector(31 downto 0);
            trap_val       : in  std_logic_vector(31 downto 0);
            trap_return    : in  std_logic;
            timer_irq_in   : in  std_logic;
            ext_irq_in     : in  std_logic;
            sw_irq_in      : in  std_logic;
            irq_pending    : out std_logic;
            mtvec_out      : out std_logic_vector(31 downto 0);
            mepc_out       : out std_logic_vector(31 downto 0)
        );
    end component;

    component rv32i_regfile
        Port (
            clk      : in  std_logic;
            reset    : in  std_logic;
            we       : in  std_logic;
            rs1_addr : in  std_logic_vector(4 downto 0);
            rs2_addr : in  std_logic_vector(4 downto 0);
            rd_addr  : in  std_logic_vector(4 downto 0);
            wr_data  : in  std_logic_vector(31 downto 0);
            rs1_data : out std_logic_vector(31 downto 0);
            rs2_data : out std_logic_vector(31 downto 0)
        );
    end component;

    component rv32i_alu
        Port (
            a       : in  std_logic_vector(31 downto 0);
            b       : in  std_logic_vector(31 downto 0);
            alu_op  : in  std_logic_vector(3 downto 0);
            result  : out std_logic_vector(31 downto 0);
            zero    : out std_logic
        );
    end component;

    -- Signals
    signal pc_reg      : std_logic_vector(31 downto 0) := (others => '0');
    signal next_pc     : std_logic_vector(31 downto 0);

    signal opcode      : std_logic_vector(6 downto 0);
    signal rd          : std_logic_vector(4 downto 0);
    signal funct3      : std_logic_vector(2 downto 0);
    signal rs1         : std_logic_vector(4 downto 0);
    signal rs2         : std_logic_vector(4 downto 0);
    signal funct7      : std_logic_vector(6 downto 0);
    signal imm         : std_logic_vector(31 downto 0);

    signal reg_we      : std_logic;
    signal reg_wr_data : std_logic_vector(31 downto 0);
    signal rs1_data    : std_logic_vector(31 downto 0);
    signal rs2_data    : std_logic_vector(31 downto 0);

    signal alu_operand_a : std_logic_vector(31 downto 0);
    signal alu_operand_b : std_logic_vector(31 downto 0);
    signal alu_ctrl      : std_logic_vector(3 downto 0);
    signal alu_result    : std_logic_vector(31 downto 0);
    signal alu_zero      : std_logic;

    signal branch_take   : std_logic;

    -- CSR & Trap Signals
    signal csr_addr     : std_logic_vector(11 downto 0);
    signal uimm         : std_logic_vector(31 downto 0);
    signal csr_rdata    : std_logic_vector(31 downto 0);
    signal csr_wdata    : std_logic_vector(31 downto 0);
    signal csr_op       : std_logic_vector(2 downto 0);
    signal trap_entry   : std_logic;
    signal trap_cause   : std_logic_vector(31 downto 0);
    signal trap_pc      : std_logic_vector(31 downto 0);
    signal trap_val     : std_logic_vector(31 downto 0);
    signal trap_return  : std_logic;
    signal irq_pending  : std_logic;
    signal mtvec_out    : std_logic_vector(31 downto 0);
    signal mepc_out     : std_logic_vector(31 downto 0);

    signal is_ecall     : std_logic;
    signal is_ebreak    : std_logic;
    signal is_mret      : std_logic;

begin
    pc_out    <= pc_reg;
    data_addr <= alu_result;
    data_out  <= rs2_data;

    -- System instruction decoding
    is_ecall  <= '1' when (opcode = OPCODE_SYSTEM and funct3 = "000" and imm(11 downto 0) = x"000") else '0';
    is_ebreak <= '1' when (opcode = OPCODE_SYSTEM and funct3 = "000" and imm(11 downto 0) = x"001") else '0';
    is_mret   <= '1' when (opcode = OPCODE_SYSTEM and funct3 = "000" and imm(11 downto 0) = x"302") else '0';

    csr_op    <= funct3 when opcode = OPCODE_SYSTEM else "000";
    csr_wdata <= uimm when (funct3 = FUNCT3_CSRRWI or funct3 = FUNCT3_CSRRSI or funct3 = FUNCT3_CSRRCI) else rs1_data;

    trap_entry <= irq_pending or is_ecall or is_ebreak;
    trap_pc    <= pc_reg;
    trap_val   <= x"00000000";
    trap_return<= is_mret;

    process(irq_pending, timer_irq_in, ext_irq_in, sw_irq_in, is_ecall, is_ebreak)
    begin
        if irq_pending = '1' then
            if timer_irq_in = '1' then
                trap_cause <= x"80000007"; -- Machine Timer Interrupt
            elsif ext_irq_in = '1' then
                trap_cause <= x"8000000B"; -- Machine External Interrupt
            elsif sw_irq_in = '1' then
                trap_cause <= x"80000003"; -- Machine Software Interrupt
            else
                trap_cause <= x"80000007";
            end if;
        elsif is_ecall = '1' then
            trap_cause <= x"0000000B"; -- Environment call from M-mode
        elsif is_ebreak = '1' then
            trap_cause <= x"00000003"; -- Breakpoint
        else
            trap_cause <= x"00000000";
        end if;
    end process;

    -- Decoder instantiation
    dec_inst : rv32i_decode
        port map (
            instruction => instr_in,
            opcode      => opcode,
            rd          => rd,
            funct3      => funct3,
            rs1         => rs1,
            rs2         => rs2,
            funct7      => funct7,
            imm         => imm,
            csr_addr    => csr_addr,
            uimm        => uimm
        );

    -- CSR Unit instantiation
    csrs_inst : rv32i_csrs
        port map (
            clk          => clk,
            reset        => reset,
            csr_addr     => csr_addr,
            csr_wdata    => csr_wdata,
            csr_op       => csr_op,
            csr_rdata    => csr_rdata,
            trap_entry   => trap_entry,
            trap_cause   => trap_cause,
            trap_pc      => trap_pc,
            trap_val     => trap_val,
            trap_return  => trap_return,
            timer_irq_in => timer_irq_in,
            ext_irq_in   => ext_irq_in,
            sw_irq_in    => sw_irq_in,
            irq_pending  => irq_pending,
            mtvec_out    => mtvec_out,
            mepc_out     => mepc_out
        );

    -- Register file instantiation
    rf_inst : rv32i_regfile
        port map (
            clk      => clk,
            reset    => reset,
            we       => reg_we,
            rs1_addr => rs1,
            rs2_addr => rs2,
            rd_addr  => rd,
            wr_data  => reg_wr_data,
            rs1_data => rs1_data,
            rs2_data => rs2_data
        );

    -- ALU instantiation
    alu_inst : rv32i_alu
        port map (
            a       => alu_operand_a,
            b       => alu_operand_b,
            alu_op  => alu_ctrl,
            result  => alu_result,
            zero    => alu_zero
        );

    -- ALU Muxes & Control
    process(opcode, funct3, funct7, rs1_data, rs2_data, imm, pc_reg)
    begin
        alu_operand_a <= rs1_data;
        alu_operand_b <= rs2_data;
        alu_ctrl      <= ALU_ADD;

        case opcode is
            when OPCODE_R_TYPE =>
                alu_operand_a <= rs1_data;
                alu_operand_b <= rs2_data;
                case funct3 is
                    when FUNCT3_ADD_SUB =>
                        if funct7(5) = '1' then
                            alu_ctrl <= ALU_SUB;
                        else
                            alu_ctrl <= ALU_ADD;
                        end if;
                    when FUNCT3_SLL  => alu_ctrl <= ALU_SLL;
                    when FUNCT3_SLT  => alu_ctrl <= ALU_SLT;
                    when FUNCT3_SLTU => alu_ctrl <= ALU_SLTU;
                    when FUNCT3_XOR  => alu_ctrl <= ALU_XOR;
                    when FUNCT3_SRL_SRA =>
                        if funct7(5) = '1' then
                            alu_ctrl <= ALU_SRA;
                        else
                            alu_ctrl <= ALU_SRL;
                        end if;
                    when FUNCT3_OR   => alu_ctrl <= ALU_OR;
                    when FUNCT3_AND  => alu_ctrl <= ALU_AND;
                    when others      => alu_ctrl <= ALU_ADD;
                end case;

            when OPCODE_I_TYPE =>
                alu_operand_a <= rs1_data;
                alu_operand_b <= imm;
                case funct3 is
                    when FUNCT3_ADD_SUB => alu_ctrl <= ALU_ADD;
                    when FUNCT3_SLL     => alu_ctrl <= ALU_SLL;
                    when FUNCT3_SLT     => alu_ctrl <= ALU_SLT;
                    when FUNCT3_SLTU    => alu_ctrl <= ALU_SLTU;
                    when FUNCT3_XOR     => alu_ctrl <= ALU_XOR;
                    when FUNCT3_SRL_SRA =>
                        if funct7(5) = '1' then
                            alu_ctrl <= ALU_SRA;
                        else
                            alu_ctrl <= ALU_SRL;
                        end if;
                    when FUNCT3_OR  => alu_ctrl <= ALU_OR;
                    when FUNCT3_AND => alu_ctrl <= ALU_AND;
                    when others     => alu_ctrl <= ALU_ADD;
                end case;

            when OPCODE_LOAD | OPCODE_STORE =>
                alu_operand_a <= rs1_data;
                alu_operand_b <= imm;
                alu_ctrl      <= ALU_ADD;

            when OPCODE_AUIPC =>
                alu_operand_a <= pc_reg;
                alu_operand_b <= imm;
                alu_ctrl      <= ALU_ADD;

            when OPCODE_LUI =>
                alu_operand_a <= x"00000000";
                alu_operand_b <= imm;
                alu_ctrl      <= ALU_COPY_B;

            when OPCODE_BRANCH =>
                alu_operand_a <= rs1_data;
                alu_operand_b <= rs2_data;
                alu_ctrl      <= ALU_SUB;

            when others =>
                alu_operand_a <= rs1_data;
                alu_operand_b <= rs2_data;
                alu_ctrl      <= ALU_ADD;
        end case;
    end process;

    -- Branch condition evaluation
    process(opcode, funct3, alu_zero, rs1_data, rs2_data)
    begin
        branch_take <= '0';
        if opcode = OPCODE_BRANCH then
            case funct3 is
                when FUNCT3_BEQ =>
                    branch_take <= alu_zero;
                when FUNCT3_BNE =>
                    branch_take <= not alu_zero;
                when FUNCT3_BLT =>
                    if signed(rs1_data) < signed(rs2_data) then
                        branch_take <= '1';
                    end if;
                when FUNCT3_BGE =>
                    if signed(rs1_data) >= signed(rs2_data) then
                        branch_take <= '1';
                    end if;
                when FUNCT3_BLTU =>
                    if unsigned(rs1_data) < unsigned(rs2_data) then
                        branch_take <= '1';
                    end if;
                when FUNCT3_BGEU =>
                    if unsigned(rs1_data) >= unsigned(rs2_data) then
                        branch_take <= '1';
                    end if;
                when others =>
                    branch_take <= '0';
            end case;
        end if;
    end process;

    -- Register Write Enable & Data Selection (including sub-word loads)
    process(opcode, funct3, alu_result, data_in, pc_reg)
        variable byte_sel : integer range 0 to 3;
        variable load_val : std_logic_vector(31 downto 0);
    begin
        byte_sel := to_integer(unsigned(alu_result(1 downto 0)));
        case funct3 is
            when "000" => -- LB
                case byte_sel is
                    when 0 => load_val := std_logic_vector(resize(signed(data_in(7 downto 0)), 32));
                    when 1 => load_val := std_logic_vector(resize(signed(data_in(15 downto 8)), 32));
                    when 2 => load_val := std_logic_vector(resize(signed(data_in(23 downto 16)), 32));
                    when 3 => load_val := std_logic_vector(resize(signed(data_in(31 downto 24)), 32));
                end case;
            when "100" => -- LBU
                case byte_sel is
                    when 0 => load_val := x"000000" & data_in(7 downto 0);
                    when 1 => load_val := x"000000" & data_in(15 downto 8);
                    when 2 => load_val := x"000000" & data_in(23 downto 16);
                    when 3 => load_val := x"000000" & data_in(31 downto 24);
                end case;
            when "001" => -- LH
                if alu_result(1) = '0' then
                    load_val := std_logic_vector(resize(signed(data_in(15 downto 0)), 32));
                else
                    load_val := std_logic_vector(resize(signed(data_in(31 downto 16)), 32));
                end if;
            when "101" => -- LHU
                if alu_result(1) = '0' then
                    load_val := x"0000" & data_in(15 downto 0);
                else
                    load_val := x"0000" & data_in(31 downto 16);
                end if;
            when others => -- LW
                load_val := data_in;
        end case;

        case opcode is
            when OPCODE_R_TYPE | OPCODE_I_TYPE | OPCODE_LUI | OPCODE_AUIPC =>
                reg_we      <= '1';
                reg_wr_data <= alu_result;
            when OPCODE_LOAD =>
                reg_we      <= '1';
                reg_wr_data <= load_val;
            when OPCODE_JAL | OPCODE_JALR =>
                reg_we      <= '1';
                reg_wr_data <= std_logic_vector(unsigned(pc_reg) + 4);
            when OPCODE_SYSTEM =>
                if funct3 /= "000" then
                    reg_we      <= '1';
                    reg_wr_data <= csr_rdata;
                else
                    reg_we      <= '0';
                    reg_wr_data <= (others => '0');
                end if;
            when others =>
                reg_we      <= '0';
                reg_wr_data <= (others => '0');
        end case;
    end process;

    -- Memory Write Control
    mem_write <= '1' when opcode = OPCODE_STORE else '0';

    -- Next PC logic (with interrupts, traps, MRET, JAL, JALR, Branch)
    process(pc_reg, opcode, branch_take, imm, rs1_data, alu_result, trap_entry, mtvec_out, is_mret, mepc_out)
    begin
        if trap_entry = '1' then
            next_pc <= mtvec_out;
        elsif is_mret = '1' then
            next_pc <= mepc_out;
        elsif opcode = OPCODE_JAL then
            next_pc <= std_logic_vector(unsigned(pc_reg) + unsigned(imm));
        elsif opcode = OPCODE_JALR then
            next_pc <= std_logic_vector((unsigned(rs1_data) + unsigned(imm)) and x"FFFFFFFE");
        elsif branch_take = '1' then
            next_pc <= std_logic_vector(unsigned(pc_reg) + unsigned(imm));
        else
            next_pc <= std_logic_vector(unsigned(pc_reg) + 4);
        end if;
    end process;

    -- Sequential PC update
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                pc_reg <= (others => '0');
            else
                pc_reg <= next_pc;
            end if;
        end if;
    end process;

end Behavioral;
