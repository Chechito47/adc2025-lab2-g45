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
    ldr w0, N              // w0 = 4096
    
    // Cargar alpha directamente
    fmov d0, #2.5          // d0 = alpha
    
    // Cargar direcciones de vectores
    adr x1, X              // dirección de X
    adr x2, Y              // dirección de Y
    adr x3, Z              // dirección de Z
    
    // Inicializar vectores X e Y
    fmov d1, #1.0          // X[i] = 1.0
    fmov d2, #2.0          // Y[i] = 2.0
    mov x5, #0             // contador i

init_loop:
    cmp x5, x0
    bge daxpy_start
    str d1, [x1, x5, lsl #3]
    str d2, [x2, x5, lsl #3]
    add x5, x5, #1
    b init_loop

daxpy_start:
    mov x5, #0             // reiniciar i = 0

daxpy_loop:
    cmp x5, x0
    bge daxpy_end
    
    ldr d3, [x1, x5, lsl #3]   // d3 = X[i]
    ldr d4, [x2, x5, lsl #3]   // d4 = Y[i]
    
    fmul d5, d0, d3            // d5 = alpha * X[i]
    fadd d5, d5, d4            // d5 += Y[i]
    
    str d5, [x3, x5, lsl #3]   // Z[i] = d5
    
    add x5, x5, #1
    b daxpy_loop

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
