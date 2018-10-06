; =============================================================================
; Assembly graphics
; =============================================================================
; Procedures:
; - transform_coordinates
; - draw_white_point
; - draw_line
; - draw_circle
; - fill_area
; =============================================================================
; author_email: yashin.alexander.42@gmail.com

.model small

.data
; parameters for bresenham algorithm
    delta_x dw ?
    delta_y dw ?
    y_deltas_difference dw ?
    x_deltas_difference dw ?

; parameters for starodubtsev algorithm
    circle_delta dw ?
    iteration_index dw ?

; parameters for point processing
    a_x dw ?
    a_y dw ?
    b_x dw ?
    b_y dw ?
    current_x dw ?
    current_y dw ?
    cell_point_pixel dw ?
    radius dw ?


.const
    DEFAULT_CELL_POINT_PIXEL equ 10000000b
    EVEN_NUMBERS_BANK_ADDR equ 0b800h
    ODD_FRAME_OFFSET equ 2000h
    SCREEN_WIDTH_BYTES equ 80
    SCREEN_WIDTH equ 640
    SCREEN_HEIGTH equ 200
    CGA_VIDEOMODE equ 6
    TIMEOUT equ 1

locals l_


.code

setup_cga_videomode proc near
; set up es to be a pointer on videobuffer address
    mov ax, CGA_VIDEOMODE
    int 10h
    mov ax, EVEN_NUMBERS_BANK_ADDR
    mov es, ax
    ret
    setup_cga_videomode endp


fill_area proc near
; a_x: a_y - in-area point coordinates
; fills area in which point is placed
    mov ax, a_y
    mov dx, a_x
    call recursively_fill
    ret
    fill_area endp


recursively_fill proc
; takes x,y point coordinates in dx,ax
; do nothing if the point is already filled
; fills the point and runs the same procedure for four neighboring points otherwise
    push dx
    push ax
    check_center:
        call transform_coordinates
        mov si, ax
        mov cl, es:[si]
        and cx, cell_point_pixel
        cmp cl, 0
        jne point_is_filled
        call draw_white_point

    check_bottom:
        pop ax
        pop dx
        inc ax ; y--
        call recursively_fill
        dec ax

    check_top:
        dec ax ; y++
        call recursively_fill
        inc ax

    check_right:
        inc dx ; x ++
        call recursively_fill
        dec dx

    check_left:
        dec dx ; x --
        call recursively_fill
        inc dx

    l_return: 
        ret

    point_is_filled:
        pop ax
        pop dx
        jmp l_return
    recursively_fill endp


draw_circle proc near
; a_x: a_y - center coordinates
; radius - circle radius value
; powered by starodubtsev algorithm
    call initialize_starodubtsev
    l_process_starodubtsev:
        call draw_circle_parts
        inc current_x
        mov dx, circle_delta
        add dx, iteration_index ; circle_delta = circle_delta + iteration_index
        mov ax, current_y
        shr ax, 1
        cmp dx, ax
        jl draw_point ; if circle_delta < current_y / 2, do not change current_y

        dec current_y ; increment y otherwise
        sub dx, current_y ; circle_delta = circle_delta - current_y
            
        draw_point:
            mov word ptr [circle_delta], dx ; save new circle_delta value
            inc iteration_index
        mov dx, current_x
        cmp dx, current_y ; repeat untill current_x < current_y
    jle l_process_starodubtsev
    ret
    draw_circle endp


initialize_starodubtsev proc near
; initialize all the starodubtsev required data
    mov word ptr [current_x], 0
    mov word ptr [circle_delta], 0
    mov word ptr [iteration_index], 0
    mov ax, radius
    mov word ptr [current_y], ax ; start with current_x = 0, current_y = radius
    ret
    initialize_starodubtsev endp


draw_circle_parts proc near
; takes starodubtsev current x,y coordinates in current_x, current_y
; and circle center coordinate in a_x, a_y
; symmetrically draws a point in eight parts of a circle
    mov dx, a_x
    add dx, current_x
    mov ax, a_y ; add actual point coordinates
    sub ax, current_y
    call transform_coordinates
    call draw_white_point

    mov dx, a_x
    add dx, current_x
    mov ax, a_y
    add ax, current_y
    call transform_coordinates
    call draw_white_point

    mov dx, a_x
    sub dx, current_x
    mov ax, a_y
    add ax, current_y
    call transform_coordinates
    call draw_white_point

    mov dx, a_x
    sub dx, current_x
    mov ax, a_y
    sub ax, current_y
    call transform_coordinates
    call draw_white_point

    mov dx, a_x
    add dx, current_y
    mov ax, a_y
    sub ax, current_x
    call transform_coordinates
    call draw_white_point

    mov dx, a_x
    add dx, current_y
    mov ax, a_y
    add ax, current_x
    call transform_coordinates
    call draw_white_point

    mov dx, a_x
    sub dx, current_y
    mov ax, a_y
    add ax, current_x
    call transform_coordinates
    call draw_white_point

    mov dx, a_x
    sub dx, current_y
    mov ax, a_y
    sub ax, current_x
    call transform_coordinates
    call draw_white_point

    ret
    draw_circle_parts endp


draw_line proc near
; a_x: a_y - A point coordinates
; b_x: b_y - B point coordinates
    call fixup_points_order
    call calculate_delta_x
    call calculate_delta_y
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
        call run_bresenham_algorithm
        pop cx

        loop process_point
    ret
    draw_line endp


fixup_points_order proc near
; swap A -> B point coordinates if Ax > Bx
; do nothing otherwise
    mov cx, a_x
    cmp cx, b_x
    jl l_return; l_return ; point A is in the left, it's OK

    mov dx, b_x ; swap point coordinates, A->B B->A
    mov word ptr [b_x], cx
    mov word ptr [a_x], dx
    mov cx, a_y
    mov dx, b_y
    mov word ptr [b_y], cx
    mov word ptr [a_y], dx

    l_return:
    ret
    fixup_points_order endp


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


calculate_deltas_difference proc near
; calculates base deltas_difference which is used by bresenham algorithm
; y_deltas_difference = 2Dy  -Dx
; x_deltas_difference = 2Dx - Dy
    mov ax, delta_y
    shl ax, 1
    sub ax, delta_x
    mov y_deltas_difference, ax

    mov ax, delta_x
    shl ax, 1
    sub ax, delta_y
    mov x_deltas_difference, ax
    ret
    calculate_deltas_difference endp


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
    mov cx, delta_y
    cmp cx, delta_x
    jge major_x
    major_y:
        call calculate_x_major_bresenham_deltas
    l_return:
        ret

    major_x:
        call calculate_y_major_bresenham_deltas
        jmp l_return

    run_bresenham_algorithm endp


calculate_x_major_bresenham_deltas proc near
; dx - constantly incremented x coordinate
; ax - y coordinate
    mov cx, y_deltas_difference
    cmp y_deltas_difference, 0
    jge l_define_incremention_area ; two cases: Di < 0 or Di >= 0
    
    mov cx, delta_y ; case when Di < 0
    shl cx, 1
    add cx, y_deltas_difference
    mov y_deltas_difference, cx ; deltas_difference = deltas_difference + 2 * Dy

    l_return:
        inc dx
        ret

    l_define_incremention_area: ; case when Di >= 0
        mov cx, a_y
        cmp cx, b_y
        jl increment_y ; if line from bootom to high, increment minor
        dec ax ; decrement minor otherwise

    l_process_deltas_difference: ; calculate deltas difference for next iteration    
        mov cx, delta_y
        sub cx, delta_x
        shl cx, 1
        mov bx, y_deltas_difference
        add bx, cx
        mov y_deltas_difference, bx ; deltas_difference = deltas_difference - 2 * (Dy - Dx)
        jmp l_return
 
    increment_y:
        inc ax
        jmp l_process_deltas_difference

    calculate_x_major_bresenham_deltas endp


calculate_y_major_bresenham_deltas proc near
; dx - x coordinate
; ax - constantly incremented y coordinate
    l_define_incremention_area:
        mov cx, a_y
        cmp cx, b_y
        jl increment_x ; if line from bootom to top , decrement major
        dec ax ; increment major otherwise
    
    l_process_deltas_difference:
        mov cx, x_deltas_difference
        cmp x_deltas_difference, 0
        jge l_calculate_deltas_difference ; two cases: Di < 0 or Di >= 0
    
    mov cx, delta_x ; case when Di < 0
    shl cx, 1
    add cx, x_deltas_difference
    mov x_deltas_difference, cx ; deltas_difference = deltas_difference + 2 * Dx

    l_return:
        ret

    increment_x:
        inc ax 
        jmp l_process_deltas_difference

    l_calculate_deltas_difference:  ; case when Di >= 0;
        inc dx          ; increment x
        mov cx, delta_x ; calculate deltas difference for next iteration    
        sub cx, delta_y
        shl cx, 1
        mov bx, x_deltas_difference
        add bx, cx
        mov x_deltas_difference, bx ; deltas_difference = deltas_difference - 2 * (Dx - Dy)
        jmp l_return
 
    calculate_y_major_bresenham_deltas endp


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
    cmp ax, SCREEN_HEIGTH
    jae exit
    cmp dx, SCREEN_WIDTH
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


sleep proc
    xor ax, ax
    int 1Ah 
    add dx, TIMEOUT
    mov bx, dx
    l_repeat:   
        int 1Ah
        cmp dx, bx
        jl l_repeat
    ret
    sleep endp


exit proc near
    mov ax, 4c00h
    int 21h
    ret
    exit endp


run_animation proc near
; flying circle animation
    mov a_x, 320
    mov a_y, 100
    l_repeat:
        call trembling_left_circle
        call trembling_right_circle
        loop l_repeat
    ret
    run_animation endp


trembling_left_circle proc near
; make the circle fly to left
    mov radius, 40
    mov cx, 20
    l_repeat_dec:
        push cx
        dec radius
        dec a_x
        dec a_x
        call draw_circle
        call sleep
        call setup_cga_videomode
        pop cx
        loop l_repeat_dec
    mov cx, 20
    l_repeat_inc:
        push cx
        inc radius
        dec a_x
        dec a_x
        call draw_circle
        call sleep
        call setup_cga_videomode
        pop cx
        loop l_repeat_inc
    ret
    trembling_left_circle endp


trembling_right_circle proc near
; make the circle fly to right
    mov radius, 40
    mov cx, 20
    l_repeat_dec:
        push cx
        dec radius
        inc a_x
        inc a_x
        call draw_circle
        call sleep
        call setup_cga_videomode
        pop cx
        loop l_repeat_dec
    mov cx, 20
    l_repeat_inc:
        push cx
        inc radius
        inc a_x
        inc a_x
        call draw_circle
        call sleep
        call setup_cga_videomode
        pop cx
        loop l_repeat_inc
    ret
    trembling_right_circle endp


start:
    mov ax, @data
    mov ds, ax
    call setup_cga_videomode
    call run_animation
    call exit
end start
