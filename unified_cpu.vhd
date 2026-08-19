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
        active_mode    : out std_logic -- 0: Hack 16-bit, 1: RISC-V 32-bit
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
            imm         : out std_logic_vector(31 downto 0)
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

    -- Hack jump evaluation
    signal hack_jump_take : std_logic;

begin
    active_mode <= is_riscv_mode;
    pc_out      <= pc_reg;

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
            imm         => rv_imm
        );

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

    -- Register Address & Operand Muxing based on Execution Mode
    process(is_riscv_mode, rv_rs1, rv_rs2, rv_rd, h_rs1, h_rs2, h_rd, h_we_reg_a, h_we_reg_d, alu_result, data_in, rv_opcode, rv_imm, h_use_imm, h_imm, h_use_mem, rf_rs1_data, rf_rs2_data, rv_funct3, rv_funct7)
    begin
        if is_riscv_mode = '1' then
            -- RISC-V Mode
            rf_rs1_addr <= rv_rs1;
            rf_rs2_addr <= rv_rs2;
            rf_rd_addr  <= rv_rd;
            
            alu_operand_a <= rf_rs1_data;
            if rv_opcode = OPCODE_I_TYPE or rv_opcode = OPCODE_LOAD or rv_opcode = OPCODE_STORE then
                alu_operand_b <= rv_imm;
            else
                alu_operand_b <= rf_rs2_data;
            end if;

            case rv_opcode is
                when OPCODE_R_TYPE =>
                    if rv_funct3 = FUNCT3_ADD_SUB and rv_funct7(5) = '1' then
                        alu_ctrl <= ALU_SUB;
                    else
                        alu_ctrl <= ALU_ADD;
                    end if;
                when OPCODE_I_TYPE => alu_ctrl <= ALU_ADD;
                when others        => alu_ctrl <= ALU_ADD;
            end case;

            rf_we       <= '1';
            rf_wr_data  <= alu_result;
            mem_write   <= '1' when rv_opcode = OPCODE_STORE else '0';
            data_addr   <= alu_result;
            data_out    <= rf_rs2_data;

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
            data_addr  <= rf_rs2_data; -- Memory address is A (x1)
            data_out   <= alu_result;
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

    -- Next PC Logic
    process(pc_reg, is_riscv_mode, hack_jump_take, rf_rs2_data)
    begin
        if is_riscv_mode = '1' then
            next_pc <= std_logic_vector(unsigned(pc_reg) + 4);
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
