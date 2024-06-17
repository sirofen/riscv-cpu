# LED 0x200 [3:0]
_start:
    lui s3, zero, 0x20000
    lui  s4, 0x1000
    addi  s2, zero, 15

loop_0:
    xori  s2, s2, 15

loop_1:
    addi t0, zero, 0
delay_loop:
    addi t0, t0, 1
    bne  t0, s4, delay_loop

    sw   s2, 0(s3)
    jal  zero, loop_0
