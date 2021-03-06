/*
    Copyright (C) 2008 Mans Rullgard

    Permission is hereby granted, free of charge, to any person
    obtaining a copy of this software and associated documentation
    files (the "Software"), to deal in the Software without
    restriction, including without limitation the rights to use, copy,
    modify, merge, publish, distribute, sublicense, and/or sell copies
    of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
    HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.
 */

        .macro mov32    rd, val
        movw            \rd, #:lower16:\val
        movt            \rd, #:upper16:\val
        .endm

        .fpu neon
        .text

@ yuv420_to_yuv422(uint8_t *yuv, uint8_t *y, uint8_t *u, uint8_t *v,
@                  int w, int h, int yw, int cw, int dw)

#define yuv  r0
#define y    r1
#define u    r2
#define v    r3
#define w    r4
#define h    r5
#define yw   r6
#define cw   r7
#define dw   r8

#define tyuv r9
#define ty   r10
#define tu   r11
#define tv   r12
#define i    lr

        .global yuv420_to_yuv422
        .func   yuv420_to_yuv422
yuv420_to_yuv422:
        push            {r4-r11,lr}
        add             r4,  sp,  #36
.Ldo_conv:
        ldm             r4, {r4-r8}
        add             r4,  r4,  #15
        bic             r4,  r4,  #15
        push            {r4}
1:
        mov             tu,   u
        mov             tv,   v
        vld1.64         {d2}, [u,:64], cw               @ u0
        vld1.64         {d3}, [v,:64], cw               @ v0
        mov             tyuv, yuv
        mov             ty,   y
        vzip.8          d2,   d3                        @ u0v0
        mov             i,    #16
2:                      
        pld             [y, #64]
        vld1.64         {d0, d1},   [y,:128], yw        @ y0
        pld             [u, #64]
        subs            i,    i,    #4
        vld1.64         {d6},       [u,:64],  cw        @ u2
        pld             [y, #64]
        vld1.64         {d4, d5},   [y,:128], yw        @ y1
        pld             [v, #64]
        vld1.64         {d7},       [v,:64],  cw        @ v2
        pld             [y, #64]
        vld1.64         {d16,d17},  [y,:128], yw        @ y2
        vzip.8          d6,   d7                        @ u2v2
        pld             [u, #64]
        vld1.64         {d22},      [u,:64],  cw        @ u4
        pld             [v, #64]
        vld1.64         {d23},      [v,:64],  cw        @ v4
        pld             [y, #64]
        vld1.64         {d20,d21},  [y,:128], yw        @ y3
        vmov            q9,   q3                        @ u2v2
        vzip.8          d22,  d23                       @ u4v4
        vrhadd.u8       q3,   q1,   q3                  @ u1v1
        vzip.8          q0,   q1                        @ y0u0y0v0
        vmov            q12,  q11                       @ u4v4
        vzip.8          q2,   q3                        @ y1u1y1v1
        vrhadd.u8       q11,  q9,   q11                 @ u3v3
        vst1.64         {d0-d3},    [yuv,:128], dw      @ y0u0y0v0
        vzip.8          q8,   q9                        @ y2u2y2v2
        vst1.64         {d4-d7},    [yuv,:128], dw      @ y1u1y1v1
        vzip.8          q10,  q11                       @ y3u3y3v3
        vst1.64         {d16-d19},  [yuv,:128], dw      @ y2u2y2v2
        vmov            q1,   q12
        vst1.64         {d20-d23},  [yuv,:128], dw      @ y3u3y3v3
        bgt             2b

        subs            w,    w,    #16
        add             yuv,  tyuv, #32
        add             y,    ty,   #16
        add             u,    tu,   #8
        add             v,    tv,   #8
        bgt             1b

        ldr             w,    [sp]
        subs            h,    h,    #16
        add             yuv,  yuv,  dw, lsl #4
        sub             yuv,  yuv,  w,  lsl #1
        add             y,    y,    yw, lsl #4
        sub             y,    y,    w
        add             u,    u,    cw, lsl #3
        sub             u,    u,    w,  asr #1
        add             v,    v,    cw, lsl #3
        sub             v,    v,    w,  asr #1
        bgt             1b

        pop             {r3-r11,pc}
        .endfunc

        .func   yuv420_to_nv12
yuv420_to_nv12:
        ldm             r4,  {r4-r8}
        add             r4,  r4,  #31
        bic             r4,  r4,  #31
        sub             r6,  r6,  r4
        sub             r7,  r7,  r4,  lsr #1
        sub             r8,  r8,  r4
        mov             r10, r5
1:
        mov             r9,  r4
2:
        pld             [r1, #256]
        vld1.8          {q0-q1},  [r1,:128]!
        vst1.8          {q0-q1},  [r0,:128]!
        subs            r9,  r9,  #32
        bgt             2b
        add             r1,  r1,  r6
        add             r0,  r0,  r8
        subs            r10, r10, #1
        bgt             1b
1:
        lsr             r9,  r4,  #1
2:
        pld             [r2, #256]
        pld             [r3, #256]
        vld1.8          {q0},     [r2,:128]!
        vld1.8          {q1},     [r3,:128]!
        vst2.8          {q0-q1},  [r11,:256]!
        subs            r9,  r9,  #16
        bgt             2b
        add             r2,  r2,  r7
        add             r3,  r3,  r7
        add             r11, r11, r8
        subs            r5,  r5,  #2
        bgt             1b

        pop             {r4-r11,pc}
        .endfunc

        .func   neon_open
neon_open:
        ldr             r2,  [r0, #32]
        ldr             r3,  [r1, #32]
        cmp             r2,  #0                         @ PIX_FMT_YUV420P
        bxne            lr
        cmp             r3,  #1                         @ PIX_FMT_YUYV422
        cmpne           r3,  #25                        @ PIX_FMT_NV12
        mvnne           r0,  #0
        bxne            lr
        push            {r4-r8,lr}
        ldrd            r4,  r5,  [r0, #16]
        ldrd            r6,  r7,  [r0, #24]
        ldr             r8,  [r1, #24]
        mov32           r0,  conv_params
        stm             r0,  {r4-r8}
        cmp             r3,  #1
        adreq           r3,  .Ldo_conv
        adrne           r3,  yuv420_to_nv12
        str             r3,  [r0, #20]
        mov             r0,  #0
        pop             {r4-r8,pc}
        .endfunc

        .func   neon_convert
neon_convert:
        push            {r4-r11,lr}
        ldm             r0,  {r0, r11}
        mov32           r4,  conv_params
        ldm             r1,  {r1-r3}
        ldr             pc,  [r4, #20]
        .endfunc

        .func   neon_nop
neon_nop:
        bx              lr
        .endfunc

        .section .bss
conv_params:
        .skip           6*4
        .size           conv_params, . - conv_params

        .section        .rodata
.Lname: .asciz          "neon"
ofbp_pixconv_neon:
        .word           .Lname
        .word           0               @ flags
        .word           neon_open
        .word           neon_convert
        .word           neon_nop        @ finish
        .word           neon_nop        @ close
        .size           ofbp_pixconv_neon, . - ofbp_pixconv_neon

        .section        .ofbp_pixconv, "a"
ofbp_pixconv_neon_p:
        .word           ofbp_pixconv_neon
