; =============================================================================

.model small
.code


main proc near
    call setup_sga_videobuffer

    mov bh, 99
    mov bl, 14
    call transform_coordinates
    call draw_white_point
    ; mov ax, 0000
    ; mov bx, 1414
    ; call draw_line
    call wait_for_keypress
    call exit
    main endp


setup_sga_videobuffer proc near
                        ; set up es to be a pointer on videobuffer address
    mov ax, 0006h ; 6 - white & black cga mode
    int 10h
    mov ax, 0b800h ; 0b80:0000 - first byte of cga videobuffer
    mov es, ax
    ret
    setup_sga_videobuffer endp

draw_line proc near
                        ; ah:al - y:x coordinates of point A
                        ; bh:bl - y:x coordinates of point B
    
    ret
    draw_line endp


transform_coordinates proc near
                        ; bh - y coordinate [0-99]
                        ; bl - x coordinate [0-79]
                        ; returns numeric representation of address in bx
                        ; affects ax
    mov al, 80 ; 80 pixels in line
    mul bh
    xor bh, bh
    add bx, ax
    ret
    transform_coordinates endp


draw_white_point proc near
                        ; bx - byte address of cga pixel
                        ; es - cga videobuffer address
    mov al, 1 ; color
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
