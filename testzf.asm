code segment
assume cs:code
main:
	sub ax, ax; zf = 1
	stc; cf =1
	jb there
here:
	mov ah, 2
	mov dl, 'A'
	int 21h
	jmp done
there:
	mov ah, 2
	mov dl, 'B'
	int 21h
done:
	mov ah, 4Ch
	int 21h
code ends
end main
