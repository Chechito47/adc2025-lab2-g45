# Arquitectura de Computadoras - 2025
## Informe Lab2:  Análisis de microarquitecturas

## Integrantes:
- **Integrante 1: Lautaro Pinilla**
- **Integrante 2: Milena Juarez**

## Ejercicios resueltos:
- Ejercicio 1

## Incisos a-b-c-d
## Codigo utilizado para incisos a-b-c-d
```assembly
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
```
## Resultados obtenidos por consola
### 1 via
#### cache=8kB, assoc=1
- system.cpu_cluster.cpus.numCycles                                      493949.0
- system.cpu_cluster.cpus.idleCycles                                     375074.0
- system.cpu_cluster.cpus.icache.overallHits::total                      24627.0
- system.cpu_cluster.cpus.dcache.ReadReq.hits::total                     500.0

#### cache=16kB, assoc=1
- system.cpu_cluster.cpus.numCycles                                      493997.0
- system.cpu_cluster.cpus.idleCycles                                     375122.0
- system.cpu_cluster.cpus.dcache.overallHits::total                      3061.0
- system.cpu_cluster.cpus.dcache.ReadReq.hits::total                     500.0

#### cache=32kB, assoc=1
- system.cpu_cluster.cpus.numCycles                                      494181.0
- system.cpu_cluster.cpus.idleCycles                                     375305.0
- system.cpu_cluster.cpus.dcache.overallHits::total                      3061.0
- system.cpu_cluster.cpus.dcache.ReadReq.hits::total                     501.0

### 2 vias
#### cache=8kB, assoc=2
- system.cpu_cluster.cpus.numCycles                                      367844.0
- system.cpu_cluster.cpus.idleCycles                                     270309.0
- system.cpu_cluster.cpus.dcache.overallHits::total                      11418.0
- system.cpu_cluster.cpus.dcache.ReadReq.hits::total                     4426.0

#### cache=16kB, assoc=2
- system.cpu_cluster.cpus.numCycles                                      367876.0
- system.cpu_cluster.cpus.idleCycles                                     270341.0
- system.cpu_cluster.cpus.dcache.overallHits::total                      11418.0
- system.cpu_cluster.cpus.dcache.ReadReq.hits::total                     4426.0

#### cache=32kB, assoc=2
- system.cpu_cluster.cpus.numCycles                                      367876.0
- system.cpu_cluster.cpus.idleCycles                                     270341.0
- system.cpu_cluster.cpus.dcache.overallHits::total                      11418.0
- system.cpu_cluster.cpus.dcache.ReadReq.hits::total                     4426.0

### 4 vias
#### cache=8kB, assoc=4
- system.cpu_cluster.cpus.numCycles                                      302151.0
- system.cpu_cluster.cpus.idleCycles                                     221905.0
- system.cpu_cluster.cpus.dcache.overallHits::total                      17712.0
- system.cpu_cluster.cpus.dcache.ReadReq.hits::total                     7699.0

#### cache=16kB, assoc=4
- system.cpu_cluster.cpus.numCycles                                      302235.0
- system.cpu_cluster.cpus.idleCycles                                     221989.0
- system.cpu_cluster.cpus.dcache.overallHits::total                      17712.0
- system.cpu_cluster.cpus.dcache.ReadReq.hits::total                     7699.0

#### cache=32kB, assoc=4
- system.cpu_cluster.cpus.numCycles                                      302235.0
- system.cpu_cluster.cpus.idleCycles                                     221989.0
- system.cpu_cluster.cpus.dcache.overallHits::total                      17712.0
- system.cpu_cluster.cpus.dcache.ReadReq.hits::total                     7699.0

### 8 vias
#### cache=8kB, assoc=8
- system.cpu_cluster.cpus.numCycles                                      302219.0
- system.cpu_cluster.cpus.idleCycles                                     221973.0
- system.cpu_cluster.cpus.dcache.overallHits::total                      17712.0
- system.cpu_cluster.cpus.dcache.ReadReq.hits::total                     7699.0

#### cache=16kB, assoc=8
- system.cpu_cluster.cpus.numCycles                                      302235.0
- system.cpu_cluster.cpus.idleCycles                                     221989.0
- system.cpu_cluster.cpus.dcache.overallHits::total                      17712.0
- system.cpu_cluster.cpus.dcache.ReadReq.hits::total                     7699.0

#### cache=32kB, assoc=8
- system.cpu_cluster.cpus.numCycles                                      302235.0
- system.cpu_cluster.cpus.idleCycles                                     221989.0
- system.cpu_cluster.cpus.dcache.overallHits::total                      17712.0
- system.cpu_cluster.cpus.dcache.ReadReq.hits::total                     7699.0
