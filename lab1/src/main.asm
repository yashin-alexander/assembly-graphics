; =============================================================================

.model small
.const
    even_numbers_bank_addr equ 0b800h
    odd_numbers_bank_addr equ 0ba00h
    screen_width equ 100
    screen_height equ 80
    cga_videomode equ 6
    white_color_code equ 1

.data
    a_x db ?
    a_y db ?
    b_x db ?
    b_y db ?
    bresenham_delta db ?
.code


main proc near
    call setup_cga_videomode

    ; xor bx, bx
    ; mov bx, 0069h
    ; call transform_coordinates
    ; call draw_white_point

    mov ax, 0000h
    mov bx, 3030h
    call draw_line
    call wait_for_keypress
    call exit
    main endp


setup_cga_videomode proc near
; set up es to be a pointer on videobuffer address
    mov ax, cga_videomode
    int 10h
    mov ax, 0b800h
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
    mov dh, a_y          ; dh containt current y-position
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
; bh - y coordinate [0-99]
; bl - x coordinate [0-79]
; exit with error if input values are out of bounds
; returns numeric representation of address in bx
    cmp bh, screen_width
    jae exit
    cmp bl, screen_height
    jae exit
    mov al, screen_height
    mul bh
    xor bh, bh
    add bx, ax
    ret
    transform_coordinates endp


draw_white_point proc near
; bx - byte address of cga pixel
; es - cga videobuffer address
    mov al, white_color_code
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
