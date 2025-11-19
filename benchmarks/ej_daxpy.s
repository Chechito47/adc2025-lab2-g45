	.data
	N:       .dword 4096	// Number of elements in the vectors
	Alpha:   .dword 2      // scalar value
	
	.bss 
	X: .zero  32768        // vector X(4096)*8
	Y: .zero  32768        // Vector Y(4096)*8
        Z: .zero  32768        // Vector Y(4096)*8

	.arch armv8-a
	.text
	.align	2
	.global	main
	.type	main, %function
main:
.LFB6:
	.cfi_startproc
	stp	x29, x30, [sp, -16]!
	.cfi_def_cfa_offset 16
	.cfi_offset 29, -16
	.cfi_offset 30, -8
	mov	x29, sp
	mov	x1, 0
	mov	x0, 0
	bl	m5_dump_stats

	ldr     x0, N
    	ldr     x10, =Alpha
    	ldr     x2, =X
    	ldr     x3, =Y
	ldr     x4, =Z

//---------------------- CODE HERE ------------------------------------
//=== INICIALIZACION ===
//Cargar parametros y configurar vectores
ldr w0, N              			//w0 = N = 4096 elementos
fmov d0, #2.5					//d0 = alpha = 2.5

//Obtener direcciones base de los vectores
adr x1, X              			//x1 => base de X
adr x2, Y              			//x2 => base de Y
adr x3, Z              			//x3 => base de Z
    
//Inicializar vectores X e Y
fmov d1, #1.0          			//d1 = 1.0 (valor para X,  X[i] = 1.0)
fmov d2, #2.0          			//d2 = 2.0 (valor para Y,  Y[i] = 2.0)
mov x5, #0             			//x5 = i = 0 (contador)

//=== LOOP DE INICIALIZACION ===
init_loop:
    cmp x5, x0					//Comparar i con N
    bge daxpy_start				//Si i >= N => salir a DAXPY

    str d1, [x1, x5, lsl #3]	//X[i] = 1.0 (offset = i*8)
    str d2, [x2, x5, lsl #3]	//Y[i] = 2.0 (offset = i*8)

    add x5, x5, #1				//i++
    b init_loop					//Repito loop hasta que i>=N

//=== CALCULO DAXPY CON UNROLLING x4 ===
//Procesa 4 elementos por iteracion
daxpy_start:
    mov x5, #0					//Reiniciar i = 0
    lsr w6, w0, #2         		//w6 = N/4 = 1024 iteraciones

//Loop principal => procesa 4 elementos a la vez
daxpy_loop_unrolled:
    cmp x5, x6					//Comparar i con N/4
    bge daxpy_remainder			//Si i >= N/4, procesar resto
    
    //Calcular direcciones base para esta iteración
    lsl x7, x5, #5         		//x7 = i * 32 bytes (4 doubles * 8)
    add x8, x1, x7         		//x8 => X[i*4]
    add x9, x2, x7         		//x9 => Y[i*4]
    add x10, x3, x7        		//x10 => Z[i*4]
    
    //Cargar 4 elementos de consecutivos de X
    ldr d8,  [x8]				//d8 = X[i*4 + 0]
    ldr d9,  [x8, #8]			//d9 = X[i*4 + 1]
    ldr d10, [x8, #16]			//d10 = X[i*4 + 2]
    ldr d11, [x8, #24]			//d11 = X[i*4 + 3]
    
    //Cargar 4 elementos de consecutivos de Y
    ldr d12, [x9]				//d12 = Y[i*4 + 0]
    ldr d13, [x9, #8]			//d13 = Y[i*4 + 1]
    ldr d14, [x9, #16]			//d14 = Y[i*4 + 2]
    ldr d15, [x9, #24]			//d15 = Y[i*4 + 3]
    
    //Calcular 4 multiplicaciones: alpha * X[j]
    fmul d16, d0, d8			//d16 = alpha * X[i*4 + 0]
    fmul d17, d0, d9			//d17 = alpha * X[i*4 + 1]
    fmul d18, d0, d10			//d18 = alpha * X[i*4 + 2]
    fmul d19, d0, d11			//d19 = alpha * X[i*4 + 3]
    
    //Calcular 4 sumas: resultado + Y[j]
    fadd d16, d16, d12			//d16 = d16 + Y[i*4 + 0]
    fadd d17, d17, d13			//d17 = d17 + Y[i*4 + 1]
    fadd d18, d18, d14			//d18 = d18 + Y[i*4 + 2]
    fadd d19, d19, d15			//d19 = d19 + Y[i*4 + 3]
    
    //Almacenar 4 resultados en Z
    str d16, [x10]				//Z[i*4 + 0] = d16
    str d17, [x10, #8]			//Z[i*4 + 1] = d17
    str d18, [x10, #16]			//Z[i*4 + 2] = d18
    str d19, [x10, #24]			//Z[i*4 + 3] = d19
    
    add x5, x5, #1				//i++
    b daxpy_loop_unrolled		//Repetir loop hasta que i >= N/4

//=== PROCESAR ELEMENTOS RESTANTES ===
//En caso de que N no sea multiplo de 4
daxpy_remainder:
    lsl x5, x5, #2         		//Convertir indice: i = i*4

//Loop simple para elementos restantes
remainder_loop:
    cmp x5, x0					//Comparar i con N
    bge daxpy_end				//Si i >= N terminar
    
    ldr d3, [x1, x5, lsl #3]	//d3 = X[i]
    ldr d4, [x2, x5, lsl #3]	//d4 = Y[i]
    fmul d5, d0, d3				//d5 = alpha * X[i]
    fadd d5, d5, d4				//d5 = d5 + Y[i]
    str d5, [x3, x5, lsl #3]	//Z[i] = d5
    
    add x5, x5, #1				//i++
    b remainder_loop			//Repetir loop hasta que i >= N

daxpy_end:
//---------------------- END CODE -------------------------------------

	mov 	x0, 0
	mov 	x1, 0
	bl	m5_dump_stats
	mov	w0, 0
	ldp	x29, x30, [sp], 16
	.cfi_restore 30
	.cfi_restore 29
	.cfi_def_cfa_offset 0
	ret
	.cfi_endproc
.LFE6:
	.size	main, .-main
	.ident	"GCC: (Ubuntu 9.4.0-1ubuntu1~20.04.1) 9.4.0"
	.section	.note.GNU-stack,"",@progbits
