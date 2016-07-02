data segment
buf db 80, 0, 80 dup(0); first parameter : max number that you can input ;second number: the character you have input; then it is what you have input
data ends
code segment
assume cs : code, ds : data
main:
	mov ax, data
	mov ds, ax
	mov si, offset buf; here si plays the role of parameter of input
	call input; return the length of string in ax
	...
	call output; parameter ax = length of the string; si =  offset of string

input: ; si->buf
	mov ah, 0Ah
	mov dx, si
	int 21h
	xor ax, ax
	mov al, [si + 1]	
	ret
output:	;ax=len, si->string
	;it is a good practice not to spoil the value of bx, cx, dx
	push cx
	push dx
	push si
	mov cx, ax
next:
	mov ah,  2
	mov dl, [si]
	int 21h
	inc si
	loop next
	pop si
	pop dx
	pop cx
	ret


