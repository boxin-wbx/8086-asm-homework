data segment
buf db 256 dup(?)
filename db 100 
		db 0
		db 100 dup(0)
handle dw 0
key dw 0
bytes_in_buf dw 0
bytes_on_row dw 0
file_size dd 0
off_set dd 0
cc db 0
row db 0
message1 db "Please input filename:", 0Dh, 0Ah, "$"
message2 db "Cannot open file !", 0Dh, 0Ah, "$"
pattern db "00000000:            |           |           |                             "
table db "0123456789ABCDEF"
data ends

code segment
assume cs: code, ds:data

char2es: ;cc is the waiting char
push cx
	mov al, cc
	push ax
	push cx
	mov cx, 4
	shr al, cl
	pop cx
	and ax, 0fh
	lea si, table
	add si, ax	
	movsb
	inc di
	pop ax
	and ax, 0fh
	lea si, table
	add si, ax
	movsb

	inc di
pop cx
	ret

show_this_row:
push cx
push ax
push bx
sub cx, word ptr row
neg cx
mov ax, cx
mov cl, 16
mul cl; ax = i * 16
mov dx, ax
show_offset:
mov cx, 4
long2hex:
	mov bx, cx
	mov al, byte ptr off_set[bx - 1]
	mov byte ptr cc, al
	call char2es
loop long2hex
mov al, ':'
stosb
inc di

inc di
inc di; space

print_vertical_bar:
push di
push di
add di, 22
mov al, '|'
stosb
mov al, 0fh
stosb
add di, 22
mov al, '|'
stosb
mov al, 0fh
stosb
add di, 22
mov al, '|'
stosb
mov al, 0fh
stosb
pop di

mov cx, bytes_on_row
mov bx, dx
xor ax, ax
print_buf:
	mov al, byte ptr buf[bx]
	inc bx
	mov byte ptr cc, al
	call char2es
	print_space:
		inc di
		inc di
	loop print_buf
pop di
add di, 98

mov cx, bytes_on_row
lea si, buf
add si, dx
print_char:
	movsb
	inc di
	loop print_char
pop bx
pop ax
pop cx
ret

clear_this_page:
cld
xor di, di
push cx
mov cx, 80*16
mov ax, 0720h
mov di, 0
rep stosw
pop cx
ret

show_this_page:
call clear_this_page
push cx
push ax
push bx
mov ax, bytes_in_buf
add ax, 15
mov cl, 16
div cl
mov cl, al
mov ch, 0
mov word ptr row, cx
xor di, di
show_row:
	push di
	dec cx
	jcxz last_row
	else_row:
		mov bytes_on_row, 16
		inc cx
		jmp after_if_row
	last_row:
		inc cx
		mov ax, word ptr bytes_in_buf
		mov bytes_on_row, ax
		;sub word ptr bytes_on_row, (row - 1) * 16
		mov ax, word ptr row
		dec ax
		mov bl, 16
		mul bl
		sub word ptr bytes_on_row, ax
	after_if_row:
		call show_this_row ; cx = row - i
		add word ptr off_set, 16
		pop di
		add di, 80 * 2
		loop show_row
pop bx
pop ax
pop cx
ret

file_exception:
mov ah, 9
lea dx, message2
int 21h
jmp exit

main:

mov ax, 0B800h
mov es, ax

mov ax, data
mov ds, ax

mov ah, 9
lea dx, message1
int 21h

lea dx, filename
mov ah, 0ah
int 21h

mov ah, 0
mov al, filename[1]
xor di, di
mov di, ax
add di, dx
mov byte ptr ds:[2 + di], 0

mov ah, 3Dh
mov al, 0
mov dx, 2 + offset filename
int 21h

jc file_exception

mov handle, ax

mov ah, 42h
mov al, 2
mov bx, handle
mov cx, 0
mov dx, 0
int 21h
mov word ptr file_size[2], dx
mov word ptr file_size[0], ax

mov word ptr off_set[0], 0
mov word ptr off_set[2], 0

do_while:
mov ax, word ptr file_size[0]
mov dx, word ptr file_size[2]

sub ax, word ptr off_set[0]
sbb dx, word ptr off_set[2]

cmp ax, 256
jb less_than_256
ge_256:
	mov word ptr bytes_in_buf, 256
	jmp after_if_256
less_than_256: 
	cmp dx, 0
	jne after_if_256
	mov word ptr bytes_in_buf, ax
after_if_256:
mov ah, 42h
mov al, 0
mov bx, handle
mov cx, word ptr off_set[2]
mov dx, word ptr off_set[0]
int 21h

mov ah, 3Fh
mov bx, handle
mov cx, bytes_in_buf
mov dx, data
mov ds, dx
mov dx, offset buf
int 21h

;buf off_set bytes_in_buf
push word ptr off_set
call show_this_page
pop word ptr off_set

switch_key:

mov ah, 0
int 16h

cmp ax, 4900h
je pageUp

cmp ax, 5100h
je pageDown

cmp ax, 4700h
je home

cmp ax, 4f00h
je key_end

cmp ax, 011bh
je exit

jmp switch_key

exit:
mov ah, 4Ch
mov al, 0
int 21h

pageUp:
sub word ptr off_set[0], 256
sbb word ptr off_set[2], 0
jge after_if_ge
mov word ptr off_set[0], 0
mov word ptr off_set[2], 0
after_if_ge:
jmp do_while

home:
mov word ptr off_set[0], 0
mov word ptr off_set[2], 0
jmp do_while

key_end:
mov ax, word ptr file_size[0]
mov dx, word ptr file_size[2]
mov bx, 256
div bx ;  dx = file_size % 256
mov ax, word ptr file_size[0]
mov bx, word ptr file_size[2]
sub ax, dx
sbb bx, 0
mov word ptr off_set[0], ax
mov word ptr off_set[2], bx
cmp dx, 0
jne after_if_filesize
sub word ptr off_set[0], 256
sbb word ptr off_set[2], 0
after_if_filesize:
jmp do_while

pageDown:
add word ptr off_set[0], 256
adc word ptr off_set[2], 0
mov ax, word ptr file_size[0]
mov bx, word ptr file_size[2]
cmp bx, word ptr off_set[2]
ja after_if_recover ; offset < file_size
cmp bx, word ptr off_set[2]
jb recover          ; offset > file_size 
cmp ax, word ptr off_set[0]
ja after_if_recover ; offset < file_size
recover:
sub word ptr off_set[0], 256
sbb word ptr off_set[2], 0
after_if_recover:
jmp do_while

code ends
end main
