; =============================================================================

.model small

.data
    delta_x dw ?
    delta_y dw ?
    y_deltas_difference dw ?
    x_deltas_difference dw ?
    bresenham_delta_x dw ?
    bresenham_delta_y dw ?

    a_x dw ?
    a_y dw ?
    b_x dw ?
    b_y dw ?

    cell_point_pixel dw ?

.const
    DEFAULT_CELL_POINT_PIXEL equ 10000000b
    EVEN_NUMBERS_BANK_ADDR equ 0b800h
    ODD_FRAME_OFFSET equ 2000h
    SCREEN_WIDTH_BYTES equ 80
    SCREEN_WIDTH equ 640
    SCREEN_HEIGTH equ 200
    CGA_VIDEOMODE equ 6

LOCALS l_

.code
start:
    push a_x
    push a_y
    push b_x
    push b_y
    push delta_x
    push delta_y
    push y_deltas_difference
    push bresenham_delta_y
    push bresenham_delta_x
    push cell_point_pixel

    call main

    pop cell_point_pixel
    pop bresenham_delta_x
    pop bresenham_delta_y
    pop y_deltas_difference
    pop delta_y
    pop delta_x
    pop b_y
    pop b_x
    pop a_y
    pop a_x

    call exit

main proc near
    call setup_cga_videomode

    mov word ptr [a_x], 0
    mov word ptr [a_y], 40
    mov word ptr [b_x], 100
    mov word ptr [b_y], 20
    call draw_curve_line
    mov word ptr [a_x], 0
    mov word ptr [a_y], 40
    mov word ptr [b_x], 100
    mov word ptr [b_y], 60
    call draw_curve_line
    call wait_for_keypress

    call setup_cga_videomode
    ret
    main endp


setup_cga_videomode proc near
; set up es to be a pointer on videobuffer address
    mov ax, CGA_VIDEOMODE
    int 10h
    mov ax, EVEN_NUMBERS_BANK_ADDR
    mov es, ax
    ret
    setup_cga_videomode endp


draw_curve_line proc near
    call calculate_delta_x
    call calculate_delta_y
    call draw_line
    ret
    draw_curve_line endp


draw_line proc near
; a_x: a_y - A point coordinates
; b_x: b_y - B point coordinates
    call calculate_deltas_difference
    call calculate_points_count

    mov dx, a_x         ; dx contains current x-position
    mov ax, a_y         ; ax contains current y-position
    process_point:
        push cx
        push ax
        push dx
        call transform_coordinates
        call draw_white_point
        pop dx
        pop ax
        call calculate_bresenham_deltas
        pop cx

        loop process_point
    ret
    draw_line endp


calculate_deltas_difference proc near
; calculates base deltas_difference which is used by bresenham algorithm
; y_deltas_difference = 2Dy-Dx
; x_deltas_difference = 2Dx-D
    mov ax, delta_y
    shl ax, 1
    mov cx, delta_x
    sub ax, delta_x
    mov y_deltas_difference, ax

    mov ax, delta_x
    shl ax, 1
    mov cx, delta_y
    sub ax, delta_y
    mov x_deltas_difference, ax
    ret
    calculate_deltas_difference endp


calculate_delta_x proc near
; a_x - A point x coordinate
; b_x - B point x coordinate
    mov ax, a_x
    mov dx, b_x
    sub dx, ax
    jge l_return
    neg dx

    l_return:
        mov delta_x, dx
        ret
    calculate_delta_x endp


calculate_delta_y proc near
; a_y - A point y coordinate
; b_y - B point y coordinate
    mov ax, a_y
    mov dx, b_y
    sub dx, ax
    jge l_return
    neg dx

    l_return:
        mov delta_y, dx
        ret
    calculate_delta_y endp


calculate_points_count proc near
; calculate in-line points count 
; return max(delta(x0, x1), delta(y0, y1))
; a_x: a_y - A point coordinates
; b_x: b_y - B point coordinates
; return points_count in cx
    find_max_delta:
        mov dx, word ptr [delta_x]
        mov cx, word ptr [delta_y]

        cmp dx, cx
        jl l_return ; abcsissa could be bigger otherwise
    
    ordinate_is_max:
        mov cx, dx
    
    l_return:
        inc cx ; one point is lost
        ret

    calculate_points_count endp    


run_bresenham_algorithm proc near
; dx - current x coordinate
; ax - current y coordinate

    ret
    run_bresenham_algorithm endp


calculate_bresenham_deltas proc near
    mov cx, y_deltas_difference
    cmp y_deltas_difference, 0
    jge define_area
    
    mov cx, delta_y ; no increment ordinate
    shl cx, 1
    add cx, y_deltas_difference
    mov y_deltas_difference, cx ; y_deltas_difference = y_deltas_difference + 2 * Dy

    process_x_deltas_difference:
        inc dx
        ret

    define_area:
        mov cx, a_y
        cmp cx, b_y
        jl increment_y
            dec ax

    process_y_deltas_difference:    
        mov cx, delta_y
        sub cx, delta_x
        shl cx, 1
        mov bx, y_deltas_difference
        sub cx, bx
        mov y_deltas_difference, cx ; y_deltas_difference = y_deltas_difference - 2 * (Dy - Dx)
        jmp process_x_deltas_difference
 
    increment_y:
        inc ax
        jmp process_y_deltas_difference

    calculate_bresenham_deltas endp


transform_coordinates proc near
; dx - x coordinate [0-639]
; ax - y coordinate [0-199]

; exit with error if input values are out of bounds
; returns numeric representation of address in ax
    push bx
    call validate_coordinates

    mov bx, ax
    fixup_odd_row_frame:
        xor cx, cx
        test bl, 1
        jz calculate_offset
        add cx, ODD_FRAME_OFFSET
        dec bl

    calculate_offset:
        xor ax, ax
        ror bl, 1 ; divide it by 2 to correctly transform y coordinate

        mov ax, dx
        mov dl, 08
        div dl
        xor dx, dx
        push cx
        call setup_cell_point_pixel
        pop cx
        mov dl, al ; divide it by 8 to correctly transform x coordinate

        mov ax, SCREEN_WIDTH_BYTES
        mul bl
        add ax, dx
        add ax, cx ; calculate absolute offset
    
    pop bx
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
    mov cell_point_pixel, DEFAULT_CELL_POINT_PIXEL
    mov cl, ah
    ror cell_point_pixel, cl
    ret
    setup_cell_point_pixel endp


draw_white_point proc near
; ax - byte address of cga pixel
; es - cga videobuffer address
    mov si, ax
    mov al, es:[si]
    or ax, cell_point_pixel
    mov es:[si], al
    ret
    draw_white_point endp


wait_for_keypress proc near
    xor ax, ax
    int 16h
    ret
    wait_for_keypress endp


exit proc near
    mov ax, 4c00h
    int 21h
    ret
    exit endp

end start
