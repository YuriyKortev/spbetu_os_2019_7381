TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START:
	jmp BEGIN
;ДАННЫЕ
UNVAILABLE_MEM			db		'Segment address of unavailable memory: $'
UNVAILABLE_MEM_VALUE		db		'      ',10,13,'$'
ADRESS_GET			db		'Segment address of the environment: $'
ADRESS_GET_VALUE		db		'????',10,13,'$'
TAIL_M 				db 'Tail:    ', '$'
TAILEM 				db 50h DUP(' '), '$'
NOTAIL 				db 'There is no tail', 10, 13, '$'
SREDA_STR 			db 'The contents of the environment area in the symbolic form: ', 10,13,'$'
PATH_STR 			db 'Load module path: ',10,13,'$'

TETR_TO_HEX		PROC  near
			and      AL,0Fh
			cmp      AL,09
			jbe      NEXT
			add      AL,07 
NEXT:      		add      AL,30h
			ret 
TETR_TO_HEX		ENDP 
 
BYTE_TO_HEX		PROC  near 
;байт в AL переводится в два символа шестн. числа в AX
            push     CX
            mov      AH,AL
            call     TETR_TO_HEX 
	    xchg     AL,AH      
	    mov      CL,4      
	    shr      AL,CL    
 	    call     TETR_TO_HEX ;в AL старшая цифра
   	    pop      CX          ;в AH младшая           
	    ret 
BYTE_TO_HEX		ENDP

WRD_TO_HEX 	PROC  near 
      	push     BX
	mov      BH,AH
	call     BYTE_TO_HEX 
	mov      [DI],AH   
	dec      DI       
	mov      [DI],AL    
	dec      DI        
	mov      AL,BH      
	call     BYTE_TO_HEX   
	mov      [DI],AH       
	dec      DI           
	mov      [DI],AL        
	pop      BX          
	ret 
WRD_TO_HEX		ENDP 

BYTE_TO_DEC		PROC  near    
		push     CX      
		push     DX         
		xor      AH,AH     
		xor      DX,DX     
		mov      CX,10 
loop_bd:    	div      CX 
            	or       DL,30h
            	mov      [SI],DL
            	dec      SI
            	xor      DX,DX  
		cmp      AX,10  
		jae      loop_bd   
		cmp      AL,00h    
		je       end_l     
		or       AL,30h    
		mov      [SI],AL 
end_l:      	pop      DX 
            	pop      CX 
			ret 
BYTE_TO_DEC		ENDP

PRINT		PROC near
			mov AH,09h
            		int 21h
			ret
PRINT		ENDP


; Сегментный адрес недопустимой памяти, взятый из PSP
UNVAILABLE_MEM_F	PROC	near
			mov 	dx,offset UNVAILABLE_MEM
			call 	PRINT
			push 	ax
			mov 	ax,es:[2]
			mov	di, offset UNVAILABLE_MEM_VALUE
			add 	di,4
			call 	WRD_TO_HEX	
			pop 	ax
			mov 	dx,offset UNVAILABLE_MEM_VALUE
			call 	PRINT
			ret
UNVAILABLE_MEM_F	ENDP

; Сегментный адрес среды, передаваемой программе
ADRESS_GET_F			PROC	near
			mov 	dx,offset ADRESS_GET
			call 	PRINT
			push	ax
			mov 	ax,es:[2Ch]
			mov	di,offset ADRESS_GET_VALUE
			add 	di,4
			call	WRD_TO_HEX 
			pop	ax
			mov 	dx,offset ADRESS_GET_VALUE
			call 	PRINT
			ret
ADRESS_GET_F		ENDP

; Хвост командной строки в символьном виде
TAIL PROC near
	xor ch,ch
	mov cl,ss:[80h]
	
	cmp cl,0
	jne notnil
		mov dx,offset NOTAIL
		call PRINT
		ret
	notnil:
	
	mov dx,offset TAIL_M
	call PRINT
	
	mov bp,offset TAILEM
	T_cycle:
		mov di,cx
		mov bl,ss:[di+80h]
		mov ss:[bp+di-1],bl
	loop T_cycle
	
	mov dx,offset TAILEM
	call PRINT
	ret
TAIL ENDP

SREDA PROC
	mov dx,offset SREDA_STR
	call PRINT
	push es
	mov ax,es:[2Ch]
	mov es,ax
	mov ah,02h
	mov bx,0
	SREDA_loop:
		mov dl,es:[bx]
		int 21h
		inc	bx
		cmp byte ptr es:[bx],00h
		jne SREDA_loop;
		cmp word ptr es:[bx],0000h
		jne SREDA_loop
		
	add bx,4
	mov dx,offset PATH_STR
	call PRINT
	
	SREDA_loop2:
		mov dl,es:[bx]
		int 21h
		inc	bx
		cmp byte ptr es:[bx],00h
		jne SREDA_loop2	
	pop es
	ret
SREDA ENDP

BEGIN:			
			call 	UNVAILABLE_MEM_F
			call 	ADRESS_GET_F
			call 	TAIL
			call 	SREDA
			mov     AH,4Ch   
			int     21H
TESTPC 		ENDS           
END START     