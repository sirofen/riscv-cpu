# UART MMIO Base Address
# 0x100 [7: 0] RX_DATA_REG
# 0x104 [7: 0] TX_DATA_REG
# 0x108 {6'b0, [1: 1] tx_busy, [0: 0] rx_valid}


# initialization and Setup
_start:
    addi s0, zero, 0x100    # UART MMIO
    addi s1, zero, 16       # Store size
    addi s2, zero, 13       # ASCII ('\r')
    addi s3, zero, 10       # ASCII ('\n')
    addi s4, zero, 0        # Main memory Base address

# main loop for receiving data
rx_data:
    addi t2, s4, 0

rx_loop:
    jal  ra, rx_byte_wait

# print back recieved byte
    jal  ra, tx_wait_loop
    jal  ra, tx_byte

    sb   a0, 0(t2)
    addi t2, t2, 1

    beq  a0, s2, tx_data
    bge  t2, s1, tx_data
    jal  zero, rx_loop

# tx data block
tx_data:
    jal ra, tx_crlf

    addi a0, s4, 0
    addi a1, t2, 0
    jal  ra, tx_byte_arr

    jal ra, tx_crlf

    jal  zero, rx_data

# wait for byte input
rx_byte_wait:
    lw   t5, 8(s0)
    andi t5, t5, 1
    beq  t5, zero, rx_byte_wait
    lw   a0, 0(s0)
    jalr zero, 0(ra)

# transmit byte array
tx_byte_arr:
    addi t3, ra, 0
    beq  a1, zero, tx_byte_arr_ret
    addi t4, a0, 0
    add  t5, a0, a1

read_mem_tx_loop:
    lb   a0, 0(t4)
    addi t4, t4, 1
    jal  ra, tx_wait_loop
    jal  ra, tx_byte
    bne  t4, t5, read_mem_tx_loop

tx_byte_arr_ret:
    jalr zero, 0(t3)

tx_byte:
    sw   a0, 4(s0)
    jalr zero, 0(ra)

# TX status check loop
tx_wait_loop:
    lw   t6, 8(s0)
    andi t6, t6, 2
    bne  t6, zero, tx_wait_loop
    jalr zero, 0(ra)

tx_crlf:
    addi t5, ra, 0

    addi a0, s2, 0
    jal ra, tx_wait_loop
    jal  ra, tx_byte

    addi a0, s3, 0
    jal ra, tx_wait_loop
    jal  ra, tx_byte

    jalr zero, 0(t5)
