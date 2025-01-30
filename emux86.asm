 ;All rights reserved
;Copyright belongs to Saul Ramirez
;You can use this code freely as long as credit is given

bits 64
default rel

;Para cambiar archivo
	;cambiar valor de resta a contador en Read_text_file


; Here comes the defines
	sys_read: equ 0	
	sys_write:	equ 1
	sys_nanosleep:	equ 35
	sys_nanosleep2:	equ 200
	sys_time:	equ 201
	sys_fcntl:	equ 72

	up_direction: equ 119
	down_direction: equ 115
	left_direction: equ 97
	right_direction: equ 100
	space_: equ 32
	start_: equ 49
	char_space: equ 32 
	char_O: equ 79
	char_U: equ 85
	char_T: equ 84
	char_X: equ 88

	%define pc 33
	%define sp 274877906928

	STDIN_FILENO: equ 0	
	F_SETFL:	equ 0x0004		;Se pasa como segundo argumento a la llamada al sistema fcntl para indicar que queremos cambiar los flags del descriptor de archivo.
	O_NONBLOCK: equ 0x0004		;Se utiliza como tercer argumento en la llamada al sistema fcntl para indicar que el descriptor de archivo debe operar en modo no bloqueante.

	;screen clean definition
	row_cells:	equ 32	;Numero de filas que caben en la pantalla
	column_cells: 	equ 64 ; set to any (reasonable) value you wish
	array_length:	equ row_cells * column_cells + row_cells ;(+ 32 caracteres de nueva línea)


	timespec:
    tv_sec  dq 0
    tv_nsec dq 25000000		;0.02 s

	;This is for cleaning up the screen
	clear:		db 27, "[2J", 27, "[H"
	clear_length:	equ $-clear

	; Start Message
	
		msg13: db "               ", 0xA, 0xD
		msg1: db "     		   TECNOLOGICO DE COSTA RICA        ", 0xA, 0xD
		msg14: db "               ", 0xA, 0xD
		msg2: db "     			  SAUL RAMIREZ       ", 0xA, 0xD
		msg5: db "     			 JUSTIN JIMENEZ      ", 0xA, 0xD
		msg15: db "               ", 0xA, 0xD
		msg6: db "               ", 0xA, 0xD
		msg7: db "               ", 0xA, 0xD
		msg8: db "               ", 0xA, 0xD
		msg9: db "               ", 0xA, 0xD
		msg16: db "               ", 0xA, 0xD 
		msg3: db "    	 E M U L A D O R  D E  R I S C - V  E N   X 8 6       ", 0xA, 0xD
		msg17: db "               ", 0xA, 0xD
		msg18: db "               ", 0xA, 0xD
		msg19: db "               ", 0xA, 0xD
		msg20: db "               ", 0xA, 0xD
		msg21: db "               ", 0xA, 0xD
		msg22: db "               ", 0xA, 0xD
		msg23: db "               ", 0xA, 0xD 
		msg24: db "               ", 0xA, 0xD
		msg25: db "               ", 0xA, 0xD
		msg26: db "               ", 0xA, 0xD 
		msg4: db "      		   PRESIONE ENTER PARA INICIAR        ", 0xA, 0xD
		msg1_length:	equ $-msg1
		msg2_length:	equ $-msg2
		msg3_length:	equ $-msg3
		msg4_length:	equ $-msg4
		msg5_length:	equ $-msg5
		msg13_length:	equ $-msg13
		msg14_length:	equ $-msg14
		msg15_length:	equ $-msg15
		msg16_length:	equ $-msg16
		msg17_length:	equ $-msg17 
		msg6_length:	equ $-msg6 
		msg7_length:	equ $-msg7 
		msg8_length:	equ $-msg8 
		msg9_length:	equ $-msg9 
		msg18_length:	equ $-msg18
		msg19_length:	equ $-msg19
		msg20_length:	equ $-msg20
		msg21_length:	equ $-msg21
		msg22_length:	equ $-msg22
		msg23_length:	equ $-msg23
		msg24_length:	equ $-msg24
		msg25_length:	equ $-msg25
		msg26_length:	equ $-msg26
	;

; Usefull macros (Como funciones reutilizables)
 
	%macro setnonblocking 0		;Configura la entrada estándar para que funcione en modo no bloqueante
		mov rax, sys_fcntl
		mov rdi, STDIN_FILENO
		mov rsi, F_SETFL
		mov rdx, O_NONBLOCK
		syscall
	%endmacro

	%macro unsetnonblocking 0	;Restablece la entrada estándar al modo bloqueante
		mov rax, sys_fcntl
		mov rdi, STDIN_FILENO
		mov rsi, F_SETFL
		mov rdx, 0
		syscall
	%endmacro

	%macro full_line 0			;Crea una línea completa de 'X' seguida de una nueva línea
		times column_cells db "X"
		db 0x0a, 0xD
	%endmacro
 
	%macro hollow_line 0		;Crea una línea con 'X' en los extremos y espacios en el medio, seguida de una nueva línea
		db "X"
		times column_cells-2 db char_space	;A 80 le resta las 2 X de los extremos e imprime 78 espacios
		db "X", 0x0a, 0xD
	%endmacro


	%macro print 2				;Imprime una cadena especificada en la salida estándar
		mov eax, sys_write
		mov edi, 1 	; stdout
		mov rsi, %1				;Parametro 1 que se pasa en donde se llama al macro
		mov edx, %2				;Parametro 2
		syscall
	%endmacro

	%macro getchar 0			;Lee un solo carácter de la entrada estándar y lo almacena en input_char
		mov     rax, sys_read
		mov     rdi, STDIN_FILENO
		mov     rsi, input_char
		mov     rdx, 1 ; number of bytes
		syscall         ;read text input from keyboard
	%endmacro

	%macro sleeptime 0			;Suspende la ejecución del programa durante el tiempo especificado
		mov eax, sys_nanosleep
		mov rdi, timespec
		xor esi, esi		; ignore remaining time in case of call interruption
		syscall			; sleep for tv_sec seconds + tv_nsec nanoseconds
	%endmacro
;

global _start
section .bss
    data_bin resb 5000                 ; Buffer para almacenar los datos leídos (1000 bytes)
    text_bin resb 60000
	datamemory resq 1000
	gp_memory resq 3000
	stack_memory resq 1000
	input_char resq 1
	buffer resb 4                    ; Buffer para leer cada porción (4 bytes)
    file_descriptor resd 1               ; Descriptor del archivo
    contador_d resq 1                      ; Contador para el índice en data_bin
    contador_data resq 1 
	contador_t resq 1
	contador resq 1
	bytes_read resq 1                    ; Bytes leídos
	
	PC resq 1
	PCdata resq 1
	PC1 resq 1
	PCd resq 1
	PCgp resq 1
	PCsp resq 1

	bintodec_reg resq 1                        ; Buffer para el número convertido
	
	fila_bits_s resb 32   ; Variable para almacenar los 32 bits seleccionados
    fila_bits_d resb 32  

	Rd resq 1
	Rs1 resq 1
	Rs2 resq 1
	;Registros
		reg_zero resq 1
		reg_ra resq 1
		reg_sp resq 1
		reg_gp resq 1
		reg_tp resq 1
		reg_t0 resq 1
		reg_t1 resq 1
		reg_t2 resq 1
		reg_s0 resq 1
		reg_s1 resq 1
		reg_a0 resq 1
		reg_a1 resq 1
		reg_a2 resq 1
		reg_a3 resq 1
		reg_a4 resq 1
		reg_a5 resq 1
		reg_a6 resq 1
		reg_a7 resq 1
		reg_s2 resq 1
		reg_s3 resq 1
		reg_s4 resq 1
		reg_s5 resq 1
		reg_s6 resq 1
		reg_s7 resq 1
		reg_s8 resq 1
		reg_s9 resq 1
		reg_s10 resq 1
		reg_s11 resq 1
		reg_t3 resq 1
		reg_t4 resq 1
		reg_t5 resq 1
		reg_t6 resq 1 
	;

	Inm_UJ resq 1
	Inm_I resq 1
	Inm_U resq 1
	Inm_S resq 1
	Inm_SB resq 1
	Inm_D resq 1

	update_counter resd 1   ; Reservar 4 bytes para el contador (inicializado a 0)
;

section .data

	format db " %s ", 0xA, 0   ; Formato para printf (para imprimir un número entero)
	format1 db " %d ", 0xA, 0
	mensaje1 db " ", 0xA, 0  
 
	PC_msj db " Pc: %d ", 0 

	;Opcodes
		opcode_msj_ecall db " Opcode %s instruccion: ecall ", 0xA, 0xA, 0
			opcode_ecall db "01110011", 0  
		opcode_msj_TipoR db " Opcode %s tipo R, ", 0
			instruccion_msj db "%s", 0
			instruccion_msj_add db " instruccion: add ", 0xA, 0
			instruccion_msj_sub db " instruccion: sub ", 0xA, 0
			instruccion_msj_sll db " instruccion: sll ", 0xA, 0
			opcode_tipoR db "00110011", 0  
		opcode_msj_TipoUJ db " Opcode %s tipo UJ, instruccion: jal", 0xA, 0
			opcode_tipoUJ_jal db "01101111", 0  
		opcode_msj_TipoU db " Opcode %s tipo U, instruccion: lui", 0xA, 0
			opcode_tipoU_lui db "00110111", 0 
		opcode_msj_TipoU2 db " Opcode %s tipo U, instruccion: auipc", 0xA, 0
			opcode_tipoU_auipc db "00010111", 0 
		opcode_msj_TipoI db " Opcode %s", 0
			opcode_tipoI db "00000011 tipo I, instruccion: lw", 0xA, 0		 
			opcode_tipoI1 db "00010011 tipo I instruccion: addi", 0xA, 0		 
			opcode_tipoI_jalr db "01100111 tipo I instruccion: jalr", 0xA, 0
		opcode_msj_TipoS db " Opcode %s tipo S, instruccion: sw", 0xA, 0
			opcode_tipoS db "00100011", 0		;sw 
		opcode_msj_TipoSB db " Opcode %s tipo SB", 0
			instruccion_msj_beq db " Instruccion: beq", 0xA, 0
			instruccion_msj_bne db " Instruccion: bne", 0xA, 0
			instruccion_msj_blt db " Instruccion: blt", 0xA, 0
			instruccion_msj_bge db " Instruccion: bge", 0xA, 0
			opcode_tipoSB db "01100011", 0	
	;


	Rd_msj_rd db " Rd:%s = ", 0
	Rd_num_rd db "%lld ", 0xA, 0 
	Rs1_msj db " Rs1:%s = ", 0
	Rs1_num db "%lld ", 0xA, 0
	Rs2_msj db " Rs2:%s = ", 0
	Rs2_num db "%lld ", 0xA, 0
	;Registros
		registro_zero db " zero", 0
		registro_ra db " ra", 0
		registro_sp dq " sp", 0
		registro_gp dq " gp", 0
		registro_tp db " tp", 0
		registro_t0 db " t0", 0
		registro_t1 db " t1", 0
		registro_t2 db " t2", 0
		registro_s0 db " s0", 0
		registro_s1 db " s1", 0
		registro_a0 db " a0", 0
		registro_a1 db " a1", 0
		registro_a2 db " a2", 0
		registro_a3 db " a3", 0
		registro_a4 db " a4", 0
		registro_a5 db " a5", 0
		registro_a6 db " a6", 0
		registro_a7 db " a7", 0
		registro_s2 db " s2", 0
		registro_s3 db " s3", 0
		registro_s4 db " s4", 0
		registro_s5 db " s5", 0
		registro_s6 db " s6", 0
		registro_s7 db " s7", 0
		registro_s8 db " s8", 0
		registro_s9 db " s9", 0
		registro_s10 db " s10", 0
		registro_s11 db " s11", 0
		registro_t3 db " t3", 0
		registro_t4 db " t4", 0
		registro_t5 db " t5", 0
		registro_t6 db " t6", 0 
	;

	Inmediato_msj db " Inmediato: %d ", 0xA, 0
	salto_msj db " salta al pc: %d ", 0xA, 0xA, 0 
	lw_data_msj db " se descargo %d de data", 0xA, 0xA, 0 
	lw_stack_msj db " se descargo %d de stack", 0xA, 0xA, 0 
	lw_gp_msj db " se descargo %d de gp", 0xA, 0xA, 0 
	lw_input_msj db " se descargo %d en input", 0xA, 0xA, 0 
	sw_data_msj db " se cargo %d en data", 0xA, 0xA, 0 
	sw_stack_msj db " se cargo %d en stack", 0xA, 0xA, 0 
	sw_gp_msj db " se cargo %d en gp", 0xA, 0xA, 0 
	sw_input_msj db " se cargo %d en input", 0xA, 0xA, 0 

    filename_d db "pong_data_bin", 0       ; Nombre del archivo binario
		data_f db " %s ", 0xA, 0   ; Formato para printf (para imprimir un número entero)
		data_msj db "Archivo data:", 0  
	filename_t db "pong_text_bin", 0  
		text_f db " %s ", 0xA, 0   ; Formato para printf (para imprimir un número entero)
		text_msj db "Archivo text:", 0  
	file_not_opened db 'Error al abrir archivo', 0xA, 0
    dataMermory_title1 db " %s ", 0xA, 0 
	dataMermory_title2 db " Data convertida a decimal: ", 0 
	dataMermory_datos db " %d ", 0xA, 0 

	
	newline db 0xA, 0
   

	; Added for the terminal issue	
		termios:        times 36 db 0	;Define una estructura de 36 bytes inicializados a 0. Esta estructura es utilizada para almacenar las configuraciones del terminal
		stdin:          equ 0			;Define el descriptor de archivo para la entrada estándar (stdin), que es 0
		ICANON:         equ 1<<1		;Canonico la entrada no se envía al programa hasta que el usuario presiona Enter
		ECHO:           equ 1<<3		;Bandera que habilita o deshabilita este modo
		VTIME: 			equ 5
		VMIN:			equ 6
		CC_C:			equ 18
	;
	board:
		%rep 32                  ; Repite 32 filas
            times 64 db " "       ; Cada fila tiene 64 caracteres 'X'
            db 0x0A               ; Nueva línea al final de cada fila
        %endrep
	board_size:   equ   $ - board 

;
 

section .text
     
	extern printf
	extern strcpy 
	extern atoi 
	extern strtol
	extern strcmp 
	extern strlen
;;;;;;;;;;;;;;;;;;;;for the working of the terminal;;;;;;;;;;;;;;;;;
canonical_off:										;La entrada se procese carácter por carácter sin esperar a que se presione Enter.
        call read_stdin_termios						;Guarda los atributos actuales del terminal en la variable termios

        ; clear canonical bit in local mode flags	
        push rax						
        mov eax, ICANON								;Carga el valor de la constante ICANON (que representa el bit del modo canónico) en eax
        not eax										;Niega todos los bits en eax
        and [termios+12], eax						;Limpia el bit canónico en las banderas de modo local
		mov byte[termios+CC_C+VTIME], 0				;Establecen VTIME y VMIN en 0 para que el terminal no espere caracteres adicionales
		mov byte[termios+CC_C+VMIN], 0
        pop rax

        call write_stdin_termios					;Escribe los atributos modificados de termios de vuelta al terminal
        ret

echo_off:											;No se muestran los caracteres introducidos
        call read_stdin_termios

        ; clear echo bit in local mode flags
        push rax
        mov eax, ECHO
        not eax
        and [termios+12], eax
        pop rax

        call write_stdin_termios
        ret

canonical_on:										;La entrada se procesa en líneas completas. Espera hasta que el usuario presione Enter
        call read_stdin_termios

        ; set canonical bit in local mode flags
        or dword [termios+12], ICANON
		mov byte[termios+CC_C+VTIME], 0			;Tiempo en decisegundos que el terminal espera para la entrada.
		mov byte[termios+CC_C+VMIN], 1			;El número mínimo de caracteres que se deben leer
        call write_stdin_termios
        ret

echo_on:											;Se muestran los caracteres introducidos
        call read_stdin_termios

        ; set echo bit in local mode flags
        or dword [termios+12], ECHO

        call write_stdin_termios
        ret

read_stdin_termios:									;Lee los atributos del terminal y los guarda en la variable termios
        push rax
        push rbx
        push rcx
        push rdx

        mov eax, 36h
        mov ebx, stdin
        mov ecx, 5401h
        mov edx, termios
        int 80h

        pop rdx
        pop rcx
        pop rbx
        pop rax
        ret

write_stdin_termios:								;Escribe los atributos del terminal utilizando la llamada al sistema 
        push rax
        push rbx
        push rcx
        push rdx

        mov eax, 36h
        mov ebx, stdin
        mov ecx, 5402h
        mov edx, termios
        int 80h

        pop rdx
        pop rcx
        pop rbx
        pop rax
        ret

;;;;;;;;;;;;;;;;;;;;end for the working of the terminal;;;;;;;;;;;;


_start:  

	call canonical_on
	print clear, clear_length
	call start_screen  

	call canonical_off
    call Read_data_file      ; Llamada para leer el archivo
	call Read_text_file 
	;call Imprimir_data_bin
	;call Imprimir_text_bin  
	call Data_mermory
	;call Print_data_mermory
	mov qword[PC], 0
	mov qword[contador], 0 
	mov r9, 274877906928
		mov qword [reg_sp], r9
	mov qword [reg_gp], 268468224 
 
	.loop_main:  
 
		mov qword[Rd], 0
		mov qword[Rs1], 0
		mov qword[Rs2], 0

		call update_display_if_needed
		;print board, board_size	
   
	
		;Actualizar la posicion en el arreglo
			mov r9, qword [PC]  
			imul r9, pc					;PC*33
			mov qword [contador], r9

		;Suma el PC y compara si se llego al final del archivo
			add qword [PC], 1 
			mov r9, qword [PC]  
			mov r8, qword [contador_t]  
			cmp r9, r8
			jg .finish

		;Imprimir PC 
		 
 
			mov rdi, format   	  	   ; Dirección del formato (primer argumento)
			mov rsi, mensaje1			   ; Cantidad total de bytes leídos (segundo argumento)
			xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
			call printf 
		;
		;Extrae la fila de 32 bits 
	call Fila
		;
	call Deco_opcode 
	;
		.read_more:	
			getchar						;Llama a la macro getchar para leer un carácter de la entrada de teclado 
			
			cmp rax, 1
			jne .done
			
			mov al,[input_char]
			.start:
				cmp al, '1'
				jne .up_in
				mov qword [input_char], start_ 
				jmp .done 

			.up_in:
				cmp al, 'w'
				jne .down_in
				mov qword [input_char], 119
				jmp .done

			.down_in:
				cmp al, 's'
				jne .up_in2
				mov qword [input_char], 115 
				jmp .done

			.up_in2:
				cmp al, 'o'
				jne .down_in2
				mov qword [input_char], 111
				jmp .done

			.down_in2:
				cmp al, 'k'
				jne .left_in
				mov qword [input_char], 108 
				jmp .done
			
			.left_in:
				cmp al, 'a'
				jne .right_in
				mov qword [input_char], left_direction 
				jmp .done

			.right_in:
				cmp al, 'd'
				jne .shot_in
				mov qword [input_char], right_direction 
				jmp .done		

			.shot_in:
				cmp al, 32
				jne .go_out
				mov qword [input_char], space_ 
				jmp .done	

			.go_out:

				cmp al, 'q' 
				je .finish

				jmp .read_more
			
			.done:	
				 
				;unsetnonblocking		
				;sleeptime	
				;print clear, clear_length
				jmp .loop_main 

			;print clear, clear_length
			

	.finish:

    call exit

Read_data_file:

    ; Abrir el archivo (syscall open)
    mov rax, 2                      ; syscall number for sys_open
    mov rdi, filename_d                ; Nombre del archivo
    mov rsi, 0                       ; Flags: O_RDONLY (lectura)
    syscall
    test rax, rax                    ; Verifica si se abrió el archivo correctamente
    js .file_error                   ; Si no, maneja el error

    ; Almacenar el descriptor del archivo
    mov [file_descriptor], eax  
 
		; Leer el archivo (syscall read)
		mov rax, 0                       ; syscall number for sys_read
		mov rdi, [file_descriptor]        ; Descriptor del archivo
		mov rsi, data_bin                   ; Buffer donde se almacenarán los datos
		mov rdx, 5000                   ; Leer hasta 300 bites, cantidad de bits en el archivo
		syscall

		; Llamada a strlen
		mov rdi, data_bin                  ; Pasa el argumento (puntero a la cadena)
		call strlen 

		; Guardar la longitud en 
		;sub rax, 118	;Se resta el numero de filas  
		xor rdx, rdx        ; Poner rdx a 0 (parte alta del dividendo)
		mov rbx, pc         ; Divisor 
		div rbx             ; Divide rdx:rax entre rbx

		mov qword [contador_d], rax
	
		jmp .close_file

	.file_error:
		; Error al abrir el archivo, muestra un mensaje
		mov rax, 1                      ; syscall: write
		mov rdi, 1                      ; stdout
		mov rsi, file_not_opened         ; mensaje de error
		mov rdx, 23                     ; longitud del mensaje
		syscall                         ; llamada al sistema
		jmp .exit_f                     ; Salir del programa

	.close_file:
		; Cerrar el archivo (syscall close)
		mov rax, 3                       ; syscall number for sys_close
		mov rdi, [file_descriptor]        ; Descriptor del archivo
		syscall

	.exit_f:


	ret

Read_text_file:
    ; Abrir el archivo (syscall open)
    mov rax, 2                      ; syscall number for sys_open
    mov rdi, filename_t                ; Nombre del archivo
    mov rsi, 0                       ; Flags: O_RDONLY (lectura)
    syscall
    test rax, rax                    ; Verifica si se abrió el archivo correctamente
    js .file_error                   ; Si no, maneja el error

    ; Almacenar el descriptor del archivo
    mov [file_descriptor], eax  
	mov qword [contador_t], 0

	; Leer el archivo (syscall read)
		mov rax, 0                       ; syscall number for sys_read
		mov rdi, [file_descriptor]        ; Descriptor del archivo
		lea rsi, [text_bin]                   ; Buffer donde se almacenarán los datos
		mov rdx,  60000                     ; Leer hasta 4 bytes
		syscall

		; Llamada a strlen
		mov rdi, text_bin                  ; Pasa el argumento (puntero a la cadena)
		call strlen 

		; Guardar la longitud en 
		;sub rax, 118	;Se resta el numero de filas  
		xor rdx, rdx        ; Poner rdx a 0 (parte alta del dividendo)
		mov rbx, pc         ; Divisor 
		div rbx             ; Divide rdx:rax entre rbx

		mov qword [contador_t], rax

	jmp .close_file                    ; si sí, salta a cerrar el archivo
   


	.file_error:
		; Error al abrir el archivo, muestra un mensaje
		mov rax, 1                      ; syscall: write
		mov rdi, 1                      ; stdout
		mov rsi, file_not_opened         ; mensaje de error
		mov rdx, 23                     ; longitud del mensaje
		syscall                         ; llamada al sistema
		jmp .exit_f                     ; Salir del programa

	.close_file: 

		

		; Cerrar el archivo (syscall close)
		mov rax, 3                       ; syscall number for sys_close
		mov rdi, [file_descriptor]        ; Descriptor del archivo
		syscall

	.exit_f:

	ret

Imprimir_data_bin:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi
 

	mov rdi, data_f     ; Dirección del formato (primer argumento)
	mov rsi, data_msj
	xor rax, rax        ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	call printf 
 
	;Imprimir el contenido leído (syscall write)
    mov rax, 1          ; syscall number for sys_write
    mov rdi, 1          ; Descriptor de salida estándar (stdout)
    lea rsi, data_bin   ; Buffer con el contenido almacenado
    mov rdx, 5000			 ; Número de bites a imprimir (cantidad acumulada en contador)
    syscall
 

	; Salto de línea después del número
    mov rax, 1                   ; syscall: write
    mov rdi, 1                   ; file descriptor: stdout
    mov rsi, newline             ; Puntero al salto de línea
    mov rdx, 1                   ; Longitud del salto de línea
    syscall
  

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

	ret

Imprimir_text_bin:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	mov rdi, text_f    ; Dirección del formato (primer argumento)
	mov rsi, text_msj
	xor rax, rax        ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	call printf 

	;Imprimir el contenido leído (syscall write)
    mov rax, 1          ; syscall number for sys_write
    mov rdi, 1          ; Descriptor de salida estándar (stdout)
    mov rsi, text_bin   ; Buffer con el contenido almacenado
    mov rdx, 60000		; Número de bytes a imprimir (cantidad acumulada en contador)
  	syscall

	; Salto de línea después del número
    mov rax, 1                   ; syscall: write
    mov rdi, 1                   ; file descriptor: stdout
    mov rsi, newline             ; Puntero al salto de línea
    mov rdx, 1                   ; Longitud del salto de línea
    syscall

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

	ret

Printf:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	; Imprimir la cantidad de bytes leídos con printf

		; Copiar la cadena de .data a .bss
			;lea rsi, [msj]          ; Dirección de la cadena original
			;lea rdi, [formato]         ; Dirección del espacio reservado en .bss
			;mov rcx, 11                ; Número de bytes a copiar (incluyendo el terminador nulo)
			;rep mo

		;mov rdi, format     ; Dirección del formato (primer argumento)
		;mov rsi, mensaje1 ; Cantidad total de bytes leídos (segundo argumento)
		;xor rax, rax        ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
		;call printf         ; Llamar a la función printf


	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

	ret

; 
 
Deco_opcode:

	push rax
	push rcx
	push rdx
	push rdi	
	push rsi 

	call Bin_to_dec_opcode
	mov r8, qword[bintodec_reg]
 
		; Comparar con opcode_ecall
			cmp r8, 115
			jne .R       					 ; Saltar si los opcodes son iguales
		
				;mov rdi, opcode_msj_ecall  	  	   ; Dirección del formato (primer argumento)
				;mov rsi, opcode_ecall			   ; Cantidad total de bytes leídos (segundo argumento)
				;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
				;call printf      					   ; Llamar a la función printf

				jmp .no
			.R:

		; Comparar con opcode_msj_TipoR
			cmp r8, 51
			jne .I       					 ; Saltar si los opcodes son iguales
		
				;mov rdi, opcode_msj_TipoR  	  	   ; Dirección del formato (primer argumento)
				;mov rsi, opcode_tipoR			   ; Cantidad total de bytes leídos (segundo argumento)
				;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
				;call printf      					   ; Llamar a la función printf

				call Tipo_R

				jmp .no
			.I:
		; Comparar con opcode_msj_TipoI
			cmp r8, 3
			jne .I1       					 ; Saltar si los opcodes son iguales
		
				;mov rdi, opcode_msj_TipoI  	  	   ; Dirección del formato (primer argumento)
				;mov rsi, opcode_tipoI			   ; Cantidad total de bytes leídos (segundo argumento)
				;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
				;call printf      					   ; Llamar a la función printf

				call Lw

				jmp .no
			.I1:
		; Comparar con opcode_msj_TipoI
			cmp r8, 19
			jne .I2      					 ; Saltar si los opcodes son iguales
		
				;mov rdi, opcode_msj_TipoI  	  	   ; Dirección del formato (primer argumento)
				;mov rsi, opcode_tipoI1			   ; Cantidad total de bytes leídos (segundo argumento)
				;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
				;call printf      					   ; Llamar a la función printf

				call Addi

				jmp .no
			.I2:
		
		; Comparar con opcode_msj_TipoI
			cmp r8, 103
			jne .UJ       					 ; Saltar si los opcodes son iguales
		
				;mov rdi, opcode_msj_TipoI  	  	   ; Dirección del formato (primer argumento)
				;mov rsi, opcode_tipoI_jalr			   ; Cantidad total de bytes leídos (segundo argumento)
				;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
				;call printf      					   ; Llamar a la función printf

				call Jalr

				jmp .no
			.UJ:

		; Comparar con opcode_tipoUJ
			cmp r8, 111
			jne .U       					 ; Saltar si los opcodes son iguales
		
				;mov rdi, opcode_msj_TipoUJ   	  	   ; Dirección del formato (primer argumento)
				;mov rsi, opcode_tipoUJ_jal			   ; Cantidad total de bytes leídos (segundo argumento)
				;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
				;call printf      					   ; Llamar a la función printf
				
				call Tipo_UJ

				jmp .no
			.U:
		; Comparar con opcode_msj_TipoU
			cmp r8, 55 	
			jne .U2       					 ; Saltar si los opcodes son iguales
		
				;mov rdi, opcode_msj_TipoU   	  	   ; Dirección del formato (primer argumento)
				;mov rsi, opcode_tipoU_lui			   ; Cantidad total de bytes leídos (segundo argumento)
				;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
				;call printf      					   ; Llamar a la función printf
				
				call Lui
				
				jmp .no
			.U2:


		; Comparar con opcode_msj_TipoU
			cmp r8, 23
			jne .S       					 ; Saltar si los opcodes son iguales
		
				;mov rdi, opcode_msj_TipoU2  	  	   ; Dirección del formato (primer argumento)
				;mov rsi, opcode_tipoU_auipc			   ; Cantidad total de bytes leídos (segundo argumento)
				;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
				;call printf      					   ; Llamar a la función printf
				
				call Auipc
				
				jmp .no
			.S:

		; Comparar con opcode_msj_TipoS
			cmp r8, 35
			jne .SB       					 ; Saltar si los opcodes son iguales
		
				;mov rdi, opcode_msj_TipoS   	  	   ; Dirección del formato (primer argumento)
				;mov rsi, opcode_tipoS			   ; Cantidad total de bytes leídos (segundo argumento)
				;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
				;call printf      					   ; Llamar a la función printf

				call Sw
				jmp .no
			.SB:

		; Comparar con opcode_msj_TipoSB
			cmp r8, 99
			jne .no       					 ; Saltar si los opcodes son iguales
		
				;mov rdi, opcode_msj_TipoSB   	  	   ; Dirección del formato (primer argumento)
				;mov rsi, opcode_tipoSB			   ; Cantidad total de bytes leídos (segundo argumento)
				;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
				;call printf      					   ; Llamar a la función printf

				call Tipo_SB

				jmp .no
	;
		 
	.no:
			; Salto de línea después del número
			;mov rax, 1                   ; syscall: write
			;mov rdi, 1                   ; file descriptor: stdout
			;mov rsi, newline             ; Puntero al salto de línea
			;mov rdx, 1                   ; Longitud del salto de línea
			;syscall	 
		 			
	 		; Salto de línea después del número
			;mov rax, 1                   ; syscall: write
			;mov rdi, 1                   ; file descriptor: stdout
			;lea rsi, [fila_bits_s+25]             ; Puntero al salto de línea
			;mov rdx, 8                   ; Longitud del salto de línea
			;syscall

			 ;Salto de línea después del número
			;mov rax, 1                   ; syscall: write
			;mov rdi, 1                   ; file descriptor: stdout
			;mov rsi, newline             ; Puntero al salto de línea
			;mov rdx, 1                   ; Longitud del salto de línea
			;syscall	 
							
 
 

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

    ret

;
Data_mermory:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi 

	mov qword [contador_data], 0 
	mov qword [PCdata], 0 
	.loop_data:

		;Actualizar la posicion en el arreglo
		mov r9, qword [PCdata]  
		imul r9, pc					;PCdata*33
		mov qword [contador_data], r9

		mov rbx, qword [contador_data]                            ; Contador de posición en el buffer
	
		lea rsi, [data_bin + rbx]                ; Apuntar al inicio del siguiente bloque de 32 caracteres
		lea rdi, [fila_bits_d ]                    ; Destino del buffer de instrucción
		mov rcx, 32                             ; Número de caracteres a copiar
		cld                                      ; Dirección de incremento en movsb
		rep movsb                                ; Copiar exactamente 32 caracteres desde `text_bin` a `instruccion`
	
		call Bin_to_dec_Data
		mov rcx, qword[Inm_D]
		mov rax, qword[PCdata] 

		imul rax, 8 

		mov qword[datamemory + rax], rcx
 

		;Suma el PC y compara si se llego al final del archivo
		add qword [PCdata], 1 
		mov r9, qword [PCdata]  
		mov r8, qword [contador_d]  
		cmp r9, r8
		jge .finish_data

		jmp .loop_data

 
	.finish_data:

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

    ret

;
Print_data_mermory:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi 
 
	mov qword [PCdata], 0 

	mov rdi, dataMermory_title1  	  	   ; Dirección del formato (primer argumento)
	mov rsi, dataMermory_title2			   ; Cantidad total de bytes leídos (segundo argumento)
	xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	call printf  

	.loop_data1:

		mov rbx, qword [PCdata]                            ; Contador de posición en el buffer
	
		imul rbx, 8 

		mov rax, qword[datamemory + rbx]                   ; Copiar exactamente 32 caracteres desde `text_bin` a `instruccion`

		mov rdi, dataMermory_datos  	  	   ; Dirección del formato (primer argumento)
		mov rsi, rax						   ; Cantidad total de bytes leídos (segundo argumento)
		xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
		call printf   

		;Suma el PC y compara si se llego al final del archivo
		add qword [PCdata], 1 
		mov r9, qword [PCdata]  
		mov r8, qword [contador_d]  
		cmp r9, r8
		jge .finish_data1  

		jmp .loop_data1
  
	.finish_data1:
	mov rdi, format  	  	   ; Dirección del formato (primer argumento)
	mov rsi, mensaje1			   ; Cantidad total de bytes leídos (segundo argumento)
	xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	call printf  

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

    ret
; 
Fila:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi 

	mov rbx, qword [contador]                            ; Contador de posición en el buffer
 
    lea rsi, [text_bin + rbx]                ; Apuntar al inicio del siguiente bloque de 32 caracteres
    lea rdi, [fila_bits_s ]                    ; Destino del buffer de instrucción
    mov rcx, 32                             ; Número de caracteres a copiar
	cld                                      ; Dirección de incremento en movsb
    rep movsb                                ; Copiar exactamente 32 caracteres desde `text_bin` a `instruccion`

	;add qword [contador], pc

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

    ret

;

update_display_if_needed:
    ; Verificar si es necesario actualizar el display
    ; (puedes usar un contador para decidir cuándo)
    cmp dword [update_counter], 100  ; Actualizar cada 1000 instrucciones
    jl .skip_update

    ; Limpiar la pantalla y redibujar el estado del juego
    call update_board
    print clear, clear_length
    print board, board_size

    ; Reiniciar el contador
    mov dword [update_counter], 0

    ; Pausar brevemente para dar tiempo al jugador para ver la pantalla
    sleeptime

	.skip_update:
		; Incrementar el contador
		inc dword [update_counter]

 ret

update_board:
    mov rsi, gp_memory          ; Apuntar a la memoria de colores
    mov rdi, board              ; Apuntar al inicio del tablero
    mov rcx, 2048               ; Número de elementos en gp_memory
    mov rbx, 0                  ; Contador para las columnas

	.update_loop:
		cmp rcx, 0                  ; Comprobar si hemos procesado todos los elementos
		je .end_update              ; Salir si hemos terminado

		mov eax, [rsi]              ; Cargar el valor de color (4 bytes)
		
		; Comparar el color y mapearlo al carácter correspondiente
		cmp eax, 0			        ; Comparar con negro
		je .set_space               ; Si es negro, mapea a un espacio (' ')

		cmp eax, 16777215	        ; Comparar con blanco
		je .set_X                   ; Si es blanco, mapea a 'X'

		cmp eax, 16711680         ; Comparar con rojo
		je .set_X                   ; Si es rojo, mapea a 'R'

		cmp eax, 65535         ; Comparar con cyan
		je .set_X                   ; Si es cyan, mapea a 'C'

		cmp eax, 16753920         ; Comparar con naranja
		je .set_X                   ; Si es naranja, mapea a 'O'

		; Default case (si no hay coincidencias, usar un carácter por defecto)
		mov byte [rdi], 'X'
		jmp .continue_loop

	.set_space:
		mov byte [rdi], ' '         ; Espacio para negro
		jmp .continue_loop

	.set_X:
		mov byte [rdi], 'X'         ; 'X' para blanco
		jmp .continue_loop
 
	.continue_loop:
		 
		inc rdi                     ; Avanzar al siguiente carácter en el tablero
		add rsi, 8                  ; Avanzar al siguiente color en gp_memory
		inc rbx                     ; Incrementar el contador de columnas

		cmp rbx, 64                 ; ¿Hemos alcanzado 64 columnas?
		jne .skip_newline

		; Si hemos alcanzado 64 columnas, insertar un salto de línea
		mov byte [rdi], 0x0A        ; Insertar salto de línea
		inc rdi                    ; Avanzar el puntero del tablero
		mov rbx, 0                  ; Reiniciar el contador de columnas


	.skip_newline:
		dec rcx                     ; Decrementar el contador de elementos
		jmp .update_loop

	.end_update:
		
 ret

;

Write_RD:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi
 
	call Bin_to_dec_rd
	mov r8, qword [bintodec_reg]

	;Registro para rd
		cmp r8, 0
		jne .rd_ra 
			mov qword [reg_zero], 0
			mov qword [Rd], 0
				mov rsi, registro_zero
			jmp .fin_rd
		.rd_ra:

		cmp r8, 1
		jne .rd_sp
			mov r8, qword[Rd]
			mov qword [reg_ra], r8
				mov rsi, registro_ra
			jmp .fin_rd
		.rd_sp:

		cmp r8, 2
		jne .rd_gp  
			mov qword r9, qword [Rd]
			mov qword [reg_sp], r9
			mov rsi, registro_sp
			jmp .fin_rd
		.rd_gp:

		cmp r8, 3
		jne .rd_tp  
				mov rsi, registro_gp
			jmp .fin_rd
		.rd_tp:

		cmp r8, 4
		jne .rd_t0
			mov r8, qword[Rd]
			mov qword [reg_tp], r8
				mov rsi, registro_tp
			jmp .fin_rd
		.rd_t0:

		cmp r8, 5
		jne .rd_t1
			mov r8, qword[Rd]
			mov qword [reg_t0], r8
				mov rsi, registro_t0
			jmp .fin_rd
		.rd_t1:

		cmp r8, 6
		jne .rd_t2
			mov r8, qword[Rd]
			mov qword [reg_t1], r8
				mov rsi, registro_t1
			jmp .fin_rd
		.rd_t2:

		cmp r8, 7
		jne .rd_s0
			mov r8, qword[Rd]
			mov qword [reg_t2], r8
				mov rsi, registro_t2
			jmp .fin_rd
		.rd_s0:

		cmp r8, 8
		jne .rd_s1
			mov r8, qword[Rd]
			mov qword [reg_s0], r8
				mov rsi, registro_s0
			jmp .fin_rd
		.rd_s1:

		cmp r8, 9
		jne .rd_a0
			mov r8, qword[Rd]
			mov qword [reg_s1], r8
				mov rsi, registro_s1
			jmp .fin_rd
		.rd_a0:

		cmp r8, 10
		jne .rd_a1
			mov r8, qword[Rd]
			mov qword [reg_a0], r8
				mov rsi, registro_a0
			jmp .fin_rd
		.rd_a1:

		cmp r8, 11
		jne .rd_a2
			mov r8, qword[Rd]
			mov qword [reg_a1], r8
				mov rsi, registro_a1
			jmp .fin_rd
		.rd_a2:

		cmp r8, 12
		jne .rd_a3
			mov r8, qword[Rd]
			mov qword [reg_a2], r8
				mov rsi, registro_a2
			jmp .fin_rd
		.rd_a3:

		cmp r8, 13
		jne .rd_a4
			mov r8, qword[Rd]
			mov qword [reg_a3], r8
				mov rsi, registro_a3
			jmp .fin_rd
		.rd_a4:

		cmp r8, 14
		jne .rd_a5
			mov r8, qword[Rd]
			mov qword [reg_a4], r8
				mov rsi, registro_a4
			jmp .fin_rd
		.rd_a5:

		cmp r8, 15
		jne .rd_a6
			mov r8, qword[Rd]
			mov qword [reg_a5], r8
				mov rsi, registro_a5
			jmp .fin_rd
		.rd_a6:

		cmp r8, 16
		jne .rd_a7
			mov r8, qword[Rd]
			mov qword [reg_a6], r8
				mov rsi, registro_a6
			jmp .fin_rd
		.rd_a7:

		cmp r8, 17
		jne .rd_s2
			mov r8, qword[Rd]
			mov qword [reg_a7], r8
				mov rsi, registro_a7
			jmp .fin_rd
		.rd_s2:

		cmp r8, 18
		jne .rd_s3
			mov r8, qword[Rd]
			mov qword [reg_s2], r8
				mov rsi, registro_s2
			jmp .fin_rd
		.rd_s3:

		cmp r8, 19
		jne .rd_s4
			mov r8, qword[Rd]
			mov qword [reg_s3], r8
				mov rsi, registro_s3
			jmp .fin_rd
		.rd_s4:

		cmp r8, 20
		jne .rd_s5
			mov r8, qword[Rd]
			mov qword [reg_s4], r8
				mov rsi, registro_s4
			jmp .fin_rd
		.rd_s5:

		cmp r8, 21
		jne .rd_s6
			mov r8, qword[Rd]
			mov qword [reg_s5], r8
				mov rsi, registro_s5
			jmp .fin_rd
		.rd_s6:

		cmp r8, 22
		jne .rd_s7
			mov r8, qword[Rd]
			mov qword [reg_s6], r8
				mov rsi, registro_s6
			jmp .fin_rd
		.rd_s7:

		cmp r8, 23
		jne .rd_s8
			mov r8, qword[Rd]
			mov qword [reg_s7], r8
				mov rsi, registro_s7
			jmp .fin_rd
		.rd_s8:

		cmp r8, 24
		jne .rd_s9
			mov r8, qword[Rd]
			mov qword [reg_s8], r8
				mov rsi, registro_s8
			jmp .fin_rd
		.rd_s9:

		cmp r8, 25
		jne .rd_s10
			mov r8, qword[Rd]
			mov qword [reg_s9], r8
				mov rsi, registro_s9
			jmp .fin_rd
		.rd_s10:

		cmp r8, 26
		jne .rd_s11
			mov r8, qword[Rd]
			mov qword [reg_s10], r8
				mov rsi, registro_s10
			jmp .fin_rd
		.rd_s11:
		cmp r8, 27
		jne .rd_t3
			mov r8, qword[Rd]
			mov qword [reg_s11], r8
				mov rsi, registro_s11
			jmp .fin_rd
		.rd_t3:

		cmp r8, 28
		jne .rd_t4
			mov r8, qword[Rd]
			mov qword [reg_t3], r8
				mov rsi, registro_t3
			jmp .fin_rd
		.rd_t4:

		cmp r8, 29
		jne .rd_t5
			mov r8, qword[Rd]
			mov qword [reg_t4], r8
				mov rsi, registro_t4
			jmp .fin_rd
		.rd_t5:

		cmp r8, 30
		jne .rd_t6
			mov r8, qword[Rd]
			mov qword [reg_t5], r8
				mov rsi, registro_t5
			jmp .fin_rd
		.rd_t6:

		cmp r8, 31
		jne .fin_rd
			mov r8, qword[Rd]
			mov qword [reg_t6], r8
				mov rsi, registro_t6
			jmp .fin_rd 



	.fin_rd:

	 
	;Imprimir Rd_msj_rd
		;mov rdi, Rd_msj_rd  	  	   ; Dirección del formato (primer argumento)
			;mov rsi, 							   ; Cantidad total de bytes leídos (segundo argumento)
		;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
		;call printf   

	;Imprimir Rd_msj_rd
		;lea rdi, [Rd_num_rd ] 	  	   ; Dirección del formato (primer argumento)
		;mov rsi, [Rd]			   ; Cantidad total de bytes leídos (segundo argumento)
		;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
		;call printf 
 
		; Salto de línea después del número
			;mov rax, 1                   ; syscall: write
			;mov rdi, 1                   ; file descriptor: stdout
			;mov rsi, newline             ; Puntero al salto de línea
			;mov rdx, 1                   ; Longitud del salto de línea
			;syscall

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

    ret

Read_Rs1:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi
 
	call Bin_to_dec_rs1
	mov r8, qword [bintodec_reg] 

	 	cmp r8, 0
		jne .rd_ra1 
			mov qword [Rs1], 0
				mov rsi, registro_zero
			jmp .fin_rd1
		.rd_ra1:

		cmp r8, 1
		jne .rd_sp1
			mov r8, qword[reg_ra]
			mov qword [Rs1], r8
				mov rsi, registro_ra
			jmp .fin_rd1
		.rd_sp1:

		cmp r8, 2
		jne .rd_gp1 
			mov r9, qword[reg_sp]
			mov qword [Rs1], r9
				mov rsi, registro_sp
			jmp .fin_rd1
		.rd_gp1:

		cmp r8, 3
		jne .rd_tp1 
			mov r9, qword[reg_gp]
			mov qword [Rs1], r9
				mov rsi, registro_gp
			jmp .fin_rd1
		.rd_tp1:

		cmp r8, 4
		jne .rd_t01
			mov r8, qword[reg_tp]
			mov qword [Rs1], r8
				mov rsi, registro_tp
			jmp .fin_rd1
		.rd_t01:

		cmp r8, 5
		jne .rd_t11
			mov r8, qword[reg_t0]
			mov qword [Rs1], r8
				mov rsi, registro_t0
			jmp .fin_rd1
		.rd_t11:

		cmp r8, 6
		jne .rd_t21
			mov r8, qword[reg_t1]
			mov qword [Rs1], r8
				mov rsi, registro_t1
			jmp .fin_rd1
		.rd_t21:

		cmp r8, 7
		jne .rd_s01
			mov r8, qword[reg_t2]
			mov qword [Rs1], r8
				mov rsi, registro_t2
			jmp .fin_rd1
		.rd_s01:

		cmp r8, 8
		jne .rd_s11
			mov r8, qword[reg_s0]
			mov qword [Rs1], r8
				mov rsi, registro_s0
			jmp .fin_rd1
		.rd_s11:

		cmp r8, 9
		jne .rd_a01
			mov r8, qword[reg_s1]
			mov qword [Rs1], r8
				mov rsi, registro_s1
			jmp .fin_rd1
		.rd_a01:

		cmp r8, 10
		jne .rd_a11
			mov r8, qword[reg_a0]
			mov qword [Rs1], r8
				mov rsi, registro_a0
			jmp .fin_rd1
		.rd_a11:

		cmp r8, 11
		jne .rd_a21
			mov r8, qword[reg_a1]
			mov qword [Rs1], r8
				mov rsi, registro_a1
			jmp .fin_rd1
		.rd_a21:

		cmp r8, 12
		jne .rd_a31
			mov r8, qword[reg_a2]
			mov qword [Rs1], r8
				mov rsi, registro_a2
			jmp .fin_rd1
		.rd_a31:

		cmp r8, 13
		jne .rd_a41
			mov r8, qword[reg_a3]
			mov qword [Rs1], r8
				mov rsi, registro_a3
			jmp .fin_rd1
		.rd_a41:

		cmp r8, 14
		jne .rd_a51
			mov r8, qword[reg_a4]
			mov qword [Rs1], r8
				mov rsi, registro_a4
			jmp .fin_rd1
		.rd_a51:

		cmp r8, 15
		jne .rd_a61
			mov r8, qword[reg_a5]
			mov qword [Rs1], r8
				mov rsi, registro_a5
			jmp .fin_rd1
		.rd_a61:

		cmp r8, 16
		jne .rd_a71
			mov r8, qword[reg_a6]
			mov qword [Rs1], r8
				mov rsi, registro_a6
			jmp .fin_rd1
		.rd_a71:

		cmp r8, 17
		jne .rd_s21
			mov r8, qword[reg_a7]
			mov qword [Rs1], r8
				mov rsi, registro_a7
			jmp .fin_rd1
		.rd_s21:

		cmp r8, 18
		jne .rd_s31
			mov r8, qword[reg_s2]
			mov qword [Rs1], r8
				mov rsi, registro_s2
			jmp .fin_rd1
		.rd_s31:

		cmp r8, 19
		jne .rd_s41
			mov r8, qword[reg_s3]
			mov qword [Rs1], r8
				mov rsi, registro_s3
			jmp .fin_rd1
		.rd_s41:

		cmp r8, 20
		jne .rd_s51
			mov r8, qword[reg_s4]
			mov qword [Rs1], r8
				mov rsi, registro_s4
			jmp .fin_rd1
		.rd_s51:

		cmp r8, 21
		jne .rd_s61
			mov r8, qword[reg_s5]
			mov qword [Rs1], r8
				mov rsi, registro_s5
			jmp .fin_rd1
		.rd_s61:

		cmp r8, 22
		jne .rd_s71
			mov r8, qword[reg_s6]
			mov qword [Rs1], r8
				mov rsi, registro_s6
			jmp .fin_rd1
		.rd_s71:

		cmp r8, 23
		jne .rd_s81
			mov r8, qword[reg_s7]
			mov qword [Rs1], r8
				mov rsi, registro_s7
			jmp .fin_rd1
		.rd_s81:

		cmp r8, 24
		jne .rd_s91
			mov r8, qword[reg_s8]
			mov qword [Rs1], r8
				mov rsi, registro_s8
			jmp .fin_rd1
		.rd_s91:

		cmp r8, 25
		jne .rd_s101
			mov r8, qword[reg_s9]
			mov qword [Rs1], r8
				mov rsi, registro_s9
			jmp .fin_rd1
		.rd_s101:

		cmp r8, 26
		jne .rd_s111
			mov r8, qword[reg_s10]
			mov qword [Rs1], r8
				mov rsi, registro_s10
			jmp .fin_rd1
		.rd_s111:
		cmp r8, 27
		jne .rd_t31
			mov r8, qword[reg_s11]
			mov qword [Rs1], r8
				mov rsi, registro_s11
			jmp .fin_rd1
		.rd_t31:

		cmp r8, 28
		jne .rd_t41
			mov r8, qword[reg_t3]
			mov qword [Rs1], r8
				mov rsi, registro_t3
			jmp .fin_rd1
		.rd_t41:

		cmp r8, 29
		jne .rd_t51
			mov r8, qword[reg_t4]
			mov qword [Rs1], r8
				mov rsi, registro_t4
			jmp .fin_rd1
		.rd_t51:

		cmp r8, 30
		jne .rd_t61
			mov r8, qword[reg_t5]
			mov qword [Rs1], r8
				mov rsi, registro_t5
			jmp .fin_rd1
		.rd_t61:

		cmp r8, 31
		jne .fin_rd1
			mov r8, qword[reg_t6]
			mov qword [Rs1], r8
				mov rsi, registro_t6
			jmp .fin_rd1



	.fin_rd1:


	;Imprimir Rs1_msj
		;lea rdi, [Rs1_msj] 	  	   ; Dirección del formato (primer argumento)
			;rsi 							   ; Cantidad total de bytes leídos (segundo argumento)
		;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
		;call printf   

	;Imprimir Rd_msj_rd
		;lea rdi, [Rs1_num] 	  	   ; Dirección del formato (primer argumento)
		;mov rsi, [Rs1]			   ; Cantidad total de bytes leídos (segundo argumento)
		;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
		;call printf 


	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

    ret

Read_Rs2:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi
 
	call Bin_to_dec_rs2
	mov r8, qword [bintodec_reg] 
 
		cmp r8, 0
		jne .rd_ra2 
			mov qword [Rs2], 0
				mov rsi, registro_zero
			jmp .fin_rd2
		.rd_ra2:
 
		cmp r8, 1
		jne .rd_sp2
			mov r8, qword[reg_ra]
			mov qword [Rs2], r8
				mov rsi, registro_ra
			jmp .fin_rd2
		.rd_sp2:

		cmp r8, 2
		jne .rd_gp2 
			mov r9, qword[reg_sp]
			mov qword [Rs2], r9
				mov rsi, registro_sp
			jmp .fin_rd2
		.rd_gp2:

		cmp r8, 3
		jne .rd_tp2 
			mov qword [Rs2], 268468224
				mov rsi, registro_gp
			jmp .fin_rd2
		.rd_tp2:

		cmp r8, 4
		jne .rd_t02
			mov r8, qword[reg_tp]
			mov qword [Rs2], r8
				mov rsi, registro_tp
			jmp .fin_rd2
		.rd_t02:

		cmp r8, 5
		jne .rd_t12
			mov r8, qword[reg_t0]
			mov qword [Rs2], r8
				mov rsi, registro_t0
			jmp .fin_rd2
		.rd_t12:

		cmp r8, 6
		jne .rd_t22
			mov r8, qword[reg_t1]
			mov qword [Rs2], r8
				mov rsi, registro_t1
			jmp .fin_rd2
		.rd_t22:

		cmp r8, 7
		jne .rd_s02
			mov r8, qword[reg_t2]
			mov qword [Rs2], r8
				mov rsi, registro_t2
			jmp .fin_rd2
		.rd_s02:

		cmp r8, 8
		jne .rd_s12
			mov r8, qword[reg_s0]
			mov qword [Rs2], r8
				mov rsi, registro_s0
			jmp .fin_rd2
		.rd_s12:

		cmp r8, 9
		jne .rd_a02
			mov r8, qword[reg_s1]
			mov qword [Rs2], r8
				mov rsi, registro_s1
			jmp .fin_rd2
		.rd_a02:

		cmp r8, 10
		jne .rd_a12
			mov r8, qword[reg_a0]
			mov qword [Rs2], r8
				mov rsi, registro_a0
			jmp .fin_rd2
		.rd_a12:

		cmp r8, 11
		jne .rd_a22
			mov r8, qword[reg_a1]
			mov qword [Rs2], r8
				mov rsi, registro_a1
			jmp .fin_rd2
		.rd_a22:

		cmp r8, 12
		jne .rd_a32
			mov r8, qword[reg_a2]
			mov qword [Rs2], r8
				mov rsi, registro_a2
			jmp .fin_rd2
		.rd_a32:

		cmp r8, 13
		jne .rd_a42
			mov r8, qword[reg_a3]
			mov qword [Rs2], r8
				mov rsi, registro_a3
			jmp .fin_rd2
		.rd_a42:

		cmp r8, 14
		jne .rd_a52
			mov r8, qword[reg_a4]
			mov qword [Rs2], r8
				mov rsi, registro_a4
			jmp .fin_rd2
		.rd_a52:

		cmp r8, 15
		jne .rd_a62
			mov r8, qword[reg_a5]
			mov qword [Rs2], r8
				mov rsi, registro_a5
			jmp .fin_rd2
		.rd_a62:

		cmp r8, 16
		jne .rd_a72
			mov r8, qword[reg_a6]
			mov qword [Rs2], r8
				mov rsi, registro_a6
			jmp .fin_rd2
		.rd_a72:

		cmp r8, 17
		jne .rd_s22
			mov r8, qword[reg_a7]
			mov qword [Rs2], r8
				mov rsi, registro_a7
			jmp .fin_rd2
		.rd_s22:

		cmp r8, 18
		jne .rd_s32
			mov r8, qword[reg_s2]
			mov qword [Rs2], r8
				mov rsi, registro_s2
			jmp .fin_rd2
		.rd_s32:

		cmp r8, 19
		jne .rd_s42
			mov r8, qword[reg_s3]
			mov qword [Rs2], r8
				mov rsi, registro_s3
			jmp .fin_rd2
		.rd_s42:

		cmp r8, 20
		jne .rd_s52
			mov r8, qword[reg_s4]
			mov qword [Rs2], r8
				mov rsi, registro_s4
			jmp .fin_rd2
		.rd_s52:

		cmp r8, 21
		jne .rd_s62
			mov r8, qword[reg_s5]
			mov qword [Rs2], r8
				mov rsi, registro_s5
			jmp .fin_rd2
		.rd_s62:

		cmp r8, 22
		jne .rd_s72
			mov r8, qword[reg_s6]
			mov qword [Rs2], r8
				mov rsi, registro_s6
			jmp .fin_rd2
		.rd_s72:

		cmp r8, 23
		jne .rd_s82
			mov r8, qword[reg_s7]
			mov qword [Rs2], r8
				mov rsi, registro_s7
			jmp .fin_rd2
		.rd_s82:

		cmp r8, 24
		jne .rd_s92
			mov r8, qword[reg_s8]
			mov qword [Rs2], r8
				mov rsi, registro_s8
			jmp .fin_rd2
		.rd_s92:

		cmp r8, 25
		jne .rd_s102
			mov r8, qword[reg_s9]
			mov qword [Rs2], r8
				mov rsi, registro_s9
			jmp .fin_rd2
		.rd_s102:

		cmp r8, 26
		jne .rd_s112
			mov r8, qword[reg_s10]
			mov qword [Rs2], r8
				mov rsi, registro_s10
			jmp .fin_rd2
		.rd_s112:
		cmp r8, 27
		jne .rd_t32
			mov r8, qword[reg_s11]
			mov qword [Rs2], r8
				mov rsi, registro_s11
			jmp .fin_rd2
		.rd_t32:

		cmp r8, 28
		jne .rd_t42
			mov r8, qword[reg_t3]
			mov qword [Rs2], r8
				mov rsi, registro_t3
			jmp .fin_rd2
		.rd_t42:

		cmp r8, 29
		jne .rd_t52
			mov r8, qword[reg_t4]
			mov qword [Rs2], r8
				mov rsi, registro_t4
			jmp .fin_rd2
		.rd_t52:

		cmp r8, 30
		jne .rd_t62
			mov r8, qword[reg_t5]
			mov qword [Rs2], r8
				mov rsi, registro_t5
			jmp .fin_rd2
		.rd_t62:

		cmp r8, 31
		jne .fin_rd2
			mov r8, qword[reg_t6]
			mov qword [Rs2], r8
				mov rsi, registro_t6
			jmp .fin_rd2



	.fin_rd2:

	 
	;Imprimir Rs2_msj
		;mov rdi, Rs2_msj  	  	   ; Dirección del formato (primer argumento)
			;rsi 							   ; Cantidad total de bytes leídos (segundo argumento)
		;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
		;call printf   

	;Imprimir Rd_msj_rd
		;lea rdi, [Rs2_num ] 	  	   ; Dirección del formato (primer argumento)
		;mov rsi, [Rs2]			   ; Cantidad total de bytes leídos (segundo argumento)
		;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
		;call printf 
  

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

    ret

;

Tipo_UJ:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi
 
		call Bin_to_dec_rd
		mov r8, qword[bintodec_reg]
		cmp r8, 0
		jne .jalr_

			call Jmp
			jmp .j_done

		.jalr_:
		
			call Jal
		.j_done:

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

	ret

Tipo_R:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi
 
	  call Bin_to_dec_funct3
	  mov r8,  qword[bintodec_reg]  
	  cmp r8, 0
	  jne .sll
		call Bin_to_dec_funct7
		mov r8,  qword[bintodec_reg]  
		cmp r8, 0
		jne .resta
			call Add
			jmp .nada
		.resta:
			call Sub
			jmp .nada
	  .sll:
	  cmp r8, 1
	  jne .nada
		call Sll
	  .nada:
	 

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

	ret	

Tipo_I:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi
 
	 
	 

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

	ret	

Tipo_U:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi
 
	  ;Se llaman directo desde la comparacion de opcodes

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

	ret	

Tipo_SB:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi
 
	  call Bin_to_dec_funct3
	  mov r8,  qword[bintodec_reg]  

	;bge  
	  cmp r8, 5
	  jne .beq_
		call Bge
		jmp .Tipo_SB_Done
	.beq_:
	  cmp r8, 0
	  jne .bne_
		call Beq
		jmp .Tipo_SB_Done
	.bne_:
	  cmp r8, 1
	  jne .blt_
		call Bne
		jmp .Tipo_SB_Done
	.blt_:
	  cmp r8, 4
	  jne .Tipo_SB_Done 
		call Blt

	.Tipo_SB_Done:

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

	ret	
;
 

Inm_Tipo_UJ:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	mov qword [Inm_UJ], 0

	;Ver si es positivo o negativo
	mov al, byte [fila_bits_s + 0]        	  ; Cargar la dirección donde almacenar los datos leídos
	cmp al, '1' 
	je .negativo
   
	;Positivo
		;Ordenar
			mov al, byte [fila_bits_s + 0]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next
				add qword[Inm_UJ], 1048576

			.next:
			mov al, byte [fila_bits_s + 12]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next1
				add qword[Inm_UJ], 524288

			.next1:
			mov al, byte [fila_bits_s + 13]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next2
				add qword[Inm_UJ], 262144

			.next2:
			mov al, byte [fila_bits_s + 14]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next3
				add qword[Inm_UJ], 131072

			.next3:
			mov al, byte [fila_bits_s + 15]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next4
				add qword[Inm_UJ], 65536

			.next4:
			mov al, byte [fila_bits_s + 16]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next5
				add qword[Inm_UJ], 32768

			.next5:
			mov al, byte [fila_bits_s + 17]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next6
				add qword[Inm_UJ], 16384

			.next6:
			mov al, byte [fila_bits_s + 18]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next7
				add qword[Inm_UJ], 8192

			.next7:
			mov al, byte [fila_bits_s + 19]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next8
				add qword[Inm_UJ], 4096

			.next8:
			mov al, byte [fila_bits_s + 11]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next9
				add qword[Inm_UJ], 2048

			.next9:
			mov al, byte [fila_bits_s + 1]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next10
				add qword[Inm_UJ], 1024

			.next10:
			mov al, byte [fila_bits_s + 2]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next11
				add qword[Inm_UJ], 512

			.next11:
			mov al, byte [fila_bits_s + 3]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next12
				add qword[Inm_UJ], 256

			.next12:
			mov al, byte [fila_bits_s + 4]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next13
				add qword[Inm_UJ], 128

			.next13:
			mov al, byte [fila_bits_s + 5]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next14
				add qword[Inm_UJ], 64

			.next14:
			mov al, byte [fila_bits_s + 6]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next15
				add qword[Inm_UJ], 32

			.next15:
			mov al, byte [fila_bits_s + 7]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next16
				add qword[Inm_UJ], 16

			.next16:
			mov al, byte [fila_bits_s + 8]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next17
				add qword[Inm_UJ], 8

			.next17:
			mov al, byte [fila_bits_s + 9]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next18
				add qword[Inm_UJ], 4

			.next18: 
			mov al, byte [fila_bits_s + 10]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next19
				add qword[Inm_UJ], 2

			.next19: 
			mov al, byte [fila_bits_s + 20]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next20	
				add qword[Inm_UJ], 1

		.next20:
		 
		;mov rdi, Inmediato_msj  	  	   ; Dirección del formato (primer argumento)
		;mov rsi, qword[Inm_UJ]			   ; Cantidad total de bytes leídos (segundo argumento)
		;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
		;call printf

		jmp .Done_Inm_uj

	.negativo:

		;Ordenar
			mov al, byte [fila_bits_s + 0]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextn
				add qword[Inm_UJ], 1048576

			.nextn:
			mov al, byte [fila_bits_s + 12]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next1n
				add qword[Inm_UJ], 524288

			.next1n:
			mov al, byte [fila_bits_s + 13]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next2n
				add qword[Inm_UJ], 262144

			.next2n:
			mov al, byte [fila_bits_s + 14]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next3n
				add qword[Inm_UJ], 131072

			.next3n:
			mov al, byte [fila_bits_s + 15]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next4n
				add qword[Inm_UJ], 65536

			.next4n:
			mov al, byte [fila_bits_s + 16]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next5n
				add qword[Inm_UJ], 32768

			.next5n:
			mov al, byte [fila_bits_s + 17]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next6n
				add qword[Inm_UJ], 16384

			.next6n:
			mov al, byte [fila_bits_s + 18]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next7n
				add qword[Inm_UJ], 8192

			.next7n:
			mov al, byte [fila_bits_s + 19]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next8n
				add qword[Inm_UJ], 4096

			.next8n:
			mov al, byte [fila_bits_s + 11]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next9n
				add qword[Inm_UJ], 2048

			.next9n:
			mov al, byte [fila_bits_s + 1]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next10n
				add qword[Inm_UJ], 1024

			.next10n:
			mov al, byte [fila_bits_s + 2]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next11n
				add qword[Inm_UJ], 512

			.next11n:
			mov al, byte [fila_bits_s + 3]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next12n
				add qword[Inm_UJ], 256

			.next12n:
			mov al, byte [fila_bits_s + 4]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next13n
				add qword[Inm_UJ], 128

			.next13n:
			mov al, byte [fila_bits_s + 5]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next14n
				add qword[Inm_UJ], 64

			.next14n:
			mov al, byte [fila_bits_s + 6]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next15n
				add qword[Inm_UJ], 32

			.next15n:
			mov al, byte [fila_bits_s + 7]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next16n
				add qword[Inm_UJ], 16

			.next16n:
			mov al, byte [fila_bits_s + 8]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next17n
				add qword[Inm_UJ], 8

			.next17n:
			mov al, byte [fila_bits_s + 9]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next18n
				add qword[Inm_UJ], 4

			.next18n: 
			mov al, byte [fila_bits_s + 10]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next19n
				add qword[Inm_UJ], 2

			.next19n: 
			mov al, byte [fila_bits_s + 20]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next20n
				add qword[Inm_UJ], 1

		.next20n: 
		add word[Inm_UJ], 1
		mov rax, qword[Inm_UJ]
		mov rcx, -1
		imul rax, rcx 
		mov qword[Inm_UJ], rax
 
		;mov rdi, Inmediato_msj  	  	   ; Dirección del formato (primer argumento)
		;mov rsi, qword[Inm_UJ]			   ; Cantidad total de bytes leídos (segundo argumento)
		;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
		;call printf  
	; 

		 
	.Done_Inm_uj:

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

    ret
;
Inm_Tipo_I:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	mov qword[Inm_I], 0

	;Ver si es positivo o negativo
	mov al, byte [fila_bits_s + 0]        	  ; Cargar la dirección donde almacenar los datos leídos
	cmp al, '1' 
	je .negativoI
   
	;Positivo
		;Ordenar
			
			mov al, byte [fila_bits_s + 0]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI9
				add qword[Inm_I], 2048

			.nextI9:
			mov al, byte [fila_bits_s + 1]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI10
				add qword[Inm_I], 1024

			.nextI10:
			mov al, byte [fila_bits_s + 2]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI11
				add qword[Inm_I], 512

			.nextI11:
			mov al, byte [fila_bits_s + 3]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI12
				add qword[Inm_I], 256

			.nextI12:
			mov al, byte [fila_bits_s + 4]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI13
				add qword[Inm_I], 128

			.nextI13:
			mov al, byte [fila_bits_s + 5]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI14
				add qword[Inm_I], 64

			.nextI14:
			mov al, byte [fila_bits_s + 6]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI15
				add qword[Inm_I], 32

			.nextI15:
			mov al, byte [fila_bits_s + 7]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI16
				add qword[Inm_I], 16

			.nextI16:
			mov al, byte [fila_bits_s + 8]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI17
				add qword[Inm_I], 8

			.nextI17:
			mov al, byte [fila_bits_s + 9]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI18
				add qword[Inm_I], 4

			.nextI18: 
			mov al, byte [fila_bits_s + 10]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI19
				add qword[Inm_I], 2

			.nextI19: 
			mov al, byte [fila_bits_s + 11]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI20	
				add qword[Inm_I], 1

		.nextI20:
 
		;mov rdi, Inmediato_msj  	  	   ; Dirección del formato (primer argumento)
		;mov rsi, qword[Inm_I]			   ; Cantidad total de bytes leídos (segundo argumento)
		;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
		;call printf   

		jmp .Done_Inm_I
	;

	.negativoI:

		;Ordenar
			
			mov al, byte [fila_bits_s + 0]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI9n
				add qword[Inm_I], 2048

			.nextI9n:
			mov al, byte [fila_bits_s + 1]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI10n
				add qword[Inm_I], 1024

			.nextI10n:
			mov al, byte [fila_bits_s + 2]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI11n
				add qword[Inm_I], 512

			.nextI11n:
			mov al, byte [fila_bits_s + 3]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI12n
				add qword[Inm_I], 256

			.nextI12n:
			mov al, byte [fila_bits_s + 4]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI13n
				add qword[Inm_I], 128

			.nextI13n:
			mov al, byte [fila_bits_s + 5]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI14n
				add qword[Inm_I], 64

			.nextI14n:
			mov al, byte [fila_bits_s + 6]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI15n
				add qword[Inm_I], 32

			.nextI15n:
			mov al, byte [fila_bits_s + 7]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI16n
				add qword[Inm_I], 16

			.nextI16n:
			mov al, byte [fila_bits_s + 8]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI17n
				add qword[Inm_I], 8

			.nextI17n:
			mov al, byte [fila_bits_s + 9]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI18n
				add qword[Inm_I], 4

			.nextI18n: 
			mov al, byte [fila_bits_s + 10]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI19n
				add qword[Inm_I], 2

			.nextI19n: 
			mov al, byte [fila_bits_s + 11]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI20n	
				add qword[Inm_I], 1

		.nextI20n:
	

		add word[Inm_I], 1
		mov rax, qword[Inm_I]
		mov rcx, -1
		imul rax, rcx 
		mov qword[Inm_I], rax
 
		;mov rdi, Inmediato_msj  	  	   ; Dirección del formato (primer argumento)
		;mov rsi, qword[Inm_I]			   ; Cantidad total de bytes leídos (segundo argumento)
		;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
		;call printf   


	.Done_Inm_I: 

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

    ret
;
Inm_Tipo_U:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	mov qword [Inm_U], 0

	;Ver si es positivo o negativo
	mov al, byte [fila_bits_s + 0]        	  ; Cargar la dirección donde almacenar los datos leídos
	cmp al, '1' 
	je .negativou
   
	;Positivo
		;Ordenar
			
			mov al, byte [fila_bits_s + 0]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next1u
				add qword[Inm_U], 524288

			.next1u:
			mov al, byte [fila_bits_s + 1]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next2u
				add qword[Inm_U], 262144

			.next2u:
			mov al, byte [fila_bits_s + 2]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next3u
				add qword[Inm_U], 131072

			.next3u:
			mov al, byte [fila_bits_s + 3]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next4u
				add qword[Inm_U], 65536

			.next4u:
			mov al, byte [fila_bits_s + 4]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next5u
				add qword[Inm_U], 32768

			.next5u:
			mov al, byte [fila_bits_s + 5]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next6u
				add qword[Inm_U], 16384

			.next6u:
			mov al, byte [fila_bits_s + 6]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next7u
				add qword[Inm_U], 8192

			.next7u:
			mov al, byte [fila_bits_s + 7]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next8u
				add qword[Inm_U], 4096

			.next8u:
			mov al, byte [fila_bits_s + 8]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next9u
				add qword[Inm_U], 2048

			.next9u:
			mov al, byte [fila_bits_s + 9]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next10u
				add qword[Inm_U], 1024

			.next10u:
			mov al, byte [fila_bits_s + 10]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next11u
				add qword[Inm_U], 512

			.next11u:
			mov al, byte [fila_bits_s + 11]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next12u
				add qword[Inm_U], 256

			.next12u:
			mov al, byte [fila_bits_s + 12]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next13u
				add qword[Inm_U], 128

			.next13u:
			mov al, byte [fila_bits_s + 13]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next14u
				add qword[Inm_U], 64

			.next14u:
			mov al, byte [fila_bits_s + 14]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next15u
				add qword[Inm_U], 32

			.next15u:
			mov al, byte [fila_bits_s + 15]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next16u
				add qword[Inm_U], 16

			.next16u:
			mov al, byte [fila_bits_s + 16]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next17u
				add qword[Inm_U], 8

			.next17u:
			mov al, byte [fila_bits_s + 17]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next18u
				add qword[Inm_U], 4

			.next18u: 
			mov al, byte [fila_bits_s + 18]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next19u
				add qword[Inm_U], 2

			.next19u: 
			mov al, byte [fila_bits_s + 19]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next20u	
				add qword[Inm_U], 1

		.next20u:
		 
		mov rax, qword[Inm_U]   
		mov rcx, 4096
		imul rax, rcx 
		mov qword[Inm_U], rax
		
		;mov rdi, Inmediato_msj  	  	   ; Dirección del formato (primer argumento)
		;mov rsi, qword[Inm_U]			   ; Cantidad total de bytes leídos (segundo argumento)
		;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
		;call printf

		jmp .Done_Inm_u

	.negativou:

		;Ordenar
			
			mov al, byte [fila_bits_s + 1]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next1nu2
				add qword[Inm_U], 524288

			.next1nu2:
			mov al, byte [fila_bits_s + 2]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next2nu2
				add qword[Inm_U], 262144

			.next2nu2:
			mov al, byte [fila_bits_s + 3]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next3nu2
				add qword[Inm_U], 131072

			.next3nu2:
			mov al, byte [fila_bits_s + 4]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next4nu2
				add qword[Inm_U], 65536

			.next4nu2:
			mov al, byte [fila_bits_s + 5]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next5nu2
				add qword[Inm_U], 32768

			.next5nu2:
			mov al, byte [fila_bits_s + 6]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next6nu2
				add qword[Inm_U], 16384

			.next6nu2:
			mov al, byte [fila_bits_s + 7]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next7nu2
				add qword[Inm_U], 8192

			.next7nu2:
			mov al, byte [fila_bits_s + 8]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next8nu2
				add qword[Inm_UJ], 4096

			.next8nu2:
			mov al, byte [fila_bits_s + 9]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next9nu2
				add qword[Inm_U], 2048

			.next9nu2:
			mov al, byte [fila_bits_s + 10]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next10nu2
				add qword[Inm_U], 1024

			.next10nu2:
			mov al, byte [fila_bits_s + 11]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next11nu2
				add qword[Inm_U], 512

			.next11nu2:
			mov al, byte [fila_bits_s + 12]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next12nu2
				add qword[Inm_U], 256

			.next12nu2:
			mov al, byte [fila_bits_s + 13]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next13nu2
				add qword[Inm_U], 128

			.next13nu2:
			mov al, byte [fila_bits_s + 5]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next14nu2
				add qword[Inm_U], 64

			.next14nu2:
			mov al, byte [fila_bits_s + 14]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next15nu2
				add qword[Inm_U], 32

			.next15nu2:
			mov al, byte [fila_bits_s + 15]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next16nu2
				add qword[Inm_U], 16

			.next16nu2:
			mov al, byte [fila_bits_s + 16]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next17nu2
				add qword[Inm_U], 8

			.next17nu2:
			mov al, byte [fila_bits_s + 17]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next18nu2
				add qword[Inm_U], 4

			.next18nu2: 
			mov al, byte [fila_bits_s + 18]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next19nu2
				add qword[Inm_U], 2

			.next19nu2: 
			mov al, byte [fila_bits_s + 19]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next20nu2
				add qword[Inm_U], 1

		.next20nu2: 

		add word[Inm_U], 1

		mov rax, qword[Inm_U]   
		mov rcx, 4096
		imul rax, rcx 
		mov qword[Inm_U], rax
		
		mov rax, qword[Inm_U]
		mov rcx, -1
		imul rax, rcx 
		mov qword[Inm_U], rax
 
		;mov rdi, Inmediato_msj  	  	   ; Dirección del formato (primer argumento)
		;mov rsi, qword[Inm_U]			   ; Cantidad total de bytes leídos (segundo argumento)
		;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
		;call printf  
	; 

		 
	.Done_Inm_u:

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

    ret
;
Inm_Tipo_S:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	mov qword[Inm_S], 0

	;Ver si es positivo o negativo
	mov al, byte [fila_bits_s + 0]        	  ; Cargar la dirección donde almacenar los datos leídos
	cmp al, '1' 
	je .negativoS
   
	;Positivo
		;Ordenar
			 
			mov al, byte [fila_bits_s + 0]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI9ns
				add qword[Inm_S], 2048

			.nextI9ns:
			mov al, byte [fila_bits_s + 1]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI10ns
				add qword[Inm_S], 1024

			.nextI10ns:
			mov al, byte [fila_bits_s + 2]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI11ns
				add qword[Inm_S], 512

			.nextI11ns:
			mov al, byte [fila_bits_s + 3]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI12ns
				add qword[Inm_S], 256

			.nextI12ns:
			mov al, byte [fila_bits_s + 4]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI13ns
				add qword[Inm_S], 128

			.nextI13ns:
			mov al, byte [fila_bits_s + 5]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI14s
				add qword[Inm_S], 64

			.nextI14s:
			mov al, byte [fila_bits_s + 6]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI15s
				add qword[Inm_S], 32

			.nextI15s:
			mov al, byte [fila_bits_s + 20]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI16s
				add qword[Inm_S], 16

			.nextI16s:
			mov al, byte [fila_bits_s + 21]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI17s
				add qword[Inm_S], 8

			.nextI17s:
			mov al, byte [fila_bits_s + 22]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI18s
				add qword[Inm_S], 4

			.nextI18s: 
			mov al, byte [fila_bits_s + 23]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI19s
				add qword[Inm_S], 2

			.nextI19s: 
			mov al, byte [fila_bits_s + 24]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI20s	
				add qword[Inm_S], 1

		.nextI20s:
 
		;mov rdi, Inmediato_msj  	  	   ; Dirección del formato (primer argumento)
		;mov rsi, qword[Inm_S]			   ; Cantidad total de bytes leídos (segundo argumento)
		;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
		;call printf   

		jmp .Done_Inm_S
	;

	.negativoS:

		;Ordenar
			 
			mov al, byte [fila_bits_s + 0]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI9nsn
				add qword[Inm_S], 2048

			.nextI9nsn:
			mov al, byte [fila_bits_s + 1]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI10nsn
				add qword[Inm_S], 1024

			.nextI10nsn:
			mov al, byte [fila_bits_s + 2]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI11nsn
				add qword[Inm_S], 512

			.nextI11nsn:
			mov al, byte [fila_bits_s + 3]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI12nsn
				add qword[Inm_S], 256

			.nextI12nsn:
			mov al, byte [fila_bits_s + 4]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI13nsn
				add qword[Inm_S], 128

			.nextI13nsn:
			mov al, byte [fila_bits_s + 5]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI14nsn
				add qword[Inm_S], 64

			.nextI14nsn:
			mov al, byte [fila_bits_s + 6]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI15nsn
				add qword[Inm_S], 32

			.nextI15nsn:
			mov al, byte [fila_bits_s + 20]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI16nsn
				add qword[Inm_S], 16

			.nextI16nsn:
			mov al, byte [fila_bits_s + 21]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI17nsn
				add qword[Inm_S], 8

			.nextI17nsn:
			mov al, byte [fila_bits_s + 22]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI18nsn
				add qword[Inm_S], 4

			.nextI18nsn: 
			mov al, byte [fila_bits_s + 23]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI19nsn
				add qword[Inm_S], 2

			.nextI19nsn: 
			mov al, byte [fila_bits_s + 24]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI20nsn	
				add qword[Inm_S], 1

		.nextI20nsn:
	

		add word[Inm_S], 1

		mov rax, qword[Inm_S]
		mov rcx, -1
		imul rax, rcx 
		mov qword[Inm_S], rax
 
		;mov rdi, Inmediato_msj  	  	   ; Dirección del formato (primer argumento)
		;mov rsi, qword[Inm_S]			   ; Cantidad total de bytes leídos (segundo argumento)
		;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
		;call printf   


	.Done_Inm_S: 

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

    ret
;
Inm_Tipo_SB:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	mov qword[Inm_SB], 0

	;Ver si es positivo o negativo
	mov al, byte [fila_bits_s + 0]        	  ; Cargar la dirección donde almacenar los datos leídos
	cmp al, '1' 
	je .negativoSB
   
	;Positivo
		;Ordenar
			 
			mov al, byte [fila_bits_s + 0]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI9nsb
				add qword[Inm_SB], 2048

			.nextI9nsb:
			mov al, byte [fila_bits_s + 2]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI10nsb
				add qword[Inm_SB], 1024

			.nextI10nsb:
			mov al, byte [fila_bits_s + 3]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI11nsb
				add qword[Inm_SB], 512

			.nextI11nsb:
			mov al, byte [fila_bits_s + 4]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI12nsb
				add qword[Inm_SB], 256

			.nextI12nsb:
			mov al, byte [fila_bits_s + 5]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI13nsb
				add qword[Inm_SB], 128

			.nextI13nsb:
			mov al, byte [fila_bits_s + 6]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI14sb
				add qword[Inm_SB], 64

			.nextI14sb:
			mov al, byte [fila_bits_s + 20]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI15sb
				add qword[Inm_SB], 32

			.nextI15sb:
			mov al, byte [fila_bits_s + 21]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI16sb
				add qword[Inm_SB], 16

			.nextI16sb:
			mov al, byte [fila_bits_s + 22]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI17sb
				add qword[Inm_SB], 8

			.nextI17sb:
			mov al, byte [fila_bits_s + 23]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI18sb
				add qword[Inm_SB], 4

			.nextI18sb: 
			mov al, byte [fila_bits_s + 24]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI19sb
				add qword[Inm_SB], 2

			.nextI19sb: 
			mov al, byte [fila_bits_s + 1]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextI20sb	
				add qword[Inm_SB], 1

		.nextI20sb:

		mov rax, qword[Inm_SB]			;Concateno un cero a la derecha
		mov rcx, 2
		imul rax, rcx 
		mov qword[Inm_SB], rax
 
		;mov rdi, Inmediato_msj  	  	   ; Dirección del formato (primer argumento)
		;mov rsi, qword[Inm_SB]			   ; Cantidad total de bytes leídos (segundo argumento)
		;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
		;call printf   

		jmp .Done_Inm_SB
	;

	.negativoSB:

		;Ordenar
			 
			mov al, byte [fila_bits_s + 0]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI9nsbn
				add qword[Inm_SB], 2048

			.nextI9nsbn:
			mov al, byte [fila_bits_s + 2]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI10nsbn
				add qword[Inm_SB], 1024

			.nextI10nsbn:
			mov al, byte [fila_bits_s + 3]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI11nsbn
				add qword[Inm_SB], 512

			.nextI11nsbn:
			mov al, byte [fila_bits_s + 4]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI12nsbn
				add qword[Inm_SB], 256

			.nextI12nsbn:
			mov al, byte [fila_bits_s + 5]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI13nsbn
				add qword[Inm_SB], 128

			.nextI13nsbn:
			mov al, byte [fila_bits_s + 6]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI14nsbn
				add qword[Inm_SB], 64

			.nextI14nsbn:
			mov al, byte [fila_bits_s + 20]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI15nsbn
				add qword[Inm_SB], 32

			.nextI15nsbn:
			mov al, byte [fila_bits_s + 21]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI16nsbn
				add qword[Inm_SB], 16

			.nextI16nsbn:
			mov al, byte [fila_bits_s + 22]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI17nsbn
				add qword[Inm_SB], 8

			.nextI17nsbn:
			mov al, byte [fila_bits_s + 23]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI18nsbn
				add qword[Inm_SB], 4

			.nextI18nsbn: 
			mov al, byte [fila_bits_s + 24]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI19nsbn
				add qword[Inm_SB], 2

			.nextI19nsbn: 
			mov al, byte [fila_bits_s + 1]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .nextI20nsbn
				add qword[Inm_SB], 1

		.nextI20nsbn:
	
		add word[Inm_SB], 1
		mov rax, qword[Inm_SB]
		mov rcx, 2
		imul rax, rcx  

		mov rcx, -1
		imul rax, rcx 
		mov qword[Inm_SB], rax
 
		;mov rdi, Inmediato_msj  	  	   ; Dirección del formato (primer argumento)
		;mov rsi, qword[Inm_SB]			   ; Cantidad total de bytes leídos (segundo argumento)
		;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
		;call printf   


	.Done_Inm_SB: 

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

    ret
;
 

Bin_to_dec_Data:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	mov qword [Inm_D], 0

	mov al, byte [fila_bits_d + 0]    	    	  ; Cargar la dirección donde almacenar los datos leídos
	cmp al, '0'         					       ; apunta al la cadena a leer
	jne .Data_negativo
	
	;Positivo
		;Ordenar
			
			mov al, byte [fila_bits_d + 0]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next131u
				add qword[Inm_D], 0

			.next131u:
			mov al, byte [fila_bits_d + 1]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next121u
				add qword[Inm_D], 0

			.next121u:
			mov al, byte [fila_bits_d + 2]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next111u
				add qword[Inm_D], 0

			.next111u:
			mov al, byte [fila_bits_d + 3]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next101u
				add qword[Inm_D], 0

			.next101u:
			mov al, byte [fila_bits_d + 4]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next91u
				add qword[Inm_D], 0

			.next91u:
			mov al, byte [fila_bits_d + 5]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next81u
				add qword[Inm_D], 0

			.next81u:
			mov al, byte [fila_bits_d + 6]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next71u
				add qword[Inm_D], 0

			.next71u:
			mov al, byte [fila_bits_d + 7]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next61u
				add qword[Inm_D], 16777216

			.next61u:
			mov al, byte [fila_bits_d + 8]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next51u
				add qword[Inm_D], 8388608

			.next51u:
			mov al, byte [fila_bits_d + 9]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next41u
				add qword[Inm_D], 4194304

			.next41u:
			mov al, byte [fila_bits_d + 10]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next31u
				add qword[Inm_D], 2097152

			.next31u:
			mov al, byte [fila_bits_d + 11]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next21u
				add qword[Inm_D], 1048576

			.next21u:
			mov al, byte [fila_bits_d + 12]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next1ud
				add qword[Inm_D], 524288

			.next1ud:
			mov al, byte [fila_bits_d + 13]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next2ud
				add qword[Inm_D], 262144

			.next2ud:
			mov al, byte [fila_bits_d + 14]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next3ud
				add qword[Inm_D], 131072

			.next3ud:
			mov al, byte [fila_bits_d + 15]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next4ud
				add qword[Inm_D], 65536

			.next4ud:
			mov al, byte [fila_bits_d + 16]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next5ud
				add qword[Inm_D], 32768

			.next5ud:
			mov al, byte [fila_bits_d + 17]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next6ud
				add qword[Inm_D], 16384

			.next6ud:
			mov al, byte [fila_bits_d + 18]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next7ud
				add qword[Inm_D], 8192

			.next7ud:
			mov al, byte [fila_bits_d + 19]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next8ud
				add qword[Inm_D], 4096

			.next8ud:
			mov al, byte [fila_bits_d + 20]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next9ud
				add qword[Inm_D], 2048

			.next9ud:
			mov al, byte [fila_bits_d + 21]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next10ud
				add qword[Inm_D], 1024

			.next10ud:
			mov al, byte [fila_bits_d + 22]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next11ud
				add qword[Inm_D], 512

			.next11ud:
			mov al, byte [fila_bits_d + 23]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next12ud
				add qword[Inm_D], 256

			.next12ud:
			mov al, byte [fila_bits_d + 24]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next13ud
				add qword[Inm_D], 128

			.next13ud:
			mov al, byte [fila_bits_d + 25]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next14ud
				add qword[Inm_D], 64

			.next14ud:
			mov al, byte [fila_bits_d + 26]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next15ud
				add qword[Inm_D], 32

			.next15ud:
			mov al, byte [fila_bits_d + 27]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next16ud
				add qword[Inm_D], 16

			.next16ud:
			mov al, byte [fila_bits_d + 28]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next17ud
				add qword[Inm_D], 8

			.next17ud:
			mov al, byte [fila_bits_d + 29]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next18ud
				add qword[Inm_D], 4

			.next18ud: 
			mov al, byte [fila_bits_d + 30]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next19ud
				add qword[Inm_D], 2

			.next19ud: 
			mov al, byte [fila_bits_d + 31]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .next20ud	
				add qword[Inm_D], 1

		.next20ud:

		jmp .Data_done

	.Data_negativo:
		;Ordenar
			
			mov al, byte [fila_bits_d + 0]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next131un
				add qword[Inm_D], 0

			.next131un:
			mov al, byte [fila_bits_d + 1]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next121un
				add qword[Inm_D], 0

			.next121un:
			mov al, byte [fila_bits_d + 2]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next111un
				add qword[Inm_D], 0

			.next111un:
			mov al, byte [fila_bits_d + 3]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next101un
				add qword[Inm_D], 0

			.next101un:
			mov al, byte [fila_bits_d + 4]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next91un
				add qword[Inm_D], 0

			.next91un:
			mov al, byte [fila_bits_d + 5]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next81un
				add qword[Inm_D], 0

			.next81un:
			mov al, byte [fila_bits_d + 6]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next71un
				add qword[Inm_D], 0

			.next71un:
			mov al, byte [fila_bits_d + 7]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next61un
				add qword[Inm_D], 16777216

			.next61un:
			mov al, byte [fila_bits_d + 8]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next51un
				add qword[Inm_D], 8388608

			.next51un:
			mov al, byte [fila_bits_d + 9]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next41un
				add qword[Inm_D], 4194304

			.next41un:
			mov al, byte [fila_bits_d + 10]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next31un
				add qword[Inm_D], 2097152

			.next31un:
			mov al, byte [fila_bits_d + 11]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next21un
				add qword[Inm_D], 1048576

			.next21un:
			mov al, byte [fila_bits_d + 12]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next1udn
				add qword[Inm_D], 524288

			.next1udn:
			mov al, byte [fila_bits_d + 13]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next2udn
				add qword[Inm_D], 262144

			.next2udn:
			mov al, byte [fila_bits_d + 14]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next3udn
				add qword[Inm_D], 131072

			.next3udn:
			mov al, byte [fila_bits_d + 15]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next4udn
				add qword[Inm_D], 65536

			.next4udn:
			mov al, byte [fila_bits_d + 16]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next5udn
				add qword[Inm_D], 32768

			.next5udn:
			mov al, byte [fila_bits_d + 17]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next6udn
				add qword[Inm_D], 16384

			.next6udn:
			mov al, byte [fila_bits_d + 18]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next7udn
				add qword[Inm_D], 8192

			.next7udn:
			mov al, byte [fila_bits_d + 19]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next8udn
				add qword[Inm_D], 4096

			.next8udn:
			mov al, byte [fila_bits_d + 20]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next9udn
				add qword[Inm_D], 2048

			.next9udn:
			mov al, byte [fila_bits_d + 21]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next10udn
				add qword[Inm_D], 1024

			.next10udn:
			mov al, byte [fila_bits_d + 22]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next11udn
				add qword[Inm_D], 512

			.next11udn:
			mov al, byte [fila_bits_d + 23]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next12udn
				add qword[Inm_D], 256

			.next12udn:
			mov al, byte [fila_bits_d + 24]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next13udn
				add qword[Inm_D], 128

			.next13udn:
			mov al, byte [fila_bits_d + 25]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next14udn
				add qword[Inm_D], 64

			.next14udn:
			mov al, byte [fila_bits_d + 26]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next15udn
				add qword[Inm_D], 32

			.next15udn:
			mov al, byte [fila_bits_d + 27]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next16udn
				add qword[Inm_D], 16

			.next16udn:
			mov al, byte [fila_bits_d + 28]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next17udn
				add qword[Inm_D], 8

			.next17udn:
			mov al, byte [fila_bits_d + 29]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next18udn
				add qword[Inm_D], 4

			.next18udn: 
			mov al, byte [fila_bits_d + 30]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next19udn
				add qword[Inm_D], 2

			.next19udn: 
			mov al, byte [fila_bits_d + 31]        	  ; Cargar la dirección donde almacenar los datos leídos
			cmp al, '0'                 ; apunta al la cadena a leer
			jne .next20udn	
				add qword[Inm_D], 1

		.next20udn:

		add word[Inm_D], 1
		mov rax, qword[Inm_D]
		mov rcx, -1
		imul rax, rcx 
		mov qword[Inm_D], rax

		.Data_done:

		;mov rdi, Inmediato_msj  	  	   ; Dirección del formato (primer argumento)
		;mov rsi, qword[Inm_D]			   ; Cantidad total de bytes leídos (segundo argumento)
		;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
		;call printf  


	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

    ret
;
Bin_to_dec_rd:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	 
	; Inicializar Inm_UJ a cero
	mov qword [bintodec_reg], 0
  
	 

		mov al, byte[fila_bits_s + 20]
 
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextrd
				add qword[bintodec_reg], 16

			.nextrd:
		mov al, byte[fila_bits_s + 21]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextrd1
				add qword[bintodec_reg], 8

			.nextrd1:
		mov al, byte[fila_bits_s + 22]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextrd2
				add qword[bintodec_reg], 4

			.nextrd2: 
		mov al, byte[fila_bits_s + 23]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextrd3
				add qword[bintodec_reg], 2

			.nextrd3: 
		mov al, byte[fila_bits_s + 24]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextrd4	
				add qword[bintodec_reg], 1

		.nextrd4:


		mov rdi, format1  	  	   ; Dirección del formato (primer argumento)
			;mov rsi, qword[bintodec_reg]			   ; Cantidad total de bytes leídos (segundo argumento)
			;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
			;call printf   

		; Salto de línea después del número
			;mov rax, 1                   ; syscall: write
			;mov rdi, 1                   ; file descriptor: stdout
			;mov rsi, newline             ; Puntero al salto de línea
			;mov rdx, 1                   ; Longitud del salto de línea
			;syscall	

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

    ret

Bin_to_dec_rs1:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	 
	; Inicializar Inm_UJ a cero
	mov qword [bintodec_reg], 0
  
	 

		mov al, byte[fila_bits_s + 12]
 
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextrs
				add qword[bintodec_reg], 16

			.nextrs:
		mov al, byte[fila_bits_s + 13]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextrs1
				add qword[bintodec_reg], 8

			.nextrs1:
		mov al, byte[fila_bits_s + 14]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextrs2
				add qword[bintodec_reg], 4

			.nextrs2: 
		mov al, byte[fila_bits_s + 15]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextrs3
				add qword[bintodec_reg], 2

			.nextrs3: 
		mov al, byte[fila_bits_s + 16]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextrs4	
				add qword[bintodec_reg], 1

		.nextrs4:


	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

    ret

Bin_to_dec_rs2:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	 
	; Inicializar Inm_UJ a cero
	mov qword [bintodec_reg], 0
  
	 

		mov al, byte[fila_bits_s + 7]
 
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextrs1
				add qword[bintodec_reg], 16

			.nextrs1:
		mov al, byte[fila_bits_s + 8]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextrs11
				add qword[bintodec_reg], 8

			.nextrs11:
		mov al, byte[fila_bits_s + 9]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextrs12
				add qword[bintodec_reg], 4

			.nextrs12: 
		mov al, byte[fila_bits_s + 10]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextrs13
				add qword[bintodec_reg], 2

			.nextrs13: 
		mov al, byte[fila_bits_s + 11]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextrs14	
				add qword[bintodec_reg], 1

		.nextrs14:


		;mov rdi, format1  	  	   ; Dirección del formato (primer argumento)
			;mov rsi, qword[bintodec_reg]			   ; Cantidad total de bytes leídos (segundo argumento)
			;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
			;call printf   

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

    ret

Bin_to_dec_funct3:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	 
	; Inicializar Inm_UJ a cero
	mov qword [bintodec_reg], 0
  
	 
		mov al, byte[fila_bits_s + 17]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextf2
				add qword[bintodec_reg], 4

			.nextf2: 
		mov al, byte[fila_bits_s + 18]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextf3
				add qword[bintodec_reg], 2

			.nextf3: 
		mov al, byte[fila_bits_s + 19]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextf4	
				add qword[bintodec_reg], 1

		.nextf4:

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

    ret

Bin_to_dec_funct7:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	 
	; Inicializar Inm_UJ a cero
	mov qword [bintodec_reg], 0
  
	 

		mov al, byte[fila_bits_s] 
 
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextf12
				add qword[bintodec_reg], 64

			.nextf12:
		mov al, byte[fila_bits_s + 1]
 
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextf13
				add qword[bintodec_reg], 32

			.nextf13:
		mov al, byte[fila_bits_s + 2]
 
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextf14
				add qword[bintodec_reg], 16

			.nextf14:
		mov al, byte[fila_bits_s + 3]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextf15
				add qword[bintodec_reg], 8

			.nextf15:
		mov al, byte[fila_bits_s + 4]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextf16
				add qword[bintodec_reg], 4

			.nextf16: 
		mov al, byte[fila_bits_s + 5]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextf7
				add qword[bintodec_reg], 2

			.nextf7: 
		mov al, byte[fila_bits_s + 6]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextf8	
				add qword[bintodec_reg], 1

		.nextf8:


			;mov rdi, format1  	  	   ; Dirección del formato (primer argumento)
			;mov rsi, qword[bintodec_reg]			   ; Cantidad total de bytes leídos (segundo argumento)
			;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
			;call printf   

		; Salto de línea después del número
			;mov rax, 1                   ; syscall: write
			;mov rdi, 1                   ; file descriptor: stdout
			;mov rsi, newline             ; Puntero al salto de línea
			;mov rdx, 1                   ; Longitud del salto de línea
			;syscall	

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

    ret

Bin_to_dec_opcode:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	 
	; Inicializar Inm_UJ a cero
	mov qword [bintodec_reg], 0
  
	 

		mov al, byte[fila_bits_s + 25] 
 
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextf12
				add qword[bintodec_reg], 64

			.nextf12:
		mov al, byte[fila_bits_s + 26]
 
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextf13
				add qword[bintodec_reg], 32

			.nextf13:
		mov al, byte[fila_bits_s + 27]
 
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextf14
				add qword[bintodec_reg], 16

			.nextf14:
		mov al, byte[fila_bits_s + 28]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextf15
				add qword[bintodec_reg], 8

			.nextf15:
		mov al, byte[fila_bits_s + 29]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextf16
				add qword[bintodec_reg], 4

			.nextf16: 
		mov al, byte[fila_bits_s + 30]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextf7
				add qword[bintodec_reg], 2

			.nextf7: 
		mov al, byte[fila_bits_s + 31]
			cmp al, '1'                 ; apunta al la cadena a leer
			jne .nextf8	
				add qword[bintodec_reg], 1

		.nextf8:


			;mov rdi, format1  	  	   ; Dirección del formato (primer argumento)
			;mov rsi, qword[bintodec_reg]			   ; Cantidad total de bytes leídos (segundo argumento)
			;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
			;call printf   

		; Salto de línea después del número
			;mov rax, 1                   ; syscall: write
			;mov rdi, 1                   ; file descriptor: stdout
			;mov rsi, newline             ; Puntero al salto de línea
			;mov rdx, 1                   ; Longitud del salto de línea
			;syscall	

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi

    ret

; Entrada: rsi apunta al comienzo de la cadena de binarios
; Salida: el número binario está en rax

PC_calculo:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	mov rax, qword[PC]
	dec rax

	mov rcx, 4
	imul rax, rcx 

	add rax, 4194304  

	mov qword[PC1], rax

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
PCgp_calculo:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	mov rax, qword[Rd]
	sub rax, 268468224 
	mov rcx, 4       ; Divisor
	div rcx  

	mov qword[PCgp], rax

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
PCdata_calculo:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	mov rax, qword[Rd]
	sub rax, 268500992 
	mov rcx, 4       ; Divisor
	div rcx  
	;inc rax 

	mov qword[PCd], rax 
	  
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
PCstack_calculo:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	mov r8, qword[Rd]
	mov rax, 274877906928
	sub rax, r8
	mov rcx, 4       ; Divisor
	div rcx  
	dec rax

	mov qword[PCsp], rax  
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
;
 
Add:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	;lea rdi, [instruccion_msj]   	  	   ; Dirección del formato (primer argumento)
	;lea rsi, [instruccion_msj_add]			   ; Cantidad total de bytes leídos (segundo argumento)
	;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	;call printf  

	call Read_Rs1
	 
	call Read_Rs2
	
	mov r8, qword[Rs1]
	mov r9, qword[Rs2]
	add r9, r8
	mov qword[Rd], r9
	call Write_RD 

	;mov rdi, format  	  	   ; Dirección del formato (primer argumento)
	;mov rsi, mensaje1			   ; Cantidad total de bytes leídos (segundo argumento)
	;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	;call printf 
	
	  
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
Sub:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	;lea rdi, [instruccion_msj]   	  	   ; Dirección del formato (primer argumento)
	;lea rsi, [instruccion_msj_sub]			   ; Cantidad total de bytes leídos (segundo argumento)
	;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	;call printf 

	call Read_Rs1
	call Read_Rs2
	
	mov r8, qword[Rs1]
	mov r9, qword[Rs2]
	sub r8, r9
	mov qword[Rd], r8
	call Write_RD 

	;mov rdi, format  	  	   ; Dirección del formato (primer argumento)
	;mov rsi, mensaje1			   ; Cantidad total de bytes leídos (segundo argumento)
	;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	;call printf 

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
Sll:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	;lea rdi, [instruccion_msj]   	  	   ; Dirección del formato (primer argumento)
	;lea rsi, [instruccion_msj_sll]			   ; Cantidad total de bytes leídos (segundo argumento)
	;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	;call printf 
  
	call Read_Rs1
	call Read_Rs2
	mov rax, qword [Rs1]
	mov rbx, qword [Rs2]   
	.loop_sll:
		mov rcx, 2
		imul rax, rcx 

	dec rbx	
	cmp rbx, 0
	jg .loop_sll

	mov qword [Rd], rax
	call Write_RD 
		
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
  
 ret
Addi:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	call Inm_Tipo_I 

	call Read_Rs1  
	mov r8, qword[Rs1]
	mov r9, qword[Inm_I]
	add r8, r9
	mov qword[Rd], r8
	call Write_RD 

	;mov rdi, format  	  	   ; Dirección del formato (primer argumento)
	;mov rsi, mensaje1			   ; Cantidad total de bytes leídos (segundo argumento)
	;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	;call printf  
	  
	  
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
Auipc:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi
  
	call Inm_Tipo_U
	call PC_calculo

	mov r8, qword [Inm_U] 
	mov rax, qword [PC1]  

	add rax, r8

	mov qword [Rd], rax
	call Write_RD

	;mov rdi, format  	  	   ; Dirección del formato (primer argumento)
	;mov rsi, mensaje1			   ; Cantidad total de bytes leídos (segundo argumento)
	;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	;call printf  
	   
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
Lw:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	call Inm_Tipo_I
	call Read_Rs1

	mov r8, qword [Inm_I]
	mov rax, qword [Rs1]
	 
	add rax, r8
	mov qword[Rd], rax

	;input
		cmp rax, -65532
		jg .gp_ 
			mov r8, qword [input_char]
			mov qword[Rd], r8

			;mov rax, qword[input_char] 
			;mov rdi, lw_input_msj 	  	   ; Dirección del formato (primer argumento)
			;mov rsi, rax			   ; Cantidad total de bytes leídos (segundo argumento)
			;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
			;call printf 
			
			jmp .lw_done

	.gp_:
		cmp rax, 268468224
		jl .data_
			cmp rax, 268500992
			jge .data_
				call PCgp_calculo 
				mov rax, qword[PCgp]
				imul rax, 8 
				mov r9, qword[gp_memory + rax]
				mov qword[Rd], r9

				;mov rax, qword[Rd] 
				;mov rdi, lw_gp_msj 	  	   ; Dirección del formato (primer argumento)
				;mov rsi, rax			   ; Cantidad total de bytes leídos (segundo argumento)
				;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
				;call printf 

			jmp .lw_done

	.data_:
		cmp rax, 268500992
		jl .stack_
			cmp rax, 269488124
			jg .stack_
				call PCdata_calculo
				mov rax, qword[PCd]
				imul rax, 8 
				mov r9, qword[datamemory + rax]
				mov qword[Rd], r9
 
				;mov rdi, lw_data_msj 	  	   ; Dirección del formato (primer argumento)
				;mov rsi, r9			   ; Cantidad total de bytes leídos (segundo argumento)
				;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
				;call printf 

			jmp .lw_done

	.stack_:
		cmp rax, 269488124
		jle .lw_done
			mov r8, 274877906928
			cmp rax, r8
			jg .lw_done
				call PCstack_calculo
				mov rax, qword[PCsp]
				imul rax, 8 
				mov r9, qword[stack_memory + rax]
				mov qword[Rd], r9

				;mov rax, qword[PCsp] 
				;mov rdi, lw_stack_msj	  	   ; Dirección del formato (primer argumento)
				;mov rsi, rax			   ; Cantidad total de bytes leídos (segundo argumento)
				;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
				;call printf 
			  
	.lw_done:
  
	call Write_RD
	  
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
Sw:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	call Inm_Tipo_S
	call Read_Rs1
	call Read_Rs2

	mov r8, qword [Inm_S]  
 
	mov rax, qword [Rs1]
	 
	add rax, r8
	mov qword[Rd], rax

	;input
		cmp rax, -65532
		jg .gp_1  
			mov qword[input_char], 65536  

			;mov rax, qword[input_char] 
			;mov rdi, sw_input_msj 	  	   ; Dirección del formato (primer argumento)
			;mov rsi, rax			   ; Cantidad total de bytes leídos (segundo argumento)
			;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
			;call printf 
			jmp .lw_done1 

	.gp_1:
		cmp rax, 268468224
		jl .data_1
			cmp rax, 268500992
			jge .data_1
				call PCgp_calculo
				mov rax, qword[PCgp] 
				imul rax, 8 
				mov r10, qword[Rs2]
				mov qword[gp_memory + rax], r10 

				;mov rax, qword[Rs2] 
				;mov rdi, sw_gp_msj 	  	   ; Dirección del formato (primer argumento)
				;mov rsi, rax			   ; Cantidad total de bytes leídos (segundo argumento)
				;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
				;call printf

			jmp .lw_done1

	.data_1:
		cmp rax, 268500992
		jl .stack_1
			cmp rax, 269488124
			jg .stack_1
				call PCdata_calculo
				mov rax, qword[PCd] 
				imul rax, 8 

				mov r10, qword[Rs2]
				mov qword[datamemory + rax], r10 

				;mov rax, qword[Rs2] 
				;mov rdi, sw_data_msj  	  	   ; Dirección del formato (primer argumento)
				;mov rsi, rax			   ; Cantidad total de bytes leídos (segundo argumento)
				;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
				;call printf 
  
			jmp .lw_done1

	.stack_1:
	
		cmp rax, 269488124
		jle .lw_done1
			mov r8, 274877906928
			cmp rax, r8
			jg .lw_done1
				call PCstack_calculo
				mov rax, qword[PCsp] 
				imul rax, 8 
				mov r10, qword[Rs2]
				mov qword[stack_memory + rax], r10 

				;mov rax, qword[PCsp] 
				;mov rdi, sw_stack_msj 	  	   ; Dirección del formato (primer argumento)
				;mov rsi, rax			   ; Cantidad total de bytes leídos (segundo argumento)
				;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
				;call printf 
	.lw_done1:
	 
	  
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
Jal:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi 

	mov r8, qword[PC]
	inc r8
	mov qword [Rd], r8
	call Write_RD
	 
	call Inm_Tipo_UJ
	mov r8, qword [Inm_UJ]
	cmp r8, 0
	jge .Inm_Jal_positivo
		
		mov rax, qword [Inm_UJ]
		mov rcx, -1
		imul rax, rcx 
		mov rcx, 4     			  ; Divisor
		div rcx 
		mov rcx, -1
		imul rax, rcx 

		mov r8, qword[PC] 
		add rax, r8 
		dec rax 
		mov qword[PC], rax 

	jmp .Jal_Done

	.Inm_Jal_positivo:

		mov rax, qword [Inm_UJ] 
		mov rcx, 4      		 ; Divisor
		div rcx  

		mov r8, qword[PC] 
		add rax, r8
		
		dec rax

		mov qword [PC], rax 

	 
	.Jal_Done:

	;mov rdi, salto_msj  	  	   ; Dirección del formato (primer argumento)
	;mov rsi, rax			   ; Cantidad total de bytes leídos (segundo argumento)
	;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	;call printf  
	  
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
Jmp:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	
	call Inm_Tipo_UJ
	mov r8, qword [Inm_UJ]
	cmp r8, 0
	jge .Inm_J_positivo

		mov rax, qword [Inm_UJ]
		mov rcx, -1
		imul rax, rcx 
		mov rcx, 4     			  ; Divisor
		div rcx 
		mov rcx, -1
		imul rax, rcx 

		mov r8, qword[PC] 
		add rax, r8 
		dec rax 
		mov qword[PC], rax 
			  
	jmp .J_Done

	.Inm_J_positivo:

		mov rax, qword [Inm_UJ] 
		mov rcx, 4      		 ; Divisor
		div rcx  

		mov r8, qword[PC] 
		add rax, r8
		
		dec rax

		mov qword [PC], rax
	 
	.J_Done:

	;mov rdi, salto_msj  	  	   ; Dirección del formato (primer argumento)
	;mov rsi, rax			   ; Cantidad total de bytes leídos (segundo argumento)
	;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	;call printf 
	
	  
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
Jalr:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi
 

	mov r8, qword[PC]
	inc r8
	mov qword [Rd], r8
	call Write_RD
	
	call Read_Rs1

	call Inm_Tipo_I
	mov r8, qword [Inm_I]
	cmp r8, 0
	jge .Inm_Jalr_positivo

		mov rax, qword[Rs1] 
		dec rax
		mov qword[PC], rax 

	jmp .Jalr_Done

	.Inm_Jalr_positivo:

		mov rax, qword[Rs1] 

		dec rax
		mov qword[PC], rax 
	 
	.Jalr_Done:

	;mov rdi, salto_msj  	  	   ; Dirección del formato (primer argumento)
	;mov rsi, rax			   ; Cantidad total de bytes leídos (segundo argumento)
	;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	;call printf 
	
	  
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
Bge:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	;lea rdi, [instruccion_msj]   	  	   ; Dirección del formato (primer argumento)
	;lea rsi, [instruccion_msj_bge]			   ; Cantidad total de bytes leídos (segundo argumento)
	;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	;call printf 
  
	call Inm_Tipo_SB

	call Read_Rs1 
	call Read_Rs2 
	mov r8, qword[Rs1]
	mov r9, qword[Rs2]

	cmp r8, r9
	jl .bge_done
		mov rax, qword[Inm_SB] 
		cmp rax, 0
		jge .bge_positivo
		
		;Negativo
			imul rax, -1 

			mov rcx, 2       			; Divisor
			div rcx  

			dec rax

			mov rcx, 4       			; Divisor
			div rcx 

			inc rax

			mov rcx, 2       			; Divisor
			div rcx 

			inc rax

			mov r8, qword[PC] 
			sub r8, rax 
			mov qword [PC], r8

			jmp .bge_done

		.bge_positivo:

			mov rax, qword[Inm_SB] 
			mov rcx, 4       			; Divisor
			div rcx 
	
			mov rcx, 4       			; Divisor
			div rcx  

			mov r8, qword[PC] 
			add rax, r8
			dec rax
			mov qword [PC], rax

			;mov rdi, salto_msj  	  	   ; Dirección del formato (primer argumento)
			;mov rsi, rax			   ; Cantidad total de bytes leídos (segundo argumento)
			;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
			;call printf  

	.bge_done:

	;mov rdi, format  	  	   ; Dirección del formato (primer argumento)
	;mov rsi, mensaje1			   ; Cantidad total de bytes leídos (segundo argumento)
	;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	;call printf 
  
	  
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
Beq:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	;lea rdi, [instruccion_msj]   	  	   ; Dirección del formato (primer argumento)
	;lea rsi, [instruccion_msj_beq]			   ; Cantidad total de bytes leídos (segundo argumento)
	;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	;call printf 

	call Inm_Tipo_SB

	call Read_Rs1 
	call Read_Rs2 
	mov r8, qword[Rs1]
	mov r9, qword[Rs2]

	cmp r8, r9
	jne .beq_done
		mov rax, qword[Inm_SB] 
		cmp rax, 0
		jge .beq_positivo
		
		;Negativo
			imul rax, -1 

			mov rcx, 2       			; Divisor
			div rcx  

			dec rax

			mov rcx, 4       			; Divisor
			div rcx 

			inc rax

			mov rcx, 2       			; Divisor
			div rcx 

			inc rax

			mov r8, qword[PC] 
			sub r8, rax 
			mov qword [PC], r8

			;mov rdi, salto_msj  	  	   ; Dirección del formato (primer argumento)
			;mov rsi, r8			   ; Cantidad total de bytes leídos (segundo argumento)
			;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
			;call printf 

			jmp .beq_done

		.beq_positivo:

			mov rax, qword[Inm_SB] 
			mov rcx, 4       			; Divisor
			div rcx 
	
			mov rcx, 4       			; Divisor
			div rcx  

			mov r8, qword[PC] 
			add rax, r8
			dec rax
			mov qword [PC], rax

			;mov rdi, salto_msj  	  	   ; Dirección del formato (primer argumento)
			;mov rsi, rax			   ; Cantidad total de bytes leídos (segundo argumento)
			;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
			;call printf 

	.beq_done:
	;mov rdi, format  	  	   ; Dirección del formato (primer argumento)
	;mov rsi, mensaje1			   ; Cantidad total de bytes leídos (segundo argumento)
	;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	;call printf 
 
	  
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
Bne:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	;lea rdi, [instruccion_msj]   	  	   ; Dirección del formato (primer argumento)
	;lea rsi, [instruccion_msj_bne]			   ; Cantidad total de bytes leídos (segundo argumento)
	;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	;call printf 

	call Inm_Tipo_SB

	call Read_Rs1 
	call Read_Rs2 
	mov r8, qword[Rs1]
	mov r9, qword[Rs2]

	cmp r8, r9
	je .bne_done
		mov rax, qword[Inm_SB] 
		cmp rax, 0
		jge .bne_positivo
		
		;Negativo
			imul rax, -1 

			mov rcx, 2       			; Divisor
			div rcx  

			dec rax

			mov rcx, 4       			; Divisor
			div rcx 

			inc rax

			mov rcx, 2       			; Divisor
			div rcx 

			inc rax

			mov r8, qword[PC] 
			sub r8, rax 
			mov qword [PC], r8

			;mov rdi, salto_msj  	  	   ; Dirección del formato (primer argumento)
			;mov rsi, r8			   ; Cantidad total de bytes leídos (segundo argumento)
			;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
			;call printf 

			jmp .bne_done

		.bne_positivo:
			mov rax, qword[Inm_SB] 

			mov rcx, 4       			; Divisor
			div rcx  

			mov rcx, 4       			; Divisor
			div rcx  

			dec rax

			mov r8, qword[PC] 
			add rax, r8 
			mov qword [PC], rax

			;mov rdi, salto_msj  	  	   ; Dirección del formato (primer argumento)
			;mov rsi, rax			   ; Cantidad total de bytes leídos (segundo argumento)
			;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
			;call printf 
	.bne_done:

	;mov rdi, format  	  	   ; Dirección del formato (primer argumento)
	;mov rsi, mensaje1			   ; Cantidad total de bytes leídos (segundo argumento)
	;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	;call printf 
	
	  
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
Blt:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	;lea rdi, [instruccion_msj]   	  	   ; Dirección del formato (primer argumento)
	;lea rsi, [instruccion_msj_blt]			   ; Cantidad total de bytes leídos (segundo argumento)
	;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	;call printf  

	call Inm_Tipo_SB

	call Read_Rs1 
	call Read_Rs2 
	mov r8, qword[Rs1]
	mov r9, qword[Rs2]

	cmp r8, r9
	jge .blt_done
		mov rax, qword[Inm_SB] 
		cmp rax, 0
		jge .blt_positivo
		
		;Negativo
			imul rax, -1 

			mov rcx, 2       			; Divisor
			div rcx  

			dec rax

			mov rcx, 4       			; Divisor
			div rcx 

			inc rax

			mov rcx, 2       			; Divisor
			div rcx 

			inc rax

			mov r8, qword[PC] 
			sub r8, rax 
			mov qword [PC], r8

			;mov rdi, salto_msj  	  	   ; Dirección del formato (primer argumento)
			;mov rsi, r8			   ; Cantidad total de bytes leídos (segundo argumento)
			;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
			;call printf 

			jmp .blt_done

		.blt_positivo:
			mov rax, qword[Inm_SB] 

			mov rcx, 4       			; Divisor
			div rcx  

			mov rcx, 4       			; Divisor
			div rcx  

			dec rax

			mov r8, qword[PC] 
			add rax, r8 
			mov qword [PC], rax

			;mov rdi, salto_msj  	  	   ; Dirección del formato (primer argumento)
			;mov rsi, rax			   ; Cantidad total de bytes leídos (segundo argumento)
			;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
			;call printf 

	.blt_done:

	;mov rdi, format  	  	   ; Dirección del formato (primer argumento)
	;mov rsi, mensaje1			   ; Cantidad total de bytes leídos (segundo argumento)
	;xor rax, rax      			 		   ; Llamadas a printf requieren que rax esté en 0 para printf en x86_64
	;call printf 
	  
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
Lui:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi
 

	call Inm_Tipo_U
	
	mov r8, qword[Inm_U]
	mov qword[Rd],r8
	call Write_RD 
	
	  
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
Addw:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	 
	
	  
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
Addiw:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi
 
	  
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
And:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	 
	  
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
Andi:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

 
	
	  
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
Or:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	 
	
	  
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
Sllw:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi

	 
	
	  
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret
Slli:
	push rax
	push rcx
	push rdx
	push rdi	
	push rsi
 
	
	  
	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
 
 ret   
;

start_screen: 

	push rax
	push rcx
	push rdx
	push rdi
	push rsi
	
	print msg1, msg1_length	
	getchar
	print clear, clear_length

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
	ret
exit:
	call canonical_on
    ; Salir del programa (syscall exit)
    mov rax, 60         ; syscall number for exit
    xor rdi, rdi        ; Código de salida 0
    syscall

	ret
 
 

break:

 ret
