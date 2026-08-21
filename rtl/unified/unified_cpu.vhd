-- Copyright 2026 Takayuki Nagata All Rights Reserved.
-- Unified CPU Core with First-Instruction Auto Mode Detection & Micro-Op Translation

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.rv32i_types.all;

entity unified_cpu is
    Port (
        clk            : in  std_logic;
        reset          : in  std_logic;
        instr_in       : in  std_logic_vector(31 downto 0);
        data_in        : in  std_logic_vector(31 downto 0);
        pc_out         : out std_logic_vector(31 downto 0);
        data_addr      : out std_logic_vector(31 downto 0);
        data_out       : out std_logic_vector(31 downto 0);
        mem_write      : out std_logic;
        active_mode    : out std_logic; -- 0: Hack 16-bit, 1: RISC-V 32-bit
        timer_irq_in   : in  std_logic := '0';
        ext_irq_in     : in  std_logic := '0';
        sw_irq_in      : in  std_logic := '0'
    );
end unified_cpu;

architecture Behavioral of unified_cpu is

    component auto_mode_detector
        Port (
            clk           : in  std_logic;
            reset         : in  std_logic;
            first_instr   : in  std_logic_vector(31 downto 0);
            is_riscv_mode : out std_logic
        );
    end component;

    component hack_translator
        Port (
            instr_16     : in  std_logic_vector(15 downto 0);
            rs1          : out std_logic_vector(4 downto 0);
            rs2          : out std_logic_vector(4 downto 0);
            rd           : out std_logic_vector(4 downto 0);
            imm          : out std_logic_vector(31 downto 0);
            alu_op       : out std_logic_vector(3 downto 0);
            use_imm      : out std_logic;
            use_mem      : out std_logic;
            we_reg_a     : out std_logic;
            we_reg_d     : out std_logic;
            we_mem       : out std_logic;
            jump_cond    : out std_logic_vector(2 downto 0);
            is_c_instr   : out std_logic
        );
    end component;

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

    -- Architecture Signals
    signal is_riscv_mode : std_logic;
    signal pc_reg        : std_logic_vector(31 downto 0) := (others => '0');
    signal next_pc       : std_logic_vector(31 downto 0);

    -- Hack Translator signals
    signal h_rs1        : std_logic_vector(4 downto 0);
    signal h_rs2        : std_logic_vector(4 downto 0);
    signal h_rd         : std_logic_vector(4 downto 0);
    signal h_imm        : std_logic_vector(31 downto 0);
    signal h_alu_op     : std_logic_vector(3 downto 0);
    signal h_use_imm    : std_logic;
    signal h_use_mem    : std_logic;
    signal h_we_reg_a   : std_logic;
    signal h_we_reg_d   : std_logic;
    signal h_we_mem     : std_logic;
    signal h_jump_cond  : std_logic_vector(2 downto 0);
    signal h_is_c_instr : std_logic;

    -- RV32I Decoder signals
    signal rv_opcode    : std_logic_vector(6 downto 0);
    signal rv_rd        : std_logic_vector(4 downto 0);
    signal rv_funct3    : std_logic_vector(2 downto 0);
    signal rv_rs1       : std_logic_vector(4 downto 0);
    signal rv_rs2       : std_logic_vector(4 downto 0);
    signal rv_funct7    : std_logic_vector(6 downto 0);
    signal rv_imm       : std_logic_vector(31 downto 0);
    signal rv_csr_addr  : std_logic_vector(11 downto 0);
    signal rv_uimm      : std_logic_vector(31 downto 0);

    -- Register file control signals
    signal rf_rs1_addr  : std_logic_vector(4 downto 0);
    signal rf_rs2_addr  : std_logic_vector(4 downto 0);
    signal rf_rd_addr   : std_logic_vector(4 downto 0);
    signal rf_we        : std_logic;
    signal rf_wr_data   : std_logic_vector(31 downto 0);
    signal rf_rs1_data  : std_logic_vector(31 downto 0);
    signal rf_rs2_data  : std_logic_vector(31 downto 0);

    -- ALU Signals
    signal alu_operand_a: std_logic_vector(31 downto 0);
    signal alu_operand_b: std_logic_vector(31 downto 0);
    signal alu_ctrl     : std_logic_vector(3 downto 0);
    signal alu_result   : std_logic_vector(31 downto 0);
    signal alu_zero     : std_logic;

    -- CSR & Trap Signals
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

    -- RISC-V Branch Evaluation
    signal rv_branch_take : std_logic;

    -- Hack jump evaluation
    signal hack_jump_take : std_logic;

begin
    active_mode <= is_riscv_mode;
    pc_out      <= pc_reg;
    data_addr   <= alu_result when is_riscv_mode = '1' else rf_rs2_data;
    data_out    <= rf_rs2_data when is_riscv_mode = '1' else alu_result;

    -- Auto Mode Detector
    mode_det : auto_mode_detector
        port map (
            clk           => clk,
            reset         => reset,
            first_instr   => instr_in,
            is_riscv_mode => is_riscv_mode
        );

    -- Hack Translator (front-end for 16-bit instructions)
    hack_trans : hack_translator
        port map (
            instr_16   => instr_in(15 downto 0),
            rs1        => h_rs1,
            rs2        => h_rs2,
            rd         => h_rd,
            imm        => h_imm,
            alu_op     => h_alu_op,
            use_imm    => h_use_imm,
            use_mem    => h_use_mem,
            we_reg_a   => h_we_reg_a,
            we_reg_d   => h_we_reg_d,
            we_mem     => h_we_mem,
            jump_cond  => h_jump_cond,
            is_c_instr => h_is_c_instr
        );

    -- RISC-V Decoder (front-end for 32-bit instructions)
    rv_dec : rv32i_decode
        port map (
            instruction => instr_in,
            opcode      => rv_opcode,
            rd          => rv_rd,
            funct3      => rv_funct3,
            rs1         => rv_rs1,
            rs2         => rv_rs2,
            funct7      => rv_funct7,
            imm         => rv_imm,
            csr_addr    => rv_csr_addr,
            uimm        => rv_uimm
        );

    -- CSRs & Trap Unit
    csrs_inst : rv32i_csrs
        port map (
            clk          => clk,
            reset        => reset,
            csr_addr     => rv_csr_addr,
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

    -- System instruction decoding
    is_ecall  <= '1' when (is_riscv_mode = '1' and rv_opcode = OPCODE_SYSTEM and rv_funct3 = FUNCT3_PRIV and rv_csr_addr = x"000") else '0';
    is_ebreak <= '1' when (is_riscv_mode = '1' and rv_opcode = OPCODE_SYSTEM and rv_funct3 = FUNCT3_PRIV and rv_csr_addr = x"001") else '0';
    is_mret   <= '1' when (is_riscv_mode = '1' and rv_opcode = OPCODE_SYSTEM and rv_funct3 = FUNCT3_PRIV and rv_csr_addr = x"302") else '0';

    csr_op    <= rv_funct3 when (is_riscv_mode = '1' and rv_opcode = OPCODE_SYSTEM) else "000";
    csr_wdata <= rv_uimm when (rv_funct3 = FUNCT3_CSRRWI or rv_funct3 = FUNCT3_CSRRSI or rv_funct3 = FUNCT3_CSRRCI) else rf_rs1_data;

    trap_entry <= irq_pending or is_ecall or is_ebreak when is_riscv_mode = '1' else '0';
    trap_pc    <= pc_reg;
    trap_val   <= (others => '0');
    trap_return<= is_mret when is_riscv_mode = '1' else '0';

    process(irq_pending, timer_irq_in, ext_irq_in, sw_irq_in, is_ecall, is_ebreak)
    begin
        if irq_pending = '1' then
            if timer_irq_in = '1' then
                trap_cause <= x"80000007";
            elsif ext_irq_in = '1' then
                trap_cause <= x"8000000B";
            elsif sw_irq_in = '1' then
                trap_cause <= x"80000003";
            else
                trap_cause <= x"80000007";
            end if;
        elsif is_ecall = '1' then
            trap_cause <= x"0000000B";
        elsif is_ebreak = '1' then
            trap_cause <= x"00000003";
        else
            trap_cause <= (others => '0');
        end if;
    end process;

    -- Register File
    reg_file : rv32i_regfile
        port map (
            clk      => clk,
            reset    => reset,
            we       => rf_we,
            rs1_addr => rf_rs1_addr,
            rs2_addr => rf_rs2_addr,
            rd_addr  => rf_rd_addr,
            wr_data  => rf_wr_data,
            rs1_data => rf_rs1_data,
            rs2_data => rf_rs2_data
        );

    -- ALU
    main_alu : rv32i_alu
        port map (
            a       => alu_operand_a,
            b       => alu_operand_b,
            alu_op  => alu_ctrl,
            result  => alu_result,
            zero    => alu_zero
        );

    -- RISC-V Branch Evaluation
    process(rv_opcode, rv_funct3, alu_zero, rf_rs1_data, rf_rs2_data)
    begin
        rv_branch_take <= '0';
        if rv_opcode = OPCODE_BRANCH then
            case rv_funct3 is
                when FUNCT3_BEQ  => rv_branch_take <= alu_zero;
                when FUNCT3_BNE  => rv_branch_take <= not alu_zero;
                when FUNCT3_BLT  => if signed(rf_rs1_data) < signed(rf_rs2_data) then rv_branch_take <= '1'; end if;
                when FUNCT3_BGE  => if signed(rf_rs1_data) >= signed(rf_rs2_data) then rv_branch_take <= '1'; end if;
                when FUNCT3_BLTU => if unsigned(rf_rs1_data) < unsigned(rf_rs2_data) then rv_branch_take <= '1'; end if;
                when FUNCT3_BGEU => if unsigned(rf_rs1_data) >= unsigned(rf_rs2_data) then rv_branch_take <= '1'; end if;
                when others      => rv_branch_take <= '0';
            end case;
        end if;
    end process;

    -- Hack Jump Evaluation
    process(h_jump_cond, alu_zero, alu_result)
        variable is_neg : boolean;
    begin
        is_neg := (alu_result(31) = '1');
        hack_jump_take <= '0';

        if h_jump_cond(0) = '1' and is_neg then
            hack_jump_take <= '1';
        elsif h_jump_cond(1) = '1' and alu_zero = '1' then
            hack_jump_take <= '1';
        elsif h_jump_cond(2) = '1' and (not is_neg) and (alu_zero = '0') then
            hack_jump_take <= '1';
        end if;
    end process;

    -- Register Address & Operand Muxing based on Execution Mode
    process(is_riscv_mode, rv_rs1, rv_rs2, rv_rd, h_rs1, h_rs2, h_rd, h_we_reg_a, h_we_reg_d, alu_result, data_in, rv_opcode, rv_imm, h_use_imm, h_imm, h_use_mem, rf_rs1_data, rf_rs2_data, rv_funct3, rv_funct7, pc_reg, csr_rdata)
        variable byte_sel : integer range 0 to 3;
        variable load_val : std_logic_vector(31 downto 0);
    begin
        if is_riscv_mode = '1' then
            -- RISC-V Mode
            rf_rs1_addr <= rv_rs1;
            rf_rs2_addr <= rv_rs2;
            rf_rd_addr  <= rv_rd;
            
            -- ALU Operand Selection
            case rv_opcode is
                when OPCODE_AUIPC =>
                    alu_operand_a <= pc_reg;
                    alu_operand_b <= rv_imm;
                    alu_ctrl      <= ALU_ADD;
                when OPCODE_LUI =>
                    alu_operand_a <= x"00000000";
                    alu_operand_b <= rv_imm;
                    alu_ctrl      <= ALU_COPY_B;
                when OPCODE_I_TYPE | OPCODE_LOAD | OPCODE_STORE | OPCODE_JALR =>
                    alu_operand_a <= rf_rs1_data;
                    alu_operand_b <= rv_imm;
                    alu_ctrl      <= ALU_ADD;
                when OPCODE_R_TYPE =>
                    alu_operand_a <= rf_rs1_data;
                    alu_operand_b <= rf_rs2_data;
                    case rv_funct3 is
                        when FUNCT3_ADD_SUB =>
                            if rv_funct7(5) = '1' then alu_ctrl <= ALU_SUB; else alu_ctrl <= ALU_ADD; end if;
                        when FUNCT3_SLL     => alu_ctrl <= ALU_SLL;
                        when FUNCT3_SLT     => alu_ctrl <= ALU_SLT;
                        when FUNCT3_SLTU    => alu_ctrl <= ALU_SLTU;
                        when FUNCT3_XOR     => alu_ctrl <= ALU_XOR;
                        when FUNCT3_SRL_SRA =>
                            if rv_funct7(5) = '1' then alu_ctrl <= ALU_SRA; else alu_ctrl <= ALU_SRL; end if;
                        when FUNCT3_OR      => alu_ctrl <= ALU_OR;
                        when FUNCT3_AND     => alu_ctrl <= ALU_AND;
                        when others         => alu_ctrl <= ALU_ADD;
                    end case;
                when OPCODE_BRANCH =>
                    alu_operand_a <= rf_rs1_data;
                    alu_operand_b <= rf_rs2_data;
                    alu_ctrl      <= ALU_SUB;
                when others =>
                    alu_operand_a <= rf_rs1_data;
                    alu_operand_b <= rf_rs2_data;
                    alu_ctrl      <= ALU_ADD;
            end case;

            -- Sub-word Load Steering
            byte_sel := to_integer(unsigned(alu_result(1 downto 0)));
            case rv_funct3 is
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

            -- Writeback & Memory Write
            case rv_opcode is
                when OPCODE_R_TYPE | OPCODE_I_TYPE | OPCODE_LUI | OPCODE_AUIPC =>
                    rf_we       <= '1';
                    rf_wr_data  <= alu_result;
                when OPCODE_LOAD =>
                    rf_we       <= '1';
                    rf_wr_data  <= load_val;
                when OPCODE_JAL | OPCODE_JALR =>
                    rf_we       <= '1';
                    rf_wr_data  <= std_logic_vector(unsigned(pc_reg) + 4);
                when OPCODE_SYSTEM =>
                    if rv_funct3 /= FUNCT3_PRIV then
                        rf_we       <= '1';
                        rf_wr_data  <= csr_rdata;
                    else
                        rf_we       <= '0';
                        rf_wr_data  <= (others => '0');
                    end if;
                when others =>
                    rf_we       <= '0';
                    rf_wr_data  <= (others => '0');
            end case;

            mem_write <= '1' when rv_opcode = OPCODE_STORE else '0';

        else
            -- Hack Mode (16-bit Translation Mode)
            rf_rs1_addr <= h_rs1; -- x2 (D)
            rf_rs2_addr <= h_rs2; -- x1 (A)
            
            if h_we_reg_a = '1' then
                rf_rd_addr <= "00001"; -- x1 (A)
                rf_we      <= '1';
            elsif h_we_reg_d = '1' then
                rf_rd_addr <= "00010"; -- x2 (D)
                rf_we      <= '1';
            else
                rf_rd_addr <= "00000";
                rf_we      <= '0';
            end if;

            alu_operand_a <= rf_rs1_data; -- D
            if h_use_imm = '1' then
                alu_operand_b <= h_imm;
            elsif h_use_mem = '1' then
                alu_operand_b <= data_in;
            else
                alu_operand_b <= rf_rs2_data; -- A
            end if;

            alu_ctrl   <= h_alu_op;
            rf_wr_data <= alu_result;
            mem_write  <= h_we_mem;
        end if;
    end process;

    -- Next PC Logic
    process(pc_reg, is_riscv_mode, rv_opcode, rv_branch_take, rv_imm, rf_rs1_data, hack_jump_take, rf_rs2_data, trap_entry, mtvec_out, is_mret, mepc_out)
    begin
        if is_riscv_mode = '1' then
            if trap_entry = '1' then
                next_pc <= mtvec_out;
            elsif is_mret = '1' then
                next_pc <= mepc_out;
            elsif rv_opcode = OPCODE_JAL then
                next_pc <= std_logic_vector(unsigned(pc_reg) + unsigned(rv_imm));
            elsif rv_opcode = OPCODE_JALR then
                next_pc <= std_logic_vector((unsigned(rf_rs1_data) + unsigned(rv_imm)) and x"FFFFFFFE");
            elsif rv_branch_take = '1' then
                next_pc <= std_logic_vector(unsigned(pc_reg) + unsigned(rv_imm));
            else
                next_pc <= std_logic_vector(unsigned(pc_reg) + 4);
            end if;
        else
            if hack_jump_take = '1' then
                next_pc <= rf_rs2_data; -- Jump to A (x1)
            else
                next_pc <= std_logic_vector(unsigned(pc_reg) + 2);
            end if;
        end if;
    end process;

    -- PC Update
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
