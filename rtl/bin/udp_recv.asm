# Constants (Addresses)
# MMIO_UART_ADDR   = 0x10000000
# MMIO_GPIO_ADDR   = 0x20000000
# MMIO_ETH_ADDR    = 0x30000000

# Ethernet Register Offsets
# SELF_MAC_L       = 0x000
# SELF_MAC_H       = 0x004
# SELF_IP          = 0x008
# GATEWAY_IP       = 0x00C
# RECV_COMPLETE    = 0x100
# RECV_LENGTH      = 0x110
# RECV_BUF         = 0x2000

# UART Register Offsets
# UART_TX_DATA     = 0x04
# UART_TX_STATUS   = 0x08
# UART_TX_BUSY     = 2

_start:
    # Initialize base address for Ethernet
    lui     s0, 0x30000

    # Initialize MAC, IP, and Gateway
    # Set SELF_MAC_L
    lui     t0, 0xD063C
    ori     t0, t0, 0x226
    sw      t0, 0(s0)

    # Set SELF_MAC_H
    ori     t0, zero, 0x0B0
    sw      t0, 4(s0)

    # Set SELF_IP
    lui     t0, 0xC0A80
    ori     t0, t0, 0x10A
    sw      t0, 8(s0)

    # Set GATEWAY_IP
    lui     t0, 0xC0A80
    ori     t0, t0, 0x103
    sw      t0, 0xC(s0)

main_loop:
    # Check if there is received data
    lw      t0, 0x100(s0)
    beq     t0, zero, main_loop

    # Read the length of received data
    lw      t1, 0x110(s0)

    # If no data, clear RECV_COMPLETE and loop
    beq     t1, zero, clear_recv_complete

    # Read RECV_BUF and send data to UART
    lui     s1, 0x30002  # Base address for RECV_BUF
    add     t3, t1, zero # Copy RECV_LENGTH to t3

send_loop:
    lb      a0, 0(s1)
    jal     ra, uart_tx
    addi    s1, s1, 1
    addi    t3, t3, -1
    bne     t3, zero, send_loop

clear_recv_complete:
    # Clear RECV_COMPLETE
    lui     t0, 0x00000
    sw      t0, 0x100(s0)

    # Loop back to main loop
    jal     zero, main_loop

uart_tx:
    # Transmit byte over UART
    lui     s2, 0x10000
    lw      t0, 0x8(s2)
    andi    t0, t0, 2
    bne     t0, zero, uart_tx
    sw      a0, 0x4(s2)
    jalr    zero, 0(ra)
