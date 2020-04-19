#
# @author:Don Dennis
# machinecodeconst.py
#
# Constants and variable declaring various
# machine instructions


class MachineCodeConst:
    # Definition of opcodes used in assembly language instructions
    INSTR_LUI = 'lui'
    INSTR_AUIPC = 'auipc'
    INSTR_JAL = 'jal'
    INSTR_JALR = 'jalr'
    INSTR_BEQ = 'beq'
    INSTR_BNE = 'bne'
    INSTR_BLT = 'blt'
    INSTR_BGE = 'bge'
    INSTR_BLTU = 'bltu'
    INSTR_BGEU = 'bgeu'
    INSTR_LB = 'lb'
    INSTR_LH = 'lh'
    INSTR_LW = 'lw'
    INSTR_LBU = 'lbu'
    INSTR_LHU = 'lhu'
    INSTR_SB = 'sb'
    INSTR_SH = 'sh'
    INSTR_SW = 'sw'
    INSTR_ADDI = 'addi'
    INSTR_SLTI = 'slti'
    INSTR_SLTIU = 'sltiu'
    INSTR_XORI = 'xori'
    INSTR_ORI = 'ori'
    INSTR_ANDI = 'andi'
    INSTR_SLLI = 'slli'
    INSTR_SRLI = 'srli'
    INSTR_SRAI = 'srai'
    INSTR_ADD = 'add'
    INSTR_SUB = 'sub'
    INSTR_SLL = 'sll'
    INSTR_SLT = 'slt'
    INSTR_SLTU = 'sltu'
    INSTR_XOR = 'xor'
    INSTR_SRL = 'srl'
    INSTR_SRA = 'sra'
    INSTR_OR = 'or'
    INSTR_AND = 'and'
    #*********************Instructions added by Nikola Kovacevic**********************

    # INTEGER ARITHMETIC INSTRUCTIONS
    VV_INSTR_ADD = 'vadd'
    VX_INSTR_ADD = 'vadd'
    VI_INSTR_ADD = 'vadd'    
    VV_INSTR_SUB = 'vsub'
    VX_INSTR_SUB = 'vsub'
    VI_INSTR_SUB = 'vsub'
    VV_INSTR_OR = 'vor'
    VX_INSTR_OR = 'vor'
    VI_INSTR_OR = 'vor'
    VV_INSTR_XOR = 'vxor'
    VX_INSTR_XOR = 'vxor'
    VI_INSTR_XOR = 'vxor'
    VV_INSTR_AND = 'vand'
    VX_INSTR_AND = 'vand'
    VI_INSTR_AND = 'vand'
    # INTEGER REDUCTION ARITHMETIC INSTRUCTIONS
    # TODO
    # FLOATING POINT ARITHMETIC INSTRUCTIONS
    # TODO

        
    ##vector-vector instruction
    VV_INSTR_TYPE_I = [VV_INSTR_ADD, VV_INSTR_SUB, VV_INSTR_XOR,
                       VV_INSTR_OR, VV_INSTR_AND]
    ##vector-scalar instruction
    VX_INSTR_TYPE_I = [VX_INSTR_ADD, VX_INSTR_SUB, VX_INSTR_XOR,
                       VX_INSTR_OR, VX_INSTR_AND]
    ##vector-mask instruction
    VI_INSTR_TYPE_I = [VI_INSTR_ADD, VI_INSTR_SUB, VI_INSTR_XOR,
                       VI_INSTR_OR, VI_INSTR_AND]

    V_INTEGER_INSTRUCTIONS = VV_INSTR_TYPE_I + VI_INSTR_TYPE_I + VX_INSTR_TYPE_I    
    """****************** VECTOR LOAD INSTRUCTION OPCODES *************************"""

    
    #UNIT stride unsigned load (mop = 000)
    # (8bit, 16bit, 32bit and SEW respectively)
    V_UNIT_STRIDE_ZE_LOAD = ['vlbu', 'vlhu', 'vlwu', 'vleu']
    
    #Unit stride signed load(mop = 100)
    # (8bit, 16bit, 32bit and SEW respectively)
    V_UNIT_STRIDE_SE_LOAD = ['vlb', 'vlh', 'vlw', 'vle']


    #STRIDED unsigned load (mop = 010)
    # (8bit, 16bit, 32bit and SEW respectively)
    V_STRIDE_ZE_LOAD = ['vlsbu', 'vlshu', 'vlswu', 'vlseu']        

    #STRIDED signed load (mop = 110)
    # (8bit, 16bit, 32bit and SEW respectively)
    V_STRIDE_SE_LOAD = ['vlsb', 'vlsh', 'vlsw', 'vlse']        


    #INDEX unsigned load (mop = 011)
    # (8bit, 16bit, 32bit and SEW respectively)
    V_INDEXED_ZE_LOAD = ['vlXbu', 'vlXhu', 'vlXwu', 'vlXeu']

    #INDEX signed load (mop = 111)
    # (8bit, 16bit, 32bit and SEW respectively)
    V_INDEXED_SE_LOAD = ['vlXb', 'vlXh', 'vlXw', 'vlXe']    

    ALL_V_LOAD_OPCODES = V_UNIT_STRIDE_ZE_LOAD + V_UNIT_STRIDE_SE_LOAD + V_STRIDE_ZE_LOAD + V_STRIDE_SE_LOAD + V_INDEXED_SE_LOAD + V_INDEXED_ZE_LOAD
    

    """***************** VECTOR STORE INSTRUCTION OPCODES ***************************"""
    
    #UNIT stride store (mop = 000)
    # (8bit, 16bit and 32 bit respectively)
    V_UNIT_STRIDE_STORE = ['vsb', 'vsh', 'vsw', 'vse']
    
    #STRIDED store (mop = 010)
    # (8bit, 16bit and 32 bit respectively)
    V_STRIDE_STORE = ['vssb', 'vssh', 'vssw', 'vsse']        

    #INDEXED store (mop = 011)
    # (8bit, 16bit and 32 bit respectively)
    V_INDEXED_STORE = ['vsXb', 'vsXh', 'vsXw', 'vsXe']


    ALL_V_STORE_OPCODES = V_UNIT_STRIDE_STORE + V_STRIDE_STORE + V_INDEXED_STORE    


    ALL_V_Ld_St_unit_stride_instr = V_UNIT_STRIDE_STORE + V_UNIT_STRIDE_ZE_LOAD + V_UNIT_STRIDE_SE_LOAD
    ALL_V_Ld_St_stride_instr = V_STRIDE_STORE + V_STRIDE_ZE_LOAD + V_STRIDE_SE_LOAD
    ALL_V_Ld_St_INDEXED_instr = V_INDEXED_STORE + V_INDEXED_ZE_LOAD + V_INDEXED_SE_LOAD
    

    #******************************************************************************

    
    # All reserved opcodes
    ALL_INSTR = [INSTR_LUI, INSTR_AUIPC, INSTR_JAL,
                 INSTR_JALR, INSTR_BEQ, INSTR_BNE, INSTR_BLT,
                 INSTR_BGE, INSTR_BLTU, INSTR_BGEU, INSTR_LB,
                 INSTR_LH, INSTR_LW, INSTR_LBU, INSTR_LHU,
                 INSTR_SB, INSTR_SH, INSTR_SW, INSTR_ADDI,
                 INSTR_SLTI, INSTR_SLTIU, INSTR_XORI,
                 INSTR_ORI, INSTR_ANDI, INSTR_SLLI,
                 INSTR_SRLI, INSTR_SRAI, INSTR_ADD,
                 INSTR_SUB, INSTR_SLL, INSTR_SLT,
                 INSTR_SLTU, INSTR_XOR, INSTR_SRL,
                 INSTR_SRA, INSTR_OR, INSTR_AND] + V_INTEGER_INSTRUCTIONS + ALL_V_STORE_OPCODES + ALL_V_LOAD_OPCODES
    # All instruction in a type
    INSTR_TYPE_U = [INSTR_LUI, INSTR_AUIPC]
    INSTR_TYPE_UJ = [INSTR_JAL]
    INSTR_TYPE_S = [INSTR_SW, INSTR_SB, INSTR_SH]
    INSTR_TYPE_SB = [INSTR_BEQ, INSTR_BNE, INSTR_BLT,
                     INSTR_BLTU, INSTR_BGE, INSTR_BGEU]
    INSTR_TYPE_I = [INSTR_ADDI, INSTR_SLTI, INSTR_SLTIU,
                    INSTR_ORI, INSTR_XORI, INSTR_ANDI,
                    INSTR_SLLI, INSTR_SRLI, INSTR_SRAI,
                    INSTR_JALR, INSTR_LW, INSTR_LB,
                    INSTR_LH, INSTR_LBU, INSTR_LHU]
    INSTR_TYPE_R = [INSTR_ADD, INSTR_SUB, INSTR_SLL,
                    INSTR_SLT, INSTR_SLTU, INSTR_XOR,
                    INSTR_SRL, INSTR_SRA, INSTR_OR, INSTR_AND]
    
    
    #*********************Instructions added by Nikola Kovacevic*******************

    
    
    #******************************************************************************


    
    # Binary Opcodes
    BOP_LUI = '0110111'
    BOP_AUIPC = '0010111'
    BOP_JAL = '1101111'
    BOP_JALR = '1100111'
    BOP_BRANCH = '1100011'
    BOP_LOAD = '0000011'
    BOP_STORE = '0100011'
    BOP_ARITHI = '0010011'
    BOP_ARITH = '0110011'
    # Not supported
    # [FENCE, FENCE.I]
    BOP_MISCMEM = '0001111'
    # [ ECALL, EBREAK, CSRRW, CSRRS, cSRRC, CSRRWI, CSRRSI, CSRRCI]
    BOP_SYSTEM = '1110011'
    #*********************BINARY opcodes added by Nikola Kovacevic*******************
    #Vector Arith opcode
    V_BOP_ARITH = '1010111'
    V_BOP_LOAD = '0000111'
    V_BOP_STORE = '0100111'

    
    #******************************************************************************
    # The instruction in each distinct binary opcode
    INSTR_BOP_LUI = [INSTR_LUI]
    INSTR_BOP_AUIPC = [INSTR_AUIPC]
    INSTR_BOP_JAL = [INSTR_JAL]
    INSTR_BOP_JALR = [INSTR_JALR]
    INSTR_BOP_BRANCH = [INSTR_BEQ, INSTR_BNE, INSTR_BLT,
                        INSTR_BLTU, INSTR_BGE, INSTR_BGEU]
    INSTR_BOP_LOAD = [INSTR_LW, INSTR_LB,
                      INSTR_LH, INSTR_LBU, INSTR_LHU]
    INSTR_BOP_STORE = [INSTR_SW, INSTR_SB, INSTR_SH]
    INSTR_BOP_ARITHI = [INSTR_ADDI, INSTR_SLTI, INSTR_SLTIU,
                        INSTR_ORI, INSTR_XORI, INSTR_ANDI,
                        INSTR_SLLI, INSTR_SRLI, INSTR_SRAI]
    INSTR_BOP_ARITH = [INSTR_ADD, INSTR_SUB, INSTR_SLL,
                       INSTR_SLT, INSTR_SLTU, INSTR_XOR,
                       INSTR_SRL, INSTR_SRA, INSTR_OR, INSTR_AND]
    
    #*********************Instruction added by Nikola Kovacevic*******************
    #Vector Arith opcode
    V_INSTR_BOP_ARITH = VV_INSTR_TYPE_I + VX_INSTR_TYPE_I + VI_INSTR_TYPE_I
    #******************************************************************************
    # FUNCT for each instruction type
    FUNCT3_ARITHI = {
        INSTR_ADDI: '000',
        INSTR_SLTI: '010',
        INSTR_SLTIU: '011',
        INSTR_ORI: '110',
        INSTR_XORI: '100',
        INSTR_ANDI: '111',
        INSTR_SLLI: '001',
        INSTR_SRLI: '101',
        INSTR_SRAI: '101'
    }

    FUNCT3_JALR = {
        INSTR_JALR: '000'
    }
    
    FUNCT3_LOAD = {
        INSTR_LB: '000',
        INSTR_LH: '001',
        INSTR_LW: '010',
        INSTR_LBU: '100',
        INSTR_LHU: '101'
    }
    FUNCT3_ARITH = {
        INSTR_ADD: '000',
        INSTR_SUB: '000',
        INSTR_SLL: '001',
        INSTR_SLT: '010',
        INSTR_SLTU: '011',
        INSTR_XOR: '100',
        INSTR_SRL: '101',
        INSTR_SRA: '101',
        INSTR_OR: '110',
        INSTR_AND: '111'
    }

    #*********************FUNCT3 added by Nikola Kovacevic*******************
    FUNCT3_V_ARITH_INTEGER = {
        '.vv': '000',
        '.vi': '011',
        '.vx': '100',
    }

    FUNCT3_V_ARITH_FP = {
        '.vv': '001',
        '.vf': '101',
    }
    FUNCT3_V_ARITH_INTEGER_REDUCTION = {
        '.vv': '010',
        '.vs': '110',
    }

    FUNCT6_V_ARITH_INTEGER = {
        'vadd': '000000',
        'vsub': '000010',        
        'vxor': '001011',
        'vor': '001010',
        'vand': '001001'
        #... To be implemented
    }

    #*********************CONSTANTS added by Nikola Kovacevic*************************
    #constants needed for vector loads/stores
    """Vector_load_mop"""
    load_store_width = {
        'vlbu': '000',
        'vlhu': '101',
        'vlwu': '110',
        'vleu': '111',
        'vlb': '000',
        'vlh': '101',
        'vlw': '110',
        'vle': '111',
        'vlsbu': '000',
        'vlshu': '101',
        'vlswu': '110',
        'vlseu': '111',
        'vlsb': '000',
        'vlsh': '101',
        'vlsw': '110',
        'vlse': '111',
        'vlXbu': '000',
        'vlXhu': '101',
        'vlXwu': '110',
        'vlXeu': '111',
        'vlXb': '000',
        'vlXh': '101',
        'vlXw': '110',
        'vlXe': '111',
        'vsb': '000',
        'vsh': '101',
        'vsw': '110',
        'vse': '111',
        'vssb': '000',
        'vssh': '101',
        'vssw': '110',
        'vsse': '111',
        'vsXb': '000',
        'vsXh': '101',
        'vsXw': '110',
        'vsXe': '111'
    }
    
    #*********************************************************************************

    FUNCT7_ARITH = {
        INSTR_ADD: '0000000',
        INSTR_SUB: '0100000',
        INSTR_SLL: '0000000',
        INSTR_SLT: '0000000',
        INSTR_SLTU: '0000000',
        INSTR_XOR: '0000000',
        INSTR_SRL: '0000000',
        INSTR_SRA: '0100000',
        INSTR_OR: '0000000',
        INSTR_AND: '0000000'
    }

    FUNCT3_STORE = {
        INSTR_SB: '000',
        INSTR_SH: '001',
        INSTR_SW: '010'
    }

    FUNCT3_BRANCH = {
        INSTR_BEQ: '000',
        INSTR_BNE: '001',
        INSTR_BLT: '100',
        INSTR_BGE: '101',
        INSTR_BLTU: '110',
        INSTR_BGEU: '111'
    }
