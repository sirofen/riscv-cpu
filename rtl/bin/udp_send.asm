# Constants (Addresses)
# MMIO_UART_ADDR   = 0x10000000
# MMIO_ETH_ADDR    = 0x30000000

# Ethernet Register Offsets
# SELF_MAC_L       = 0x000
# SELF_MAC_H       = 0x004
# SELF_IP          = 0x008
# GATEWAY_IP       = 0x00C
# SEND_DEST_IP     = 0x010
# SEND_SRC_PORT    = 0x014
# SEND_DEST_PORT   = 0x016
# SEND_LENGTH      = 0x018
# SEND_TRIGGER     = 0x01A

# Buffer Addresses
# SEND_BUF         = 0x1000

# UART Register Offsets
# UART_RX_DATA     = 0x00
# UART_TX_DATA     = 0x04
# UART_TX_STATUS   = 0x08
# UART_RX_STATUS   = 0x0C
# UART_TX_BUSY     = 2
# UART_RX_READY    = 1

# Constants (Values)
# IP_ADDR           = 0xC0A8010A
# GATEWAY_IP        = 0xC0A80103
# SEND_DEST_IP      = 0xC0A80103
# SEND_SRC_PORT     = 8080
# SEND_DEST_PORT    = 1234
# MAC_LOW           = 0x63C226D0
# MAC_HIGH          = 0x00B0

# Start of the Program
_start:
    # Initialize base addresses for UART and Ethernet
    lui     s0, 0x10000
    lui     s1, 0x30000

    # Set MAC address
    lui     t0, 0xD063C
    ori     t0, t0, 0x226
    sw      t0, 0(s1)
    ori     t0, zero, 0x0B0
    sw      t0, 4(s1)

    # Set IP addresses and ports
    lui     t0, 0xC0A80
    ori     t0, t0, 0x10A
    sw      t0, 8(s1)
    lui     t0, 0xC0A80
    ori     t0, t0, 0x103
    sw      t0, 0xC(s1)
    sw      t0, 0x10(s1)
    lui     t0, 0x1f90
    srli    t0, t0, 12
    sh      t0, 0x14(s1)
    addi    t0, zero, 1234
    sh      t0, 0x16(s1)

main_loop:
    # Initialize buffer pointer
    lui     t1, 0x30001
    addi    t2, zero, 0

input_loop:
    # Wait for user input and store in buffer
    jal     ra, uart_rx
    addi    t3, zero, 13
    beq     a0, t3, send_data
    jal     ra, uart_tx
    sb      a0, 0(t1)
    addi    t1, t1, 1
    addi    t2, t2, 1
    jal     zero, input_loop

send_data:
    # Trigger sending of data
    sw      t2, 0x18(s1)
    addi    t0, zero, 1
    sw      t0, 0x1A(s1)

    # Send CRLF to UART
    addi    a0, zero, 13
    jal     ra, uart_tx
    addi    a0, zero, 10
    jal     ra, uart_tx

    jal     zero, main_loop

# UART Transmission Function
uart_tx:
    # Check if UART is busy and wait if it is
    lw      t0, 8(s0)
    andi    t0, t0, 2
    bne     t0, zero, uart_tx
    sw      a0, 4(s0)
    jalr    zero, 0(ra)

# UART Reception Function
uart_rx:
    # Wait until data is ready and load received byte
    lw      t0, 8(s0)
    andi    t0, t0, 1
    beq     t0, zero, uart_rx
    lw      a0, 0(s0)
    jalr    zero, 0(ra)
