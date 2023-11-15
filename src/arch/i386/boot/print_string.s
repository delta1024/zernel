;;; print_string(char* str_ptr) - Prints a null terminated string
;;; Paramaters:
;;; 	- str_ptr: BX
print_string:
	mov ah, 0x0e   ; Set the teletype print flag
	
	print_string.loop:
	mov al, [bx]
	inc bx
	cmp al, 0
	je print_string.end

	int 0x10
	jmp print_string
	print_string.end:
	ret

;;; print_hex(int num)
;;; Paramaters:
;;; 	- num: DX
	
print_hex:
	;; TODO: manipulate chars at HEX_OUT to reflect DX

	pusha 			; save registers

	mov cx, 4 		; start counter: we need to print 4 characters
				; 4 bits per char, ro we're printing a total of 16 bits.

	.char_loop:
	dec cx

	mov ax, dx
	shr dx, 4
	and ax, 0xf

	mov bx, HEX_OUT
	add bx, 2 		; skip '0x'
	add bx, cx		; add current counter to the address

	cmp ax, 0xa		; check to see if its a letter
	jl .set_letter		; if its a number go strait to setting its value
	add byte[bx], 7 	; ASCII letters start 17 characters after decimal numbers.
				; if is a letter its already at 10

	.set_letter:
	add byte[bx], al

	cmp cx, 0
	je .hex_done
	jmp .char_loop

	.hex_done:
	mov bx, HEX_OUT
	call print_string

	call reset_hex_str	
	popa
	ret
	
reset_hex_str:
	pusha

	mov cx, 4

	.loop:
	dec cx
	mov bx, HEX_OUT		
	add bx, 2 		; skip '0x'

	add bx, cx 		; get offset
	mov byte[bx], 0x30	; 0x30 = '0'

	cmp cx, 0
	je .done
	jmp .loop

	.done:
	popa
	ret
	

HEX_OUT: db "0x0000", 0
