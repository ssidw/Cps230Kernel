;CpS 230 Example Program: DOSBox Text Mode framebuffer demo
; (c) 2016, BJU
;------------------------------------------------------------
bits 16

org 0x100

; CpR equ 80  ; 80 characters per row
; RpS equ 25  ; 25 rows per screen
; BpC equ 2   ; 2 bytes per character
PpR equ 320 ; 320 pixels per row/scanline
RpS equ 200 ; 200 rows per screen/framebuffer
ITERATIONS  equ 200


; Compute starting offset to store "BJU!" in VRAM centered on row 12
; MESSAGE_START   equ (12 * CpR * BpC) + (((CpR - (CHARS / 2)) / 2) * BpC)

section .text
start:
    ; Set VGA graphics mode (320x200x8-bit)
    mov ah, 0
    mov al, 0x13
    int 0x10

.palcycle:
    ; Select starting color (DI) for VGA palette transformation
    ; (Color transforms "wrap" around, so if we start at color
    ; 200, the first 56 colors in the table will go in palette
    ; slots 200-255, then the remaining 200 will go in 0-199...)
    mov dx, 0x3C8   ; "starting color" port
    mov ax, di
    xor ah, ah
    out dx, al
    
    ; Blast the color table out to the VGA registers
    mov cx, 256
    mov dx, 0x3C9   ; "R/G/B data" port
    mov si, palette ; source = palette array
.palloop:
    lodsb
    out dx, al      ; Red
    lodsb
    out dx, al      ; Green
    lodsb
    out dx, al      ; Blue
    loop    .palloop

    ; Set up ES to be our framebuffer segment
    mov ax, 0xA000
    mov es, ax
    ; mov ax, 0xb800
    ; mov es, ax
    
    ; Clear screen to black (copy 80*25*2 byte of ZERO to the framebuffer)
    ; mov al, 0
    ; mov cx, CpR*RpS*BpC
    ; mov di, 0
    ; rep stosb
    ; Clear screen to black (copy 320*200 byte of ZERO to the framebuffer)
    mov al, 0
    mov cx, PpR*RpS
    mov di, 0
    rep stosb
    

    mov cx, 0
.compare_row:
    cmp cx, RpS
    jge .end_comp_row
    ;Save cx for after inner loop
    push cx
    mov cx, 0


.compare_col:
    cmp cx, PpR
    jge .end_comp_col

    ;Get current row value into bx and save again
    pop bx
    push bx

    mov word[iteration], 0
    fld dword[zero]
    fst dword[x]
    fst dword[x0]
    fst dword[y0]
    fstp dword[y]

    mov [temp_col], cx
    fild word [temp_col]
    fsub dword [width_adj]
    fmul dword [const_four]
    fdiv dword [width]
    fstp dword [x0]

    mov [temp_row], bx
    fild word [temp_row]
    fsub dword [height_adj]
    fmul dword [const_four]
    fdiv dword [width]
    fstp dword [y0]

.float_comp:
    fld dword[x]
    fmul dword[x]
    fstp dword[x2]
    fld dword[y]
    fmul dword[y]
    fstp dword[y2]
    fld dword[x2]
    fld dword[y2]
    faddp
    fld dword[const_four]


    fcomp
    fnstsw word [status_word]
    ; fstp dword[junk]
    mov ax, [status_word]
    mov di, 17664
    and ax, di
    cmp ax, 0

    je .loopy
    mov ax, [status_word]
    and ax, 16384
    cmp ax, 16384
    jne .end_crazy_pls
.loopy:
    cmp word [iteration], ITERATIONS
    jge .end_crazy_pls
    fld dword[x2]
    fld dword[y2]
    fsub
    fld dword[x0]
    fadd
    fst dword[new_x]

    fld dword[const_two]
    fld dword[x]
    fmul
    fld dword[y]
    fmul
    fld dword[y0]
    fadd
    fst dword[y]
    fld dword[new_x]
    fst dword[x]
    inc word[iteration]

    jmp .float_comp

.end_crazy_pls:
    cmp word[iteration], ITERATIONS
    jge .end_of_all
    ;320*row + col

;     mov di, 0
;     mov [temp], cx
; .compare_test:
;     cmp di, 2
;     jge .end_test

;     mov ax, [temp]
;     mov si, 10
;     xor dx, dx
;     div si
;     mov [temp], ax
;     add dx, 48
;     mov ah, 2
;     int 0x21

;     inc di
;     jmp .compare_test

; .end_test:
;     mov dx, 13
;     mov ah, 2
;     int 0x21

;     mov dx, 10
;     mov ah, 2
;     int 0x21


    mov ax, 320
    imul bx
    push ax
    mov ax, cx
    ; mov si, 2
    ; imul si
    pop dx
    add ax, dx

    ; mov di, ax
    ; mov ah, 0xFF
    ; mov al, 0
    ; stosw
    push bx
    mov bx, ax
    mov ax, [iteration]
    mov byte[es:bx], al
    pop bx
    jmp .end_of_all
.end_of_all:
    inc cx
    jmp .compare_col
.end_comp_col:


    pop cx
    inc cx
    jmp .compare_row
.end_comp_row:

    ; ; "BJU!" in bright blue on white, center of screen, in text mode
    ; mov di, MESSAGE_START
    ; mov ah, 0x1F    ; background = 1 (blue), foreground = 15 (bright white)
    ; mov al, 'B'
    ; stosw
    ; mov al, 'J'
    ; stosw
    ; mov al, 'U'
    ; stosw
    ; mov al, '!'
    ;stosw

    ; Read a key, no echo-to-screen (use BIOS routines instead of DOS)
    mov ah, 0x10
    int 0x16
    

    ; Return to text mode
    mov ah, 0
    mov al, 3
    int 0x10
    
    ; quit-to-DOS
    mov ah, 0x4c
    int 0x21


;Mandlebrot fun
;X-scale (-2.5, 1)
;X formula: (1+2.5)(x-0)/(4000 - 0) + (-2.5)
;WHY FLOATING POINT WHY
;Y-scale (-1, 1)



section .data
x0  dd  0.0
y0  dd  0.0
x   dd  0.0
new_x   dd  0.0
y   dd  0.0
x2  dd  0.0
y2  dd  0.0
zero    dd  0.0
width_adj   dd  160.0
width       dd  320.0
height_adj  dd  100.0
height      dd  200.0
const_four  dd  4.0
const_two   dd  2.0
temp_col    dw  0
temp_row    dw  0
iteration   dw  0
junk    dq  0.0
status_word dw  0
temp    dw 0

; Smooth-blending 256 color palette
; generated by a Python script
; (RGB values in the range 0-63)
palette db  0, 0, 0
    db  1, 0, 0
    db  2, 0, 0
    db  3, 0, 0
    db  4, 0, 0
    db  5, 0, 0
    db  6, 0, 0
    db  7, 0, 0
    db  8, 0, 0
    db  9, 0, 0
    db  10, 0, 0
    db  11, 0, 0
    db  12, 0, 0
    db  13, 0, 0
    db  14, 0, 0
    db  15, 0, 0
    db  16, 0, 0
    db  17, 0, 0
    db  18, 0, 0
    db  19, 0, 0
    db  20, 0, 0
    db  21, 0, 0
    db  22, 0, 0
    db  23, 0, 0
    db  24, 0, 0
    db  25, 0, 0
    db  26, 0, 0
    db  27, 0, 0
    db  28, 0, 0
    db  29, 0, 0
    db  30, 0, 0
    db  31, 0, 0
    db  32, 0, 0
    db  33, 0, 0
    db  34, 0, 0
    db  35, 0, 0
    db  36, 0, 0
    db  37, 0, 0
    db  38, 0, 0
    db  39, 0, 0
    db  40, 0, 0
    db  41, 0, 0
    db  42, 0, 0
    db  43, 0, 0
    db  44, 0, 0
    db  45, 0, 0
    db  46, 0, 0
    db  47, 0, 0
    db  48, 0, 0
    db  49, 0, 0
    db  50, 0, 0
    db  51, 0, 0
    db  52, 0, 0
    db  53, 0, 0
    db  54, 0, 0
    db  55, 0, 0
    db  56, 0, 0
    db  57, 0, 0
    db  58, 0, 0
    db  59, 0, 0
    db  60, 0, 0
    db  61, 0, 0
    db  62, 0, 0
    db  63, 0, 0
    db  63, 0, 0
    db  63, 1, 0
    db  63, 2, 0
    db  63, 3, 0
    db  63, 4, 0
    db  63, 5, 0
    db  63, 6, 0
    db  63, 7, 0
    db  63, 8, 0
    db  63, 9, 0
    db  63, 10, 0
    db  63, 11, 0
    db  63, 12, 0
    db  63, 13, 0
    db  63, 14, 0
    db  63, 15, 0
    db  63, 16, 0
    db  63, 17, 0
    db  63, 18, 0
    db  63, 19, 0
    db  63, 20, 0
    db  63, 21, 0
    db  63, 22, 0
    db  63, 23, 0
    db  63, 24, 0
    db  63, 25, 0
    db  63, 26, 0
    db  63, 27, 0
    db  63, 28, 0
    db  63, 29, 0
    db  63, 30, 0
    db  63, 31, 0
    db  63, 32, 0
    db  63, 33, 0
    db  63, 34, 0
    db  63, 35, 0
    db  63, 36, 0
    db  63, 37, 0
    db  63, 38, 0
    db  63, 39, 0
    db  63, 40, 0
    db  63, 41, 0
    db  63, 42, 0
    db  63, 43, 0
    db  63, 44, 0
    db  63, 45, 0
    db  63, 46, 0
    db  63, 47, 0
    db  63, 48, 0
    db  63, 49, 0
    db  63, 50, 0
    db  63, 51, 0
    db  63, 52, 0
    db  63, 53, 0
    db  63, 54, 0
    db  63, 55, 0
    db  63, 56, 0
    db  63, 57, 0
    db  63, 58, 0
    db  63, 59, 0
    db  63, 60, 0
    db  63, 61, 0
    db  63, 62, 0
    db  63, 63, 0
    db  63, 63, 0
    db  63, 63, 1
    db  63, 63, 2
    db  63, 63, 3
    db  63, 63, 4
    db  63, 63, 5
    db  63, 63, 6
    db  63, 63, 7
    db  63, 63, 8
    db  63, 63, 9
    db  63, 63, 10
    db  63, 63, 11
    db  63, 63, 12
    db  63, 63, 13
    db  63, 63, 14
    db  63, 63, 15
    db  63, 63, 16
    db  63, 63, 17
    db  63, 63, 18
    db  63, 63, 19
    db  63, 63, 20
    db  63, 63, 21
    db  63, 63, 22
    db  63, 63, 23
    db  63, 63, 24
    db  63, 63, 25
    db  63, 63, 26
    db  63, 63, 27
    db  63, 63, 28
    db  63, 63, 29
    db  63, 63, 30
    db  63, 63, 31
    db  63, 63, 32
    db  63, 63, 33
    db  63, 63, 34
    db  63, 63, 35
    db  63, 63, 36
    db  63, 63, 37
    db  63, 63, 38
    db  63, 63, 39
    db  63, 63, 40
    db  63, 63, 41
    db  63, 63, 42
    db  63, 63, 43
    db  63, 63, 44
    db  63, 63, 45
    db  63, 63, 46
    db  63, 63, 47
    db  63, 63, 48
    db  63, 63, 49
    db  63, 63, 50
    db  63, 63, 51
    db  63, 63, 52
    db  63, 63, 53
    db  63, 63, 54
    db  63, 63, 55
    db  63, 63, 56
    db  63, 63, 57
    db  63, 63, 58
    db  63, 63, 59
    db  63, 63, 60
    db  63, 63, 61
    db  63, 63, 62
    db  63, 63, 63
    db  63, 63, 63
    db  63, 63, 63
    db  62, 62, 62
    db  61, 61, 61
    db  60, 60, 60
    db  59, 59, 59
    db  58, 58, 58
    db  57, 57, 57
    db  56, 56, 56
    db  55, 55, 55
    db  54, 54, 54
    db  53, 53, 53
    db  52, 52, 52
    db  51, 51, 51
    db  50, 50, 50
    db  49, 49, 49
    db  48, 48, 48
    db  47, 47, 47
    db  46, 46, 46
    db  45, 45, 45
    db  44, 44, 44
    db  43, 43, 43
    db  42, 42, 42
    db  41, 41, 41
    db  40, 40, 40
    db  39, 39, 39
    db  38, 38, 38
    db  37, 37, 37
    db  36, 36, 36
    db  35, 35, 35
    db  34, 34, 34
    db  33, 33, 33
    db  32, 32, 32
    db  31, 31, 31
    db  30, 30, 30
    db  29, 29, 29
    db  28, 28, 28
    db  27, 27, 27
    db  26, 26, 26
    db  25, 25, 25
    db  24, 24, 24
    db  23, 23, 23
    db  22, 22, 22
    db  21, 21, 21
    db  20, 20, 20
    db  19, 19, 19
    db  18, 18, 18
    db  17, 17, 17
    db  16, 16, 16
    db  15, 15, 15
    db  14, 14, 14
    db  13, 13, 13
    db  12, 12, 12
    db  11, 11, 11
    db  10, 10, 10
    db  9, 9, 9
    db  8, 8, 8
    db  7, 7, 7
    db  6, 6, 6
    db  5, 5, 5
    db  4, 4, 4
    db  3, 3, 3
    db  2, 2, 2
    db  1, 1, 1