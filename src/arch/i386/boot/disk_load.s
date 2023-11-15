	;; load DH sectors to ES:BX from drive DL
disk_load:
	push dx  		; store DX on stack for later

	mov ah, 0x02 		; BIOS read sector function
	mov al, dh 		; Read DH sectors
	mov ch, 0x00		; select cylinder 0
	mov dh, 0x00 		; select head 0
	mov cl, 0x02 		; Start reading from second sector

	int 0x13 		; BIOS interupt
;	jc disk_error 		; Jump if error (i.e carry flag set)

	pop dx 			; restore dx from stack
	cmp dh, al 		; if AL (sectors read) != DH (sectors expected)
	;;	jne disk_error		;       display error message
	ret

disk_error:
	mov bx, DISK_ERROR_MSG
	call print_string
	jmp $

DISK_ERROR_MSG db "Disk read error!", 0
	
