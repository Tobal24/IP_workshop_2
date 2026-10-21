# Diseño y Arquitectura del Coprocesador Vectorial en FPGA

Este documento describe la arquitectura de hardware del coprocesador (*device*) tras separar la decodificación de comandos y el procesamiento de datos respecto de los bloques de comunicación UART, integrando además la lógica de visualización en los displays de 7 segmentos mediante los módulos `bin_deco.sv` y `sevenseg.sv`.

---

## 1. Arquitectura de Alto Nivel

El sistema implementado en `top.sv` está sincronizado mediante un único reloj de 100 MHz (`clk_out1`) generado por el IP **Clocking Wizard** (`clk_wiz_0`). La arquitectura se organiza en bloques modulares siguiendo el diagrama de referencia del enunciado:

- **`uart_basic`**: Transceptor UART (115200 bps) que serializa y deserializa bytes entre el *host* (PC con MATLAB) y la FPGA.
- **`RX_Logic` + `FSM_RX_ctrl`**: Recibe los flujos de 2048 bytes de datos para cargar los vectores de 1024 elementos de 11 bits en el Puerto A de `BRAM_A` (cabecera `0`) o `BRAM_B` (cabecera `1`), levantando la señal `rx_busy` durante la carga.
- **`Command_Decoder`**: Monitorea los bytes recibidos por UART cuando `!rx_busy`, decodifica los comandos de operación (`2` a `8`), configura el modo `op_mode[2:0]` y las banderas de operación escalar (`is_man_dist`, `is_euc_dist`, `is_dot_prod`), y emite el pulso de inicio `start_op`.
- **`BRAM_A` y `BRAM_B` (`blk_mem_gen_0`)**: Memorias *True Dual Port* de 1024 palabras de 11 bits. El Puerto A se dedica a la escritura desde `RX_Logic` y el Puerto B a la lectura simultánea desde `Processing_Core`.
- **`Processing_Core`**: Contiene la ALU combinacional (`SumVec`, `AvgVec`, `ManDist`, `EucDist`, `DotProd`), el contador de direcciones de lectura (`read_address`), el registro acumulador de 32 bits (`data_reg`), el IP `cordic_0` para el cálculo de la raíz cuadrada en `EucDist` y su propia máquina de estados de control.
- **`TX_logic` + `FSM_TX_ctrl`**: Recibe las palabras de resultado de 32 bits (`result_data`) validadas por `result_valid` (`send_word`) y las serializa en 2, 3 o 4 bytes a través de la UART, confirmando el término de cada palabra mediante `tx_word_done`.
- **`Display_logic`**: Registra el resultado de las operaciones escalares (`ManDist`, `EucDist`, `DotProd`), lo convierte a 8 dígitos decimales (BCD) mediante el algoritmo secuencial *Double-Dabble*, y maneja el barrido por división de tiempo (TDM) de los 8 displays de 7 segmentos instanciando `bin_deco` y `sevenseg_rom` (`sevenseg.sv`). Si se ejecuta una operación vectorial, apaga los displays.

---

## 2. Tabla de Codificación de Comandos

| Función / Comando en MATLAB | Byte UART (`rx_data`) | `op_mode` | Acción en el Coprocesador | Bytes Transmitidos al Host |
| :--- | :---: | :---: | :--- | :---: |
| `write2dev(..., 'BRAMA', COM)` | `8'd0` + 2048 B | — | Escribe 1024 elementos en `BRAM_A` | 0 B |
| `write2dev(..., 'BRAMB', COM)` | `8'd1` + 2048 B | — | Escribe 1024 elementos en `BRAM_B` | 0 B |
| `command2dev('readVec', 'BRAMA', COM)` | `8'd2` | `3'b000` | Lee los 1024 elementos de `BRAM_A` | 2048 B (2 B/elemento) |
| `command2dev('readVec', 'BRAMB', COM)` | `8'd3` | `3'b001` | Lee los 1024 elementos de `BRAM_B` | 2048 B (2 B/elemento) |
| `command2dev('SumVec', COM)` | `8'd4` | `3'b010` | Calcula $A_i + B_i$ elemento a elemento | 2048 B (2 B/elemento) |
| `command2dev('avgVec', COM)` | `8'd5` | `3'b011` | Calcula $\lfloor(A_i + B_i)/2\rfloor$ (`>> 1`) | 2048 B (2 B/elemento) |
| `command2dev('manDist', COM)` | `8'd6` | `3'b100` | Calcula $\sum |A_i - B_i|$ y muestra en display | 3 B (24 bits) |
| `command2dev('eucDist', COM)` | `8'd7` | `3'b101` | Calcula $\lfloor\sqrt{\sum (A_i - B_i)^2}\rfloor$ (CORDIC) y muestra en display | 3 B (24 bits) |
| `command2dev('dotProd', COM)` | `8'd8` | `3'b110` | Calcula $\sum (A_i \cdot B_i)$ y muestra en display | 4 B (32 bits) |

---

## 3. Resumen de Archivos Modificados y Creados

1. **`FSM_RX_ctrl.sv` y `RX_logic.sv`**: Se extrajo la decodificación de comandos y se añadió la salida de estado `rx_busy` para indicar cuándo se está recibiendo un flujo de datos hacia las memorias BRAM.
2. **`Command_Decoder.sv`**: Nuevo módulo dedicado a decodificar los comandos `2` a `8` y generar `start_op`, `op_mode` y las banderas `is_man_dist`, `is_euc_dist` e `is_dot_prod`.
3. **`Processing_Core.sv`**: Nuevo módulo que integra las operaciones aritméticas combinacionales, el acumulador de 32 bits, el contador de lectura de BRAM, la instancia `cordic_0` y la FSM de procesamiento.
4. **`FSM_TX_ctrl.sv` y `TX_logic.sv`**: Simplificados para dedicarse exclusivamente a la serialización de palabras de 32 bits hacia la UART (2, 3 o 4 bytes según la operación).
5. **`Display_logic.sv`**: Nuevo módulo de visualización decimal en 7 segmentos que utiliza un convertidor Binario-a-BCD (*Double-Dabble*) e instancia `bin_deco` y `sevenseg_rom`.
6. **`top.sv` y `constraints.xdc`**: Actualizados para interconectar todos los bloques modulares y habilitar los pines `cathodes[6:0]` y `anodes[7:0]` de los displays de 7 segmentos.
7. **`coprocessorTesting.m`**: Actualizado para ejecutar y verificar automáticamente todos los comandos (`write2dev` en ambas memorias, `readVec` A y B, `SumVec`, `avgVec`, `manDist`, `eucDist` y `dotProd`) comparando los resultados del *device* contra el *host*.
