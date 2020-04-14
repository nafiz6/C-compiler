.MODEL SMALL
.STACK 100H
.DATA
returnTemp DW ?
t0 DW ?
t1 DW ?
c_2 DW ?
d_2 DW ?
t2 DW ?
t3 DW ?
t4 DW ?
t5 DW ?
t6 DW ?
a_5 DW ?
b_5 DW ?
d_5 DW ?
t7 DW ?
param1 DW ?
.CODE
MAIN PROC
;init ds
mov ax, @DATA
mov ds, ax

mov ax, 15
mov a_5, ax
push ax
push bx
push cx
push dx
mov ax, a_5
call print
pop dx
pop cx
pop bx
pop ax
push c_2
push d_2
push a_5
push b_5
push d_5
push ax
push bx
push cx
push dx
push param1
mov ax, a_5
mov param1, ax
CALL func
pop param1
pop dx
pop cx
pop bx
pop ax
pop d_5
pop b_5
pop a_5
pop d_2
pop c_2
mov ax, returnTemp
mov t7, ax
mov ax, t7
mov d_5, ax
push ax
push bx
push cx
push dx
mov ax, d_5
call print
pop dx
pop cx
pop bx
pop ax
mov ax, 0
mov returnTemp, ax
MOV AH, 4CH
INT 21H
MAIN ENDP
func PROC
mov ax, param1
cmp ax, 1
je L0
mov t0, 0
jmp L1
L0:
mov t0, 1
L1:
mov ax, t0
cmp ax, 0
je L2
mov ax, 1
mov returnTemp, ax
ret
L2:
mov ax, param1
cmp ax, 2
je L3
mov t1, 0
jmp L4
L3:
mov t1, 1
L4:
mov ax, t1
cmp ax, 0
je L5
mov ax, 1
mov returnTemp, ax
ret
L5:
mov ax, param1
sub ax, 1
mov t2, ax
push c_2
push d_2
push ax
push bx
push cx
push dx
push param1
mov ax, t2
mov param1, ax
CALL func
pop param1
pop dx
pop cx
pop bx
pop ax
pop d_2
pop c_2
mov ax, returnTemp
mov t3, ax
mov ax, t3
mov c_2, ax
mov ax, param1
sub ax, 2
mov t4, ax
push c_2
push d_2
push ax
push bx
push cx
push dx
push param1
mov ax, t4
mov param1, ax
CALL func
pop param1
pop dx
pop cx
pop bx
pop ax
pop d_2
pop c_2
mov ax, returnTemp
mov t5, ax
mov ax, t5
mov d_2, ax
mov ax, c_2
add ax, d_2
mov t6, ax
mov returnTemp, ax
ret
ret
func ENDP
PROC print
MOV BX, 10
CMP AX, 0
JGE NOTNEGATIVE
NEG AX
MOV CX, AX
MOV DL, '-'
MOV AH, 2
INT 21H
MOV AX, CX
NOTNEGATIVE:
MOV CX, 0
CMP AX, 0
JNE PUSHREM
MOV AH, 2
MOV DL, '0'
INT 21H
JMP PRINTEND
PUSHREM:
MOV DX, 0
DIV BX
PUSH DX
INC CX
CMP AX, 0
JNE PUSHREM
PRINTREM:
POP DX
ADD DL, '0'
MOV AH, 2
INT 21H
LOOP PRINTREM
PRINTEND:
MOV dl, 10
MOV ah, 02h
INT 21h
MOV dl, 13
MOV ah, 02h
INT 21h
ret
PRINT ENDP
