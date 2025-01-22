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

        ;; make sure x1 > x0
        cmp ax, cx
        jge .x_if_over
        xchg ax, cx
        xchg bx, dx
        .x_if_over:

        sub bx, dx      ;; bx => dy = y1 - y0
        add bx, bx      ;; bx => 2dy = dy + dy
        mov si, bx      ;; si => 2dy
        mov bx, ax      ;; bx => x1
        sub ax, cx      ;; ax => dx = x1 - x0
        add ax, ax      ;; ax => 2dx = dx + dx
        mov di, ax      ;; di => 2dx
        mov BYTE [flag], 1
        cmp si, 0
        jge .over
        neg si
        mov BYTE [flag], -1
        .over:

        sub di, si
        mov [D], si     ;; [D] => 2dy
        sub [D], ax     ;; [D] => 2dy - dx

        mov ah, 0xc
        mov al, [draw_color]
        ;; use cx and dx as the iterators
        .loop:
                ;; cx and dx contain the right values
                int 0x10

                ;; if D > 0 {
                cmp WORD [D], 0
                jle .neg
                        cmp BYTE [flag], 0
                        jl .flag_neg
                        jmp .flag_pos
                        .flag_neg:
                                dec dx
                                jmp .flag_over
                        .flag_pos:
                                inc dx
                        .flag_over:
                        sub WORD [D], di
                        jmp .over_if
                .neg:
                        add WORD [D], si
                .over_if:

                inc cx
                cmp cx, bx
                jle .loop

        ret


;: Input:
;;   ax: left
;;   bx: top
;;   cx: width
;;   dx: height
;; Output: none
;; Destroys registers: ax, bx, cx, dx, di
draw_rect:
        mov di, dx  ;; cache dx
        xchg ax, bx
        mov dx, display_width
        mul dx      ;; mul puts the high part of the result into dx, that is
                    ;; why we cached it earlier
        add ax, bx
        mov dx, di ;; restore dx
        mov di, ax ;; pointer to top left pixel
        ;; di = y * screen_width + x

        mov bx, cx
        ;; ax = di
        ;; bx = width
        ;; cx = width
        ;; dx = height
        mov al, [draw_color]
.again_y:
        dec dx
        cmp dx, 0
        jle .over_y
        add di, display_width

        mov cx, bx
        .again_x:
                dec cx
                cmp cx, 0
                jle .over_x

                add di, cx
                mov [es:di], al
                sub di, cx
                jmp .again_x
        .over_x:
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

;; variables
;; draw_line
D: dw 0
flag: db 0
