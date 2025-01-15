format binary

;; set 640 x 480 16 color VGA display
mov ah, 0
mov al, 0x12
int 0x10

start:
        inc BYTE [draw_color]
        mov ax, 110
        mov bx, 50
        mov cx, 200
        mov dx, 50
        call draw_rec


        inc BYTE [draw_color]
        mov ax, 100
        mov bx, 200
        mov cx, 100
        mov dx, 70
        call draw_rec


        inc BYTE [draw_color]
        mov cx, 50
        mov dx, 70
        mov ax, 100
        mov bx, 120
        call draw_line

        ;; green pixel to make sure we exited the draw_rec procedure(s)
        mov ah, 0xc
        mov al, 10
        mov cx, 50
        mov dx, 50
        int 0x10

jmp start

;; Args:
;:   cx: x0
;;   dx: y0 
;;   ax: x1
;;   bx: y1
;;   Assumes that x1 > x0 and y1 > y0
draw_line:
        ;; https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
        ;; The following is a translation of the first pseudo-code example from the link above
        ;; (Source is in the `Algorithm for integer arithmetic` section)

        sub bx, dx      ;; bx => dy = y1 - y0
        add bx, bx      ;; bx => 2dy = dy + dy
        mov [d_y2], bx  ;; [d_y2] => 2dy
        sub bx, ax      ;; bx => 2dy - x1
        add bx, cx      ;; bx => 2dy - x1 + x0 = 2dy - (x1 - x0) = 2dy - dx
        mov [D], bx     ;; [D] => 2dy - dx
        mov bx, ax      ;; bx => x1
        sub ax, cx      ;; ax => dx = x1 - x0
        add ax, ax      ;; ax => 2dx = dx + dx
        mov [d_x2], ax  ;; [d_x2] => 2dx


        ;; use cx and dx as the iterators
        .loop:
                ;; cx and dx contain the right values
                mov ah, 0xc
                mov al, [draw_color]
                int 0x10

                
                cmp WORD [D], 0
                jle .skip ;; if D > 0
                        inc dx
                        mov ax, [d_x2]
                        sub WORD [D], ax
                .skip:
                mov ax, [d_y2]
                add WORD [D], ax

                inc cx
                cmp cx, bx
                jle .loop

        ret


;: Args:
;;   ax: left
;;   bx: top
;;   cx: width
;;   dx: height
draw_rec:

        mov [left], ax
        add dx, bx
        mov [top], bx
        mov bx, cx
        mov cx, ax

        mov ah, 0xc
        mov al, [draw_color]
.again_y:
        ;; dx: current y
        ;; cx: current x
        ;; bx: width
        ;; ax: used for draw call
        
        dec dx
        
        add cx, bx
        .again_x:
                dec cx

                int 0x10

                cmp cx, [left]
                jg .again_x
        ;.over_x

        cmp dx, [top]
        jg .again_y
;.over_y
        ret

;; fill the 512 bytes of the bootloader
times 510-($ - $$) db 0
;; magic bytes to indicate the end of the boot sector
db 0x55, 0xaa

;; global param
draw_color: db 0

;; variables
;; draw_rec
left: dw 0
top: dw 0

;; draw_line
D: dw 0
d_y2: dw 0
d_x2: dw 0
