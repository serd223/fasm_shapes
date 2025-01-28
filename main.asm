ORG 0x7c00
format binary

;; set 320 x 200 256 color VGA display
mov ah, 0
mov al, 0x13
int 0x10
display_width equ 320

;; framebuffer is from 0xA000:0000 to 0xA000:ffff
;; use es to index into the buffer
mov dx, 0xA000
mov es, dx

mov BYTE [draw_color], 5
;; write text
mov si, hello_world
mov dh, 1
mov dl, 1
call write_string

start:

        inc BYTE [draw_color]
        mov ax, 50
        mov bx, 30
        mov cx, 100
        mov dx, 50
        call draw_rect

        inc BYTE [draw_color]
        mov ax, 100
        mov bx, 130
        mov cx, 200
        mov dx, 69
        call draw_rect

        inc BYTE [draw_color]
        mov ax, 300
        mov bx, 120
        mov cx, 60
        mov dx, 100
        call draw_line

        inc BYTE [draw_color]
        mov ax, 60
        mov bx, 120
        mov cx, 300
        mov dx, 100
        call draw_line

jmp start

;; Input:
;;   ax: x1
;;   bx: y1
;:   cx: x0
;;   dx: y0 
;; Output: none
;; Destroys registers: ax, bx, cx, dx, si, di
draw_line:
        ;; https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm

        ;; make sure y1 > y0
        cmp bx, dx
        jge .y_if_over
        xchg ax, cx
        xchg bx, dx
        .y_if_over:

        ;; ah => sign_x 
        ;; al => color 
        ;; bx => error 
        ;; cl => -d_y
        ;; ch => abs(y1 - y0) (counter) 
        ;; dx => d_x 
        ;; si => abs(x1 - x0) (counter) 
        ;; di => pointer 

        mov di, cx              ;; di => x0
        sub ax, cx              ;; ax => x1 - x0
        mov si, ax              ;; si => x1 - x0
        mov ax, dx              ;; ax => y0
        mov cx, ax              ;; cx => y0
        mov dx, display_width   ;; dx => display_width
        mul dx                  ;; ax => y0 * display_width; dx => 0 (most of the time)
        add di, ax              ;; di => y0 * display_width + x0
        mov ah, 1               ;; ah => sign_y
        cmp si, 0               ;; if x1 < x0 { sign_x = -1 } else { sign_x = 1 }
        jge .sign_y_over
        neg si
        mov ah, -1
        .sign_y_over:           ;; si => abs(x1 - x0)
        mov dx, si              ;; dx => d_x = abs(x1 - x0)
        sub bx, cx              ;; bx => abs(y1 - y0) (always positive)
        mov ch, bl              ;; ch => abs(y1 - y0) (since the resolution is low, the y pos should fit in 8 bits)
        mov cl, bl              ;; cl => -d_y = abs(y1 - y0)
                                ;; bx => -dy
        neg bx                  ;; bx => dy
        add bx, dx              ;; bx => error = d_x + d_y
        mov al, [draw_color]    ;; al => color
        .loop:
                mov [es:di], al ;; plot(x0, y0)
                push di         ;; [pixel]
                mov di, bx
                add bx, bx
                push cx         ;; [dy|dyi][pixel]
                xor ch, ch
                neg cx
                cmp bx, cx
                pop cx          ;; [pixel]
                jge .e2_dy_ge
                jmp .e2_dy_else
                .e2_dy_ge:
                        cmp si, 0
                        jle .over
                        push cx         ;; [dyi|dy][pixel]
                        xor ch, ch
                        sub di, cx      ;; error -= -dy := error += dy
                        pop cx          ;; [pixel]
                        mov bx, di
                        pop di          ;; []
                        cmp ah, 0
                        jge .sign_x_pos
                        jmp .sign_x_neg
                        .sign_x_pos:
                                inc di
                                dec si
                                jmp .sign_x_over
                        .sign_x_neg:
                                dec di
                                dec si
                        .sign_x_over:
                        jmp .e2_dy_over
                .e2_dy_else:
                        mov bx, di
                        pop di          ;; []
                .e2_dy_over:
                push di         ;; [pixel]
                mov di, bx
                add bx, bx
                cmp bx, dx
                jle .e2_dx_le
                jmp .e2_dx_else
                .e2_dx_le:
                        cmp ch, 0
                        jle .over

                        add di, dx
                        mov bx, di
                        pop di
                        add di, display_width
                        dec ch

                        jmp .e2_dx_over
                .e2_dx_else:
                        mov bx, di
                        pop di
                .e2_dx_over:

                jmp .loop
        .over:
        pop di
        ret


;: Input:
;;   ax: left
;;   bx: top
;;   cx: width
;;   dx: height
;; Output: none
;; Destroys registers: ax, bx, dx, di
draw_rect:
        mov di, dx  ;; cache dx
        xchg ax, bx
        mov dx, display_width
        mul dx      ;; mul puts the high part of the result into dx, that is
                    ;; why we cached it earlier
        add ax, bx
        mov dx, di  ;; restore dx
        mov di, ax  ;; pointer to top left pixel
        ;; di = y * screen_width + x

        mov al, [draw_color]
        ;; cx = width
        ;; dx = height
.again_y:
        dec dx
        cmp dx, 0
        jl .over_y

        mov bx, cx
        .again_x:
                cmp bx, 0
                jle .over_x
                dec bx

                mov [es:di], al
                inc di
                jmp .again_x
        .over_x:
        add di, display_width
        sub di, cx
        jmp .again_y
.over_y:
        ret

;; Input:
;;   si: zero-terminated string
;;   dh: Cursor row
;;   dl: Cursor column
;; Output: none
;; Destroys registers: ax, bx, cx, dx, si
write_string:
        ;; put cursor in specified position
        mov ah, 0x2
        xor bx, bx
        int 0x10
.loop:
        ;; print current char
        mov ah, 0x9

        mov al, [si]
        ;; if char == '\0', break out of the loop
        cmp al, 0
        je .over

        mov bl, [draw_color]
        mov cx, 1
        int 0x10

        ;; adjust cursor
        inc dl
        mov ah, 0x2
        xor bx, bx
        int 0x10

        inc si
        jmp .loop
.over:
        ret

hello_world: db "Hello, World!", 0

;; fill the 512 bytes of the bootloader
times 510-($ - $$) db 0
;; magic bytes to indicate the end of the boot sector
db 0x55, 0xaa

;; global param
draw_color: db 0
