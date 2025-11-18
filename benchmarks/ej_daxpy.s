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
// Cargar N
    ldr w0, N
    fmov d0, #2.5
    adr x1, X
    adr x2, Y
    adr x3, Z
    
    // Inicializar vectores
    fmov d1, #1.0
    fmov d2, #2.0
    mov x5, #0

init_loop:
    cmp x5, x0
    bge daxpy_start
    str d1, [x1, x5, lsl #3]
    str d2, [x2, x5, lsl #3]
    add x5, x5, #1
    b init_loop

daxpy_start:
    mov x5, #0
    lsr w6, w0, #2         // w6 = N/4 = 1024

daxpy_loop_unrolled:
    cmp x5, x6
    bge daxpy_remainder
    
    // Calcular direcciones base para esta iteración
    lsl x7, x5, #5         // offset = i * 32 bytes (4 doubles)
    add x8, x1, x7         // dirección X[i*4]
    add x9, x2, x7         // dirección Y[i*4]
    add x10, x3, x7        // dirección Z[i*4]
    
    // Cargar 4 elementos de X
    ldr d8,  [x8]
    ldr d9,  [x8, #8]
    ldr d10, [x8, #16]
    ldr d11, [x8, #24]
    
    // Cargar 4 elementos de Y
    ldr d12, [x9]
    ldr d13, [x9, #8]
    ldr d14, [x9, #16]
    ldr d15, [x9, #24]
    
    // Calcular 4 operaciones DAXPY
    fmul d16, d0, d8
    fmul d17, d0, d9
    fmul d18, d0, d10
    fmul d19, d0, d11
    
    fadd d16, d16, d12
    fadd d17, d17, d13
    fadd d18, d18, d14
    fadd d19, d19, d15
    
    // Almacenar 4 resultados
    str d16, [x10]
    str d17, [x10, #8]
    str d18, [x10, #16]
    str d19, [x10, #24]
    
    add x5, x5, #1
    b daxpy_loop_unrolled

daxpy_remainder:
    lsl x5, x5, #2         // convertir índice
    
remainder_loop:
    cmp x5, x0
    bge daxpy_end
    
    ldr d3, [x1, x5, lsl #3]
    ldr d4, [x2, x5, lsl #3]
    fmul d5, d0, d3
    fadd d5, d5, d4
    str d5, [x3, x5, lsl #3]
    
    add x5, x5, #1
    b remainder_loop

daxpy_end://---------------------- END CODE -------------------------------------

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
