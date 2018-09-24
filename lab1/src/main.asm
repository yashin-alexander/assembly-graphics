; =============================================================================

.model small

.data
    bresenham_delta dw ?
    delta_x dw ?
    delta_y dw ?
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

LOCALS l_

.code
main:
    call setup_cga_videomode
    mov word ptr [a_x], 192
    mov word ptr [a_y], 192
    mov word ptr [b_x], 199
    mov word ptr [b_y], 199

    mov dx, a_x         ; dx contains current x-position
    mov ax, a_y         ; bx contains current y-position
    call draw_line
    call wait_for_keypress
    call exit


setup_cga_videomode proc near
; set up es to be a pointer on videobuffer address
    mov ax, CGA_VIDEOMODE
    int 10h
    mov ax, EVEN_NUMBERS_BANK_ADDR
    mov es, ax
    ret
    setup_cga_videomode endp


draw_line proc near
; a_x: a_y - A point coordinates
; b_x: b_y - B point coordinates
    call calculate_deltas
    call calculate_bresenham_delta

    mov dx, a_x         ; dx contains current x-position
    mov ax, a_y         ; bx contains current y-position
    bresenham_algorithm:
        push ax
        push dx
        push cx
        call transform_coordinates
        call draw_white_point
        pop cx
        pop dx
        pop ax

        inc dx          ; increment x coordinate
        add ax, bresenham_delta
        loop bresenham_algorithm
    ret
    draw_line endp


calculate_deltas proc near
; calculate in-line points count 
; return max(delta(x0, x1), delta(y0, y1))
; a_x: a_y - A point coordinates
; b_x: b_y - B point coordinates
; return points_count in cx

    abscissa_delta_calculate:
        mov dx, b_x
        mov ax, a_x
        sub dx, ax
        jge ordinate_delta_calculate

    abscissa_reversed_points:
        neg dx

    ordinate_delta_calculate:
        mov cx, b_y
        mov ax, a_y
        sub cx, ax
        jge find_max_delta

    ordinate_reversed_points:
        neg cx

    find_max_delta:
        mov delta_x, dx
        mov delta_y, cx

        cmp dx, cx
        jz l_return ; abcsissa could be bigger otherwise
    
    ordinate_is_max:
        mov cx, dx
    
    l_return:
        inc cx ; one point is lost
        ret

    calculate_deltas endp    


calculate_bresenham_delta proc near
; a_x: a_y - A point coordinates
; b_x: b_y - B point coordinates
; calculate (y1 - y0)/(x1 - x0) 
    cmp delta_x, 0
    jnz calculate_delta
    mov bresenham_delta, 0
    l_return:
        ret

    calculate_delta:
        mov ax, delta_x
        mov cx, delta_y

        xor dx, dx
        div cx      ; al = (y1 - y0) / (x1 - x0) 
        mov bresenham_delta, ax
        jmp l_return

    calculate_bresenham_delta endp


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
        mov al, bl
        mov bh, 2
        div bh
        mov bl, al ; divide it by 2 to correctly transform y coordinate

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
    push bx
    mov bx, ax
    mov al, es:[bx]
    or al, cell_point_pixel
    mov es:[bx], al
    pop bx
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

end main
