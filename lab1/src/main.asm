; =============================================================================

.model small

.data
    bresenham_delta dw ?
    cell_point_pixel db ?

.data?
    a_x dw ?
    a_y dw ?
    b_x dw ?
    b_y dw ?

.const   
    DEFAULT_CELL_POINT_PIXEL equ 10000000b
    EVEN_NUMBERS_BANK_ADDR equ 0b800h
    ODD_FRAME_OFFSET equ 2000h
    SCREEN_WIDTH_BYTES equ 80
    SCREEN_WIDTH equ 640
    SCREEN_HEIGTH equ 200
    CGA_VIDEOMODE equ 6

.STACK 512

    ; mov ax, 0000h
    ; mov bx, 3030h
    ; call draw_line
    call wait_for_keypress
    call exit
    main endp


setup_cga_videomode proc near
; set up es to be a pointer on videobuffer address
    mov ax, CGA_VIDEOMODE
    int 10h
    mov ax, EVEN_NUMBERS_BANK_ADDR
    mov es, ax
    ret
    setup_cga_videomode endp


draw_line proc near
; ah:al - y:x coordinates of point A
; bh:bl - y:x coordinates of point B
    mov a_x, al
    mov a_y, ah
    mov b_x, bl
    mov b_y, bh
    call calculate_deltas 

    mov cl, b_x
    sub cl, a_x          ; calculate (x1-x0), put in cl

    mov dl, a_x          ; dl contains current x-position
    mov dh, a_y          ; dh contains current y-position
    bresenham_algorithm:
        mov bl, dl
        mov bh, dh

        call transform_coordinates
        call draw_white_point

        inc dl           ; increment x coordinate
        add dh, bresenham_delta
        loop bresenham_algorithm
    ret
    draw_line endp


calculate_deltas proc near
; ah:al - y0:x0
; bh:bl - y1:x1
; calculate (y1 - y0)/(x1 - x0) 
    cmp al, bl
    jz exit

    mov dl, bl
    sub dl, al ; x1 - x0
    mov dh, bh
    sub dh, ah ; y1 - y0

    xor ax, ax
    mov al, dh ; y1 - y0 -> al
    div dl     ; al = (x1 - x0) / (y1 - y0)
    mov bresenham_delta, al

    ret
    calculate_deltas endp


transform_coordinates proc near
; dx - x coordinate [0-639]
; bx - y coordinate [0-199]

; exit with error if input values are out of bounds
; returns numeric representation of address in bx
    call validate_coordinates

    push cx
    fixup_odd_row_frame:
        xor cx, cx
        test bl, 1
        jz calculate_offset
        add cx, ODD_FRAME_OFFSET
        dec bl

    calculate_offset:
        xor ax, ax
        mov al, bl
        mov bh, 2
        div bh
        mov bl, al ; divide it by 2 to correctly transform y coordinate

        mov ax, dx
        mov dl, 08
        div dl
        xor dx, dx
        call setup_cell_point_pixel
        mov dl, al ; divide it by 8 to correctly transform x coordinate

        mov ax, SCREEN_WIDTH_BYTES
        mul bl
        mov bx, ax
        add bx, dx
        add bx, cx
    
    pop cx
    ret
    transform_coordinates endp


validate_coordinates proc near
    cmp ah, SCREEN_HEIGTH
    jae exit
    cmp ax, SCREEN_WIDTH
    jae exit
    ret
    validate_coordinates endp


setup_cell_point_pixel proc near
; setup_cell_point proc near
; sets up cell point 
; 0 - 00000001
; 1 - 00000010
; 2 - 00000100
; ...
; ah - cell value
    push cx
    mov cell_point_pixel, default_cell_point_pixel
    mov cl, ah
    ror cell_point_pixel, cl
    pop cx
    ret
    setup_cell_point_pixel endp


draw_white_point proc near
; bx - byte address of cga pixel
; es - cga videobuffer address
    mov al, cell_point_pixel
    mov es:[bx], al
    ret
    draw_white_point endp


wait_for_keypress proc near
    xor ax, ax
    int 16h
    ret
    wait_for_keypress endp


exit proc
    mov ah, 4ch
    int 21h
    exit endp

end
