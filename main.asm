format binary

;; set 640 x 480 16 color VGA display
mov ah, 0
mov al, 0x12
int 0x10

mov ax, 80
mov bx, 50
mov cx, 200
mov dx, 50
call draw_rec

mov ax, 100
mov bx, 200
mov cx, 100
mov dx, 70
call draw_rec

;; green pixel to make sure we exited the draw_rec procedure(s)
mov ah, 0xc
mov al, 10
mov cx, 50
mov dx, 50
int 0x10

;; hang forever
jmp $

;: Args:
;;   ax: left
;;   bx: top
;;   cx: width
;;   dx: height
draw_rec:

        mov [left], ax
        mov [top], bx
        mov bx, cx
        mov [counter_h], dx

        mov ah, 0xc
        mov al, 7
.again_y:
        dec WORD [counter_h]
        
        mov WORD [counter_w], bx
        .again_x:

                dec WORD [counter_w]
                mov cx, WORD [left]
                add cx, WORD [counter_w]

                mov dx, WORD [top]
                add dx, WORD [counter_h]

                int 0x10

                cmp WORD [counter_w], 0
                jg .again_x
        ;.over_x

        cmp WORD [counter_h], 0
        jg .again_y
;.over_y
        ret

;; fill the 512 bytes of the bootloader
times 510-($ - $$) db 0
;; magic bytes to indicate the end of the boot sector
db 0x55, 0xaa

;; variables
counter_w: dw 0
counter_h: dw 0
left: dw 0
top: dw 0
