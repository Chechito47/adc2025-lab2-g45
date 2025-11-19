# Arquitectura de Computadoras - 2025
## Informe Lab2:  Análisis de microarquitecturas

## Integrantes:
- **Integrante 1: Lautaro Pinilla**
- **Integrante 2: Milena Juarez**

## Ejercicios resueltos:
- Ejercicio 1

# Incisos a-b-c-d
## Codigo utilizado
Usamos fmul y fadd porque usamos punto flotante.  
Agregamos este codigo al `benchmarks/ej_daxpy.s`:  
```asm
//=== INICIALIZACION ===
//Cargar parametros y configurar vectores
ldr w0, N              			//w0 = N = 4096 elementos
fmov d0, #2.5          			//d0 = alpha = 2.5
    
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
    str d2, [x2, x5, lsl #3]	//Y[i] = 2.0  (offset = i*8)

    add x5, x5, #1				//i++
    b init_loop					//Repito loop hasta que i>=N

//=== CALCULO DAXPY ===
daxpy_start:
    mov x5, #0             		//Reiniciar i = 0

daxpy_loop:
    cmp x5, x0					//Comparar i con N
    bge daxpy_end				//Si i >= N, terminar

    ldr d3, [x1, x5, lsl #3]   	//d3 = X[i]
    ldr d4, [x2, x5, lsl #3]   	//d4 = Y[i]

    fmul d5, d0, d3            	//d5 = alpha * X[i]
    fadd d5, d5, d4            	//d5 = d5 + Y[i]
    
    str d5, [x3, x5, lsl #3]   	//Z[i] = d5
    
    add x5, x5, #1				//i++
    b daxpy_loop				//Repito loop hasta que i>=N

daxpy_end:
```
## Resultados obtenidos
Estos son los resultados obtenidos por consola luego de modificar **size** y **assoc** de **Dcache** en `in_order.py`:  
### 1 via
| Cache | numCycles | idleCycles | overallHits | readHits |
|---------------|--------|-------|------------|------|
| 8kB | 493949 | 375074 | 3061 | 500 |
| 16kB | 493997 | 375122 | 3061 | 500 |
| 32kB | 494181 | 375305 | 3061 | 501 |

### 2 vias
| Cache | numCycles | idleCycles | overallHits | readHits |
|---------------|--------|-------|------------|------|
| 8kB | 367844 | 270309 | 11418 | 4426 |
| 16kB | 367876 | 270341 | 11418 | 4426 |
| 32kB | 367876 | 270341 | 11418 | 4426 |

### 4 vias
| Cache | numCycles | idleCycles | overallHits | readHits |
|---------------|--------|-------|------------|------|
| 8kB | 302151 | 221905 | 17712 | 7699 |
| 16kB | 302235 | 221989 | 17712 | 7699 |
| 32kB | 302235 | 221989 | 17712 | 7699 |

### 8 vias
| Cache | numCycles | idleCycles | overallHits | readHits |
|---------------|--------|-------|------------|------|
| 8kB | 302219 | 221973 | 17712 | 7699 |
| 16kB | 302235 | 221989 | 17712 | 7699 |
| 32kB | 302235 | 221989 | 17712 | 7699 |

### Comparativa grafica de los resultados
![ScreenShot](Imagenes/comparativa_vias_1.png)
![ScreenShot](Imagenes/comparativa_vias_2.png)

## Explicacion de los resultados obtenidos
### Caracteristicas del codigo
El codigo implementado tiene las siguientes caracteristicas clave:  
**Patron de acceso a memoria:**
```asm
ldr d3, [x1, x5, lsl #3]   //Lee X[i]
ldr d4, [x2, x5, lsl #3]   //Lee Y[i]
str d5, [x3, x5, lsl #3]   //Escribe Z[i]
```
- No hay reutilizacion temporal, cada elemento se usa una sola vez
- Hay tres vectores activos (X, Y y Z) accedidos en cada iteracion
- Los vectores estan ubicados consecutivamente en memoria

### Analisis de 1 via

| Cache | numCycles | readHits | Hit Rate |
|--------|-----------|-------|---------------|
| 8kB | 493949 | 500 | 6,1% |
| 16kB | 493997 | 500 | 6,1% |
| 32kB | 494181 | 501 | 6,1% |

El hit rate es bajo, apenas del 6,1%.  
Vemos que el tamaño de la cache no afecta el rendimiento ya que siempre hay 494K ciclos.  

**Conflictos de mapeo:**  
En mapeo directo, cada direccion mapea a una unica linea:
```
indice_linea = (direccion / tamano linea) % numero lineas
```

El problema radica en que los vectores X, Y, Z estan separados por 32KB. Para todas las caches, los elementos X[i], Y[i] y Z[i] mapean a la misma linea causando thrashing:
```
Ejemplo para i=0:
1. Lee X[0] => Miss, carga linea N
2. Lee Y[0] => Miss, desaloja X[0], carga linea N
3. Escribe Z[0] => Miss, desaloja Y[0], carga linea N
```
**Entonces:**
- 75% del tiempo ocioso esperando memoria
- Hit rate de lectura del 6,1% (500 de 8198 lecturas)
- Aumentar el tamaño de la cache no cambia nada

### Analisis de 2 vias

| Cache | numCycles | readHits | Hit Rate | Mejora vs 1 via |
|--------|-----------|-------|------|---------------|
| 8kB | 367844 | 4426 | 54% | 25,6% mejor |
| 16kB | 367876| 4426 | 54% | 25,5% mejor |
| 32kB | 367876| 4426 | 54% | 25,5% mejor |

Vemos que hay una clara mejora pero el tamaño de la cache sigue sin importar demasiado.  
**Explicacion:** Con 2 vias cada indice puede almacenar 2 lineas diferentes por lo que X[i] e Y[i] pueden coexistir momentaneamente:
```
Lee X[i] => Se carga en via 0
Lee Y[i] => Se carga en via 1 (X[i] permanece)
Escribe Z[i] => Desaloja linea menos usada
```
**Motivo porque el tamaño de cache no importa:**
- Tenemos 10-20 lineas simultaneas activas
- No hay reutilizacion temporal
- 8KB ya es suficiente para las lineas activas

Probablemente si la cache fuese mas chiquita si importaria.  

**Entonces**:  
- Hit rate sube a 54% (9 veces mejor que 1 via)
- 126K ciclos menos
- 73% del tiempo sigue ocioso

### Analisis de 4 vias

| Cache | numCycles | readHits | Hit Rate | Mejora vs 2 vias |
|--------|-----------|-------|------|---------------|
| 8kB | 302151   | 7699 | 94% | 17,9% mejor |
| 16kB | 302235   | 7699 | 94% | 17,8% mejor |
| 32kB | 302235   | 7699 | 94% | 17,8% mejor |

Ahora vemos que hay una **gran** mejora, el hit rate es bastante alto pero el tamaño de la cache sigue sin importar demasiado (el motivo sigue siendo el mismo que antes).  
**Explicacion de la mejora:** El sistema que detecta los patrones secuenciales y trae datos anticipadamente.  

Con 4 vias hay espacio para:
- Lineas actuales de X, Y, Z
- Lineas traidas por adelantado
- Multiples lineas consecutivas activas

**Ejemplo:**
```
Cache contiene:
  Via 0: X[i], X[i+1] (traida por adelantado)
  Via 1: Y[i], Y[i+1] (traida por adelantado)
  Via 2: Z[i-1] (escritura anterior)
  Via 3: Datos traidos por adelantados adicionales
```
Entonces las lecturas de X[i] e Y[i] ahora son hits porque se trajeron por adelantado.  

**Entonces:**  
- Hit rate 94% (casi todos los accesos ahora son exitosos)
- 65K ciclos menos que 2 vias
- 39% reduccion total vs 1 via
- 73% tiempo ocioso (sigue siendo muy alto)

### Analisis de 8 vias

| Cache | numCycles | readHits | Diferencia vs 4 vias |
|--------|-----------|-------|---------------|
| 8kB | 302219 | 7699 | +68 ciclos (0,02%) |
| 16kB | 302235 | 7699 | 0 ciclos |
| 32kB | 302235 | 7699 | 0 ciclos |

Vemos que el rendimiento es practicamente identico a 4 vias.  

**Explicacion:**  
- Acceso secuencial (no hay saltos aleatorios)
- Sin reutilizacion temporal (cada dato se usa una vez)
- Las lineas que se traen anticipadamente ya eran suficientes en 4 vias

Con 4 vias ya hay suficiente espacio. Pasar a 8 vias solo agrega capacidad que no usamos.  

### Resumen

| Vias | Ciclos | Reduccion | Hit Rate | % Ocioso |
|--------|-----------|-------|------|---------------|
| 1 | ~494K  | - | 6,1% | 75% |
| 2 | ~368K  | 25% | 54% | 73% |
| 4 | ~302K  | 39% | 94% | 73% |
| 8 | ~302K  | 39% | 94% | 73% |

- 1 via = mucho thrashing
- 2 vias = mayor mejora relativa (reduce conflictos criticos)
- 4 vias = rendimiento optimo (94% hits)
- 8 vias sin beneficio
- Tamaño de cache irrelevante (sin reutilizacion temporal)

# Incisos e-f
## Codigo utilizado (mejorado)
```asm
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
```
### Tecnicas aplicadas:
#### **Loop unrolling x4**
1. Reduce iteraciones de 4096 a 1024
2. Disminuye branches en 75%

| Operacion | Normal | Optimizado | Reduccion |
|---------------|--------|-------|------------|
| Branches | 4096 | 1024 | 75% menos |
| Comparaciones | 4096 | 1024 | 75% menos |
| Incrementos | 4096 | 1024 | 75% menos |

Con loop unrolling pasamos de procesar 1 elemento por iteracion a procesar 4 en cada vuelta del bucle.  
Por ejemplo, supongamos que cada branch mal predicho cuesta 10 ciclos y que tenemos una tasa de 1% de miss, entonces:  
- Normal: 4096 branches × 0.01% error × 10 ciclos = 410 ciclos perdidos
- Optimizado: 1024 branches × 0.01% error × 10 ciclos = 102 ciclos perdidos

#### **Uso intensivo de registros**
1. 12 registros FP (d8-d19)
2. Datos permanecen en registros entre load y store
3. Reduce presion sobre cache

Nuestro codigo mejorado usa 12 registros de punto flotante:
- d0:      alpha (constante)
- d8-d11:  4 valores de X (X[i], X[i+1], X[i+2], X[i+3])
- d12-d15: 4 valores de Y (Y[i], Y[i+1], Y[i+2], Y[i+3])
- d16-d19: 4 resultados intermedios
- Total:   13 registros

Si hacemos una compracion entre el codigo normal y el mejorado al querer procesar 4 accesos a memoria tendriamos lo siguiente:  
**Flujo del codigo normal:**
```asm
//Iteracion 1 (i=0):
ldr d3, [x1, x5, lsl #3]   //Load X[0] => d3
ldr d4, [x2, x5, lsl #3]   //Load Y[0] => d4
fmul d5, d0, d3            //d5 = alpha * X[0]
fadd d5, d5, d4            //d5 = d5 + Y[0]
str d5, [x3, x5, lsl #3]   //Store Z[0]

//Iteracion 2 (i=1):
ldr d3, [x1, x5, lsl #3]   //Load X[1] => d3 (sobreescribe X[0])
ldr d4, [x2, x5, lsl #3]   //Load Y[1] => d4 (sobreescribe Y[0])
fmul d5, d0, d3            //d5 = alpha * X[1]
fadd d5, d5, d4            //d5 = d5 + Y[1]
str d5, [x3, x5, lsl #3]   //Store Z[1]

//Iteracion 3 (i=2):
ldr d3, [x1, x5, lsl #3]   //Load X[2] => d3
ldr d4, [x2, x5, lsl #3]   //Load Y[2] => d4
fmul d5, d0, d3
fadd d5, d5, d4
str d5, [x3, x5, lsl #3]   //Store Z[2]

//Iteracion 4 (i=3):
ldr d3, [x1, x5, lsl #3]   //Load X[3] => d3
ldr d4, [x2, x5, lsl #3]   //Load Y[3] => d4
fmul d5, d0, d3
fadd d5, d5, d4
str d5, [x3, x5, lsl #3]   //Store Z[3]
```
El problema es que los datos se descartan luego de usarlos.

**Flujo del codigo mejorado:**
```asm
//Calcular direcciones base
add x8, x1, x7         //x8 = direccion X[i*4]
add x9, x2, x7         //x9 = direccion Y[i*4]
add x10, x3, x7        //x10 = direccion Z[i*4]

//Cargar todos los X juntos
ldr d8,  [x8]          //X[0] => d8
ldr d9,  [x8, #8]      //X[1] => d9
ldr d10, [x8, #16]     //X[2] => d10
ldr d11, [x8, #24]     //X[3] => d11

//Cargar todos los Y juntos
ldr d12, [x9]          //Y[0] => d12
ldr d13, [x9, #8]      //Y[1] => d13
ldr d14, [x9, #16]     //Y[2] => d14
ldr d15, [x9, #24]     //Y[3] => d15

//Calcular todos los productos juntos
fmul d16, d0, d8       // d16 = alpha * X[0]
fmul d17, d0, d9       // d17 = alpha * X[1]
fmul d18, d0, d10      // d18 = alpha * X[2]
fmul d19, d0, d11      // d19 = alpha * X[3]

//Calcular todas las sumas juntas
fadd d16, d16, d12     // d16 = d16 + Y[0]
fadd d17, d17, d13     // d17 = d17 + Y[1]
fadd d18, d18, d14     // d18 = d18 + Y[2]
fadd d19, d19, d15     // d19 = d19 + Y[3]

//Guardar todos los resultados juntos
str d16, [x10]         //Z[0]
str d17, [x10, #8]     //Z[1]
str d18, [x10, #16]    //Z[2]
str d19, [x10, #24]    //Z[3]
```
Ahora los 4 valores de X e Y estan todos juntos en registros durante todo el calculo.

| Operacion | Normal | Mejorado |
|-----------|-------------------|---------------------|
| Loads de X | 4 (uno por iteracion) | 4 (todos juntos) |
| Loads de Y | 4 (uno por iteracion) | 4 (todos juntos) |
| Stores de Z | 4 (uno por iteracion) | 4 (todos juntos) |
| Total accesos | 12 | 12 |

La diferencia radica en los miss y en los hits:  
**Normal (entrelazan X, Y, Z):**
```
T1: Load X[0] => Miss, trae line de cache
T2: Load Y[0] => Miss, trae line de cache  
T3: Store Z[0] => Miss, trae line de cache
T4: Load X[1] => ¿Hit o Miss? Depende
```

**Mejorados (X juntos, luego Y juntos):**
```
T1: Load X[0] => Miss, trae line de cache
T2: Load X[1] => Hit (esta en la misma line que X[0])
T3: Load X[2] => Hit (esta en la misma line)
T4: Load X[3] => Hit (esta en la misma line)
T5: Load Y[0] => Miss, trae line de cache
T6: Load Y[1] => Hit
T7: Load Y[2] => Hit
T8: Load Y[3] => Hit
```
De esta forma al traer una line traemos todos los X o Y segun corresponda.

#### **Offsets inmediatos:**
1. `ldr d9, [x8, #8]` mas eficiente (ejemplo)
2. Mejor uso del pipeline

**Flujo del codigo normal:**
```asm
add x5, x5, #1              //Modifica x5
ldr d3, [x1, x5, lsl #3]    //Depende de x5
```

**Flujo del codigo mejorado:**
```asm
add x8, x1, x7              //Se calcula una vez
ldr d8,  [x8]               //Usa x8
ldr d9,  [x8, #8]           //Usa x8
ldr d10, [x8, #16]          //Usa x8
```
Esta forma no hay ningun hazard, mejora la dependencia de datos. Evitamos tener que stallear.

### Resultados con loop unrolling x4, cache=32kB, assoc=1
| Cache | numCycles | idleCycles | overallHits | readHits |
|---------------|--------|-------|------------|------|
| 32kB | 342847 | 270092 | 8426 | 4708 |

#### Comparativa entre codigo mejorado de 1 via y codigo normal de 2 vias
![ScreenShot](Imagenes/cod-normal_vs_cod-mejorado-1.png)
![ScreenShot](Imagenes/cod-normal_vs_cod-mejorado-2.png)

Las optimizaciones antes mencionadas compensan la desventaja de tener una sola via y logran incluso superar la performance del codigo normal con 2 vias.
### Resultados con out_of_order.py
Estos son los resultados obtenidos por consola luego de modificar **size** y **assoc** de **L1D** en `out_of_order.py`:  

| Cache | numCycles | idleCycles | overallHits | readHits |
|---------------|--------|-------|------------|------|
| 32kB | 109576 | 814 | 6079 | 4281 |

*Para correr la simulacion modificamos el **PROCESSOR** de `run_simulation.sh`*  
#### Comparativa entre codigo mejorado con in_order y out_of_order
![ScreenShot](Imagenes/in-order_vs_out-of-order-1.png)
![ScreenShot](Imagenes/in-order_vs_out-of-order-2.png)

La clave de esta gran mejora es la reduccion de los ciclos ociosos:  
| Procesador | Ciclos ociosos | % tiempo ocioso |
|------------|----------------|-----------------|
| In-order | 270092 | 79% |
| Out-of-order | 814 | 0.7% |

### Comparativa entre todas las configuraciones (obviando cache)

| Configuracion | Vias | numCycles | Hit Rate | Mejora vs normal 1 via |
|---------------|------|--------|----------------|------------------------|
| Normal | 1 | ~494K | ~6,1% | - |
| Normal | 2 | ~368K | ~54% | ~25.6% |
| Normal | 4 | ~302K | ~94% | ~38.8% |
| Normal | 8 | ~302K | ~94% | ~38.8% |
| **Loop unrolling** | **1** | **342847** | **57%** | **30,6%** |

**Conclusion de la comparacion:**

El codigo mejorado con loop unrolling y 1 via logra:
- Superar al 2 vias en 7% (342K vs 368K)
- Acercarse a 4 vias con solo 13% mas ciclos (342K vs 302K)
- Hit rate de 57% (mejor que 2 vias)

Esto demuestra que las optimizaciones compensan las limitaciones, logrando el objetivo del inciso e.

## Conclusion
El codigo mejorado con loop unrolling logro mejor performance que 2-vias con solo una via. Ademas, al usar **out_of_order.py**, se mejoro aun mas la performance. Todo esto se debe en lineas generales a:
- Menos misspredictions de branches
- Mejor aprovechamiento del pipeline
- Datos en registros reducen accesos a memoria

El codigo mejorado con loop unrolling logro mejor performance que 2 vias con solo 1 via (342K vs 368K ciclos), cumpliendo el objetivo del inciso e.  

Al ejecutar este codigo optimizado en el procesador **out_of_order** se obtuvo una mejora del 68% adicional (109K ciclos), logrando un rendimiento 3 veces superior al **in_order** optimizado y 4 veces superior al codigo original con 1 via.

**Factores clave de la mejora:**
- Loop unrolling: Reduce overhead de control (75% menos branches)
- Uso intensivo de registros: Mejora localidad
- Offsets inmediatos: Elimina hazards y mejora pipeline
- Out_of_order: Oculta latencia de memoria mediante ejecucion paralela (99,7% menos de tiempo ocioso)

Los resultados obtenidos confirman que las optimizaciones del inciso **e** pueden compensar limitaciones usar 1 via.  
Ademas confirma que la ejecucion de **out_of_order** aumenta el beneficio de estas optimizaciones al usar mejor el paralelismo.
