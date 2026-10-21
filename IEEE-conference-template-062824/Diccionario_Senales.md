# Diccionario de Señales del Proyecto

Este documento contiene el catálogo completo de todas las señales (puertos de entrada/salida, registros y cables de interconexión interna) utilizadas en cada módulo e IP del coprocesador vectorial.

---

## 1. Módulo Principal: `top` (`top.sv`)

### 1.1. Puertos de Entrada / Salida (Pines Físicos FPGA — `constraints.xdc`)

| Señal | Dirección | Ancho | Pin FPGA | Función |
| :--- | :---: | :---: | :---: | :--- |
| `clk` | `input` | 1 bit | `E3` | Reloj base externo de 100 MHz de la tarjeta Nexys A7. |
| `resetN` | `input` | 1 bit | `C12` | Botón de reinicio externo activo en bajo (`CPU_RESETN`). |
| `rx` | `input` | 1 bit | `C4` | Línea serial de recepción UART desde el *host* (PC). |
| `tx` | `output` | 1 bit | `D4` | Línea serial de transmisión UART hacia el *host* (PC). |
| `rx_pmod` | `output` | 1 bit | `C17` | Espejo de la línea `rx` hacia el conector PMOD JA para monitoreo externo. |
| `tx_pmod` | `output` | 1 bit | `D18` | Espejo de la línea `tx` hacia el conector PMOD JA para monitoreo externo. |
| `cathodes` | `output` | `[6:0]` (7 bits) | `T10..L18` | Señales de cátodos activos en bajo (`CA` en bit 6 a `CG` en bit 0) para los displays de 7 segmentos. |
| `anodes` | `output` | `[7:0]` (8 bits) | `U13..J17` | Señales de habilitación de ánodos activos en bajo (`AN7` a `AN0`) para multiplexar los 8 displays. |

### 1.2. Señales Internas de Interconexión en `top.sv`

| Señal | Tipo | Ancho | Función |
| :--- | :---: | :---: | :--- |
| `reset` | Interna | 1 bit | Señal de reinicio global activa en alto (`~resetN`). |
| `clk_out1` | Interna | 1 bit | Reloj principal del sistema (100 MHz) generado por el IP `clk_wiz_0`. Sincroniza todos los módulos. |
| `locked` | Interna | 1 bit | Indicador de enganche y estabilidad de fase del PLL/MMCM en `clk_wiz_0`. |
| `rx_in` | Interna | 1 bit | Conexión interna de la línea `rx` hacia `uart_basic`. |
| `tx_in` | Interna | 1 bit | Conexión interna de la salida `tx` de `uart_basic` hacia los puertos `tx` y `tx_pmod`. |
| `rx_data` | Interna | `[7:0]` (8 bits) | Byte paralelo recibido por `uart_basic`, distribuido hacia `RX_Logic` y `Command_Decoder`. |
| `rx_ready` | Interna | 1 bit | Pulso de 1 ciclo de reloj que indica que `rx_data` contiene un nuevo byte válido recibido por UART. |
| `tx_data` | Interna | `[7:0]` (8 bits) | Byte paralelo entregado por `TX_logic` hacia `uart_basic` para ser transmitido al *host*. |
| `tx_start` | Interna | 1 bit | Pulso de disparo desde `TX_logic` hacia `uart_basic` para iniciar la transmisión de `tx_data`. |
| `tx_busy` | Interna | 1 bit | Bandera desde `uart_basic` hacia `TX_logic` que indica que el transmisor serial está ocupado enviando un byte. |
| `ena` | Interna | 1 bit | Señal global de habilitación del Puerto A generada por `RX_Logic` durante la escritura de vectores. |
| `wea` | Interna | 1 bit | Señal global de habilitación de escritura del Puerto A generada por `RX_Logic`. |
| `addra` | Interna | `[9:0]` (10 bits) | Dirección de escritura (0 a 1023) generada por `RX_Logic` para el Puerto A de las memorias. |
| `dina` | Interna | `[10:0]` (11 bits) | Palabra de datos de 11 bits armada por `RX_Logic` para escribirse en las memorias BRAM. |
| `rx_bram_sel` | Interna | 1 bit | Selector de memoria destino generado por `RX_Logic` (`1'b0` = `BRAM_A`, `1'b1` = `BRAM_B`). |
| `rx_busy` | Interna | 1 bit | Indica que `RX_Logic` está recibiendo los 2048 bytes de un vector; inhibe a `Command_Decoder`. |
| `start_op` | Interna | 1 bit | Pulso de 1 ciclo desde `Command_Decoder` hacia `Processing_Core` que inicia la operación solicitada. |
| `op_mode` | Interna | `[2:0]` (3 bits) | Código binario de la operación activa decodificada por `Command_Decoder`. |
| `is_man_dist` | Interna | 1 bit | Bandera activa cuando la operación seleccionada es distancia de Manhattan (`op_mode == 3'b100`). |
| `is_euc_dist` | Interna | 1 bit | Bandera activa cuando la operación seleccionada es distancia Euclideana (`op_mode == 3'b101`). |
| `is_dot_prod` | Interna | 1 bit | Bandera activa cuando la operación seleccionada es producto punto (`op_mode == 3'b110`). |
| `enb` | Interna | 1 bit | Habilitación de lectura del Puerto B de ambas memorias BRAM, controlada por `Processing_Core`. |
| `addrb` | Interna | `[9:0]` (10 bits) | Dirección de lectura (0 a 1023) del Puerto B de ambas memorias BRAM, generada por `Processing_Core`. |
| `result_data` | Interna | `[31:0]` (32 bits) | Palabra de resultado generada por `Processing_Core` y enviada hacia `TX_logic` y `Display_logic`. |
| `result_valid` | Interna | 1 bit | Pulso de 1 ciclo desde `Processing_Core` que valida `result_data` y dispara a `TX_logic` (`send_word`) y `Display_logic`. |
| `tx_word_done` | Interna | 1 bit | Pulso de 1 ciclo desde `TX_logic` hacia `Processing_Core` indicando que terminó de enviar todos los bytes de la palabra actual. |
| `ena_A`, `ena_B` | Internas | 1 bit c/u | Habilitación individual del Puerto A de `BRAM_A` y `BRAM_B` demultiplexada según `rx_bram_sel`. |
| `wea_A`, `wea_B` | Internas | 1 bit c/u | Habilitación de escritura individual del Puerto A de `BRAM_A` y `BRAM_B` según `rx_bram_sel`. |
| `addra_A`, `addra_B` | Internas | `[9:0]` (10 bits) | Buses de dirección de escritura conectados al Puerto A de `BRAM_A` y `BRAM_B` (`addra`). |
| `dina_A`, `dina_B` | Internas | `[10:0]` (11 bits) | Buses de datos de entrada conectados al Puerto A de `BRAM_A` y `BRAM_B` (`dina`). |
| `douta_A`, `douta_B` | Internas | `[10:0]` (11 bits) | Buses de salida de lectura del Puerto A de `BRAM_A` y `BRAM_B` (no utilizados, Puerto A es solo de escritura). |
| `enb_A`, `enb_B` | Internas | 1 bit c/u | Habilitación de lectura del Puerto B para `BRAM_A` y `BRAM_B` (conectadas a `enb`). |
| `web_A`, `web_B` | Internas | 1 bit c/u | Habilitación de escritura del Puerto B fijadas en `1'b0` (Puerto B es solo de lectura). |
| `addrb_A`, `addrb_B` | Internas | `[9:0]` (10 bits) | Buses de dirección de lectura del Puerto B para `BRAM_A` y `BRAM_B` (conectadas a `addrb`). |
| `dinb_A`, `dinb_B` | Internas | `[10:0]` (11 bits) | Buses de entrada de datos del Puerto B fijados en `11'd0`. |
| `doutb_A`, `doutb_B` | Internas | `[10:0]` (11 bits) | Palabras de 11 bits leídas desde el Puerto B de `BRAM_A` y `BRAM_B` que ingresan a `Processing_Core`. |

---

## 2. Recepción UART y Escritura en BRAM: `RX_Logic` y `FSM_RX_ctrl`

### 2.1. Módulo `RX_Logic` (`RX_logic.sv`)

| Señal / Parámetro | Dirección / Tipo | Ancho | Función |
| :--- | :---: | :---: | :--- |
| `MEMORY_DEPTH` | `parameter` | Entero (`1024`) | Profundidad de cada memoria BRAM en número de palabras. |
| `clk` | `input` | 1 bit | Reloj del sistema (`clk_out1`). |
| `rst` | `input` | 1 bit | Reinicio síncrono activo en alto. |
| `rx_ready` | `input` | 1 bit | Pulso que indica la llegada de un byte desde `uart_basic`. |
| `rx_data` | `input` | `[7:0]` (8 bits) | Byte recibido desde `uart_basic`. |
| `enable` | `output` | 1 bit | Habilita el Puerto A de la BRAM al escribir una palabra completa. |
| `write_enable` | `output` | 1 bit | Habilita la escritura en el Puerto A de la BRAM e incrementa `write_address`. |
| `write_address` | `output` | `[9:0]` (10 bits) | Contador de dirección de escritura en BRAM (0 a 1023). |
| `write_data` | `output` | `[10:0]` (11 bits) | Palabra de 11 bits concatenada `{rx_data[2:0], lsb_reg}`. |
| `rx_bram_sel` | `output` | 1 bit | Registro que almacena cuál BRAM fue seleccionada en el byte de cabecera (`0` = A, `1` = B). |
| `rx_busy` | `output` | 1 bit | Señal de estado hacia `Command_Decoder` que indica recepción de vector en curso. |
| `save_header` | Interna | 1 bit | Orden desde `FSM_RX_ctrl` para capturar `rx_data[0]` en `rx_bram_sel` y reiniciar `write_address`. |
| `save_lsb` | Interna | 1 bit | Orden desde `FSM_RX_ctrl` para guardar el primer byte del elemento en `lsb_reg`. |
| `last_address` | Interna | 1 bit | Bandera comparadora que se activa cuando `write_address == 1023` (`MEMORY_DEPTH - 1`). |
| `lsb_reg` | Registro interno | `[7:0]` (8 bits) | Almacena temporalmente los 8 bits menos significativos (LSB) de cada elemento de 11 bits. |

### 2.2. Módulo `FSM_RX_ctrl` (`FSM_RX_ctrl.sv`)

| Señal | Dirección / Tipo | Ancho | Función |
| :--- | :---: | :---: | :--- |
| `state`, `state_next` | Registros FSM | `state_t` (2 bits) | Estado actual y siguiente de la FSM de recepción (`WAIT_ADDR`, `READ_BYTE_1`, `READ_BYTE_2`, `WRITE_BYTE`). |
| *(Resto de puertos)* | `input` / `output` | — | Conectados 1 a 1 con las señales homónimas de `RX_Logic`. |

---

## 3. Decodificador de Comandos: `Command_Decoder` (`Command_Decoder.sv`)

| Señal | Dirección / Tipo | Ancho | Función |
| :--- | :---: | :---: | :--- |
| `clk` | `input` | 1 bit | Reloj del sistema (`clk_out1`). |
| `rst` | `input` | 1 bit | Reinicio síncrono activo en alto. |
| `rx_ready` | `input` | 1 bit | Pulso de byte recibido desde `uart_basic`. |
| `rx_data` | `input` | `[7:0]` (8 bits) | Byte recibido desde `uart_basic` (códigos de comando `8'd2` a `8'd8`). |
| `rx_busy` | `input` | 1 bit | Bloquea la decodificación mientras `RX_Logic` está cargando un vector en memoria. |
| `start_op` | `output` | 1 bit | Pulso registrado de 1 ciclo que ordena a `Processing_Core` iniciar la operación decodificada. |
| `op_mode` | `output` | `[2:0]` (3 bits) | Modo de operación registrado (`000`: ReadA, `001`: ReadB, `010`: Sum, `011`: Avg, `100`: ManDist, `101`: EucDist, `110`: DotProd). |
| `is_man_dist` | `output` | 1 bit | Bandera combinacional activa cuando `op_mode == 3'b100`. |
| `is_euc_dist` | `output` | 1 bit | Bandera combinacional activa cuando `op_mode == 3'b101`. |
| `is_dot_prod` | `output` | 1 bit | Bandera combinacional activa cuando `op_mode == 3'b110`. |
| `cmd_valid` | Interna | 1 bit | Condición combinacional `rx_ready && !rx_busy && (rx_data >= 8'd2 && rx_data <= 8'd8)`. |

---

## 4. Núcleo de Procesamiento: `Processing_Core` (`Processing_Core.sv`)

| Señal / Parámetro | Dirección / Tipo | Ancho | Función |
| :--- | :---: | :---: | :--- |
| `MEMORY_DEPTH` | `parameter` | Entero (`1024`) | Cantidad de elementos de cada vector almacenado en BRAM. |
| `clk` | `input` | 1 bit | Reloj del sistema (`clk_out1`). |
| `rst` | `input` | 1 bit | Reinicio síncrono activo en alto. |
| `start_op` | `input` | 1 bit | Pulso de inicio de operación proveniente de `Command_Decoder`. |
| `op_mode` | `input` | `[2:0]` (3 bits) | Selector de operación aritmética o de lectura proveniente de `Command_Decoder`. |
| `is_man_dist` | `input` | 1 bit | Indica operación Distancia de Manhattan. |
| `is_euc_dist` | `input` | 1 bit | Indica operación Distancia Euclideana. |
| `is_dot_prod` | `input` | 1 bit | Indica operación Producto Punto. |
| `doutb_A` | `input` | `[10:0]` (11 bits) | Elemento $A_i$ leído desde el Puerto B de `BRAM_A`. |
| `doutb_B` | `input` | `[10:0]` (11 bits) | Elemento $B_i$ leído desde el Puerto B de `BRAM_B`. |
| `tx_word_done` | `input` | 1 bit | Confirmación desde `TX_logic` de que la palabra actual ya fue transmitida por UART. |
| `read_address` | `output` | `[9:0]` (10 bits) | Dirección de lectura (0 a 1023) hacia el Puerto B de `BRAM_A` y `BRAM_B`. |
| `read_enable` | `output` | 1 bit | Habilitación de lectura (`enb`) hacia el Puerto B de `BRAM_A` y `BRAM_B`. |
| `result_data` | `output` | `[31:0]` (32 bits) | Resultado numérico entregado hacia `TX_logic` y `Display_logic` (igual a `data_reg`). |
| `result_valid` | `output` | 1 bit | Pulso de 1 ciclo en el estado `SEND_RESULT` que indica que `result_data` es válido. |
| `is_scalar` | Interna | 1 bit | Activa (`1'b1`) cuando la operación es de reducción escalar (`is_man_dist \|\| is_euc_dist \|\| is_dot_prod`). |
| `sum_vec` | Interna | `[11:0]` (12 bits) | Resultado combinacional de la suma $A_i + B_i$. |
| `avg_vec` | Interna | `[11:0]` (12 bits) | Resultado combinacional del promedio truncado $(A_i + B_i) \gg 1$. |
| `man_dist_vec` | Interna | `[11:0]` (12 bits) | Diferencia absoluta combinacional $|A_i - B_i|$. |
| `euc_dist_vec` | Interna | `[21:0]` (22 bits) | Cuadrado de la diferencia $(A_i - B_i)^2 = \text{man\_dist\_vec}^2$. |
| `dot_prod_vec` | Interna | `[21:0]` (22 bits) | Producto combinacional $A_i \cdot B_i$. |
| `alu_out` | Interna | `[21:0]` (22 bits) | Salida del multiplexor combinacional que selecciona la operación según `op_mode`. |
| `addr_inc` | Interna | 1 bit | Orden de la FSM para incrementar `read_address` en 1. |
| `addr_rst` | Interna | 1 bit | Orden de la FSM (al recibir `start_op`) para reiniciar `read_address` y `data_reg` a cero. |
| `acc_en` | Interna | 1 bit | Orden de la FSM en `WAIT_MEM_2` para acumular `alu_out` dentro de `data_reg`. |
| `last_address` | Interna | 1 bit | Indicador de fin de barrido de memoria (`read_address == 1023`). |
| `cordic_valid` | Interna | 1 bit | Pulso (`s_axis_cartesian_tvalid`) que inyecta la suma de cuadrados `data_reg` al IP `cordic_0`. |
| `cordic_ready` | Interna | 1 bit | Señal (`m_axis_dout_tvalid`) del IP `cordic_0` que indica que la raíz cuadrada está lista. |
| `cordic_dout` | Interna | `[15:0]` (16 bits) | Raíz cuadrada entera calculada por el IP `cordic_0` (`m_axis_dout_tdata`). |
| `save_cordic` | Interna | 1 bit | Orden de la FSM para sobreescribir `data_reg` con `{16'd0, cordic_dout}`. |
| `data_reg` | Registro interno | `[31:0]` (32 bits) | Registro de trabajo que actúa como acumulador en operaciones escalares o registro de salida en vectoriales. |
| `state`, `state_next` | Registros FSM | `state_t` (3 bits) | Estado actual y siguiente de la FSM de procesamiento (`IDLE`, `READ_MEM`, `WAIT_MEM_1`, `WAIT_MEM_2`, `START_CORDIC`, `WAIT_CORDIC`, `SEND_RESULT`, `WAIT_TX_DONE`). |

---

## 5. Interfaz de Salida y Transmisión UART: `TX_logic` y `FSM_TX_ctrl`

### 5.1. Módulo `TX_logic` (`TX_logic.sv`)

| Señal | Dirección / Tipo | Ancho | Función |
| :--- | :---: | :---: | :--- |
| `clk` | `input` | 1 bit | Reloj del sistema (`clk_out1`). |
| `rst` | `input` | 1 bit | Reinicio síncrono activo en alto. |
| `tx_busy` | `input` | 1 bit | Señal de ocupado proveniente de `uart_basic`. |
| `send_word` | `input` | 1 bit | Pulso de disparo desde `Processing_Core` (`result_valid`) para capturar y transmitir `word_data`. |
| `is_man_dist` | `input` | 1 bit | Indica envío de 3 bytes para Distancia de Manhattan. |
| `is_euc_dist` | `input` | 1 bit | Indica envío de 3 bytes para Distancia Euclideana. |
| `is_dot_prod` | `input` | 1 bit | Indica envío de 4 bytes para Producto Punto. |
| `word_data` | `input` | `[31:0]` (32 bits) | Palabra de 32 bits proveniente de `Processing_Core` (`result_data`). |
| `tx_data` | `output` | `[7:0]` (8 bits) | Byte seleccionado enviado hacia `uart_basic`. |
| `tx_start` | `output` | 1 bit | Pulso de inicio de transmisión de 1 byte hacia `uart_basic`. |
| `tx_word_done` | `output` | 1 bit | Pulso de 1 ciclo que notifica a `Processing_Core` el término del envío de la palabra completa. |
| `byte_sel` | Interna | `[1:0]` (2 bits) | Selector del multiplexor de bytes (`0`: bits `[7:0]`, `1`: `[15:8]`, `2`: `[23:16]`, `3`: `[31:24]`). |
| `tx_word_reg` | Registro interno | `[31:0]` (32 bits) | Registro que retiene `word_data` estable mientras se serializan sus bytes por UART. |

### 5.2. Módulo `FSM_TX_ctrl` (`FSM_TX_ctrl.sv`)

| Señal | Dirección / Tipo | Ancho | Función |
| :--- | :---: | :---: | :--- |
| `state`, `state_next` | Registros FSM | `state_t` (4 bits) | Estado actual y siguiente de la serialización de bytes (`IDLE`, `SEND_LSB`, `WAIT_LSB`, `SEND_MSB`, `WAIT_MSB`, `SEND_BYTE_3`, `WAIT_BYTE_3`, `SEND_BYTE_4`, `WAIT_BYTE_4`). |
| *(Resto de puertos)* | `input` / `output` | — | Conectados 1 a 1 con las señales homónimas de `TX_logic`. |

---

## 6. Lógica de Display de 7 Segmentos: `Display_logic`, `bin_deco` y `sevenseg_rom`

### 6.1. Módulo `Display_logic` (`Display_logic.sv`)

| Señal | Dirección / Tipo | Ancho | Función |
| :--- | :---: | :---: | :--- |
| `clk` | `input` | 1 bit | Reloj del sistema (`clk_out1`). |
| `rst` | `input` | 1 bit | Reinicio síncrono activo en alto. |
| `result_valid` | `input` | 1 bit | Pulso desde `Processing_Core` que actualiza el estado y valor del display. |
| `is_man_dist` | `input` | 1 bit | Indica que el resultado corresponde a Distancia de Manhattan. |
| `is_euc_dist` | `input` | 1 bit | Indica que el resultado corresponde a Distancia Euclideana. |
| `is_dot_prod` | `input` | 1 bit | Indica que el resultado corresponde a Producto Punto. |
| `result_data` | `input` | `[31:0]` (32 bits) | Resultado binario de 32 bits a convertir y mostrar en formato decimal. |
| `cathodes` | `output` | `[6:0]` (7 bits) | Segmentos activos en bajo entregados por `sevenseg_rom` hacia los pines de la FPGA. |
| `anodes` | `output` | `[7:0]` (8 bits) | Ánodos activos en bajo entregados hacia los pines de la FPGA (`8'hFF` si `display_en == 0`). |
| `is_scalar` | Interna | 1 bit | Condición `is_man_dist \|\| is_euc_dist \|\| is_dot_prod` que determina si el display debe encenderse. |
| `display_en` | Registro interno | 1 bit | Mantiene encendidos los displays tras una operación escalar y los apaga si se ejecuta una operación vectorial. |
| `converting` | Registro interno | 1 bit | Indica que el algoritmo secuencial *Double-Dabble* está en ejecución (durante 32 ciclos). |
| `bit_cnt` | Registro interno | `[5:0]` (6 bits) | Contador de iteraciones (0 a 31) del desplazador *Double-Dabble*. |
| `bin_shift` | Registro interno | `[31:0]` (32 bits) | Registro de desplazamiento que contiene los bits binarios restantes por desplazar hacia `bcd_work`. |
| `bcd_work` | Registro interno | `[31:0]` (32 bits) | Registro temporal que acumula los 8 dígitos BCD parciales durante la conversión. |
| `bcd_adj` | Interna | `[31:0]` (32 bits) | Valor combinacional de `bcd_work` tras sumar `4'd3` a cada nibble cuyo valor sea $\ge 5$. |
| `bcd_reg` | Registro interno | `[31:0]` (32 bits) | Registro final estable con los 8 dígitos BCD (`bcd_reg[3:0]` = unidades ... `bcd_reg[31:28]` = decenas de millón). |
| `refresh_cnt` | Registro interno | `[19:0]` (20 bits) | Contador libre para generar la base de tiempo de multiplexación TDM de los displays. |
| `anode_sel` | Interna | `[2:0]` (3 bits) | Bits superiores `refresh_cnt[19:17]` que seleccionan cuál de los 8 displays está activo (~1.31 ms por dígito). |
| `anodes_deco` | Interna | `[7:0]` (8 bits) | Salida one-cold del decodificador `bin_deco` antes de aplicar la máscara `display_en`. |
| `current_digit` | Interna | `[3:0]` (4 bits) | Nibble BCD del dígito actualmente seleccionado por `anode_sel` (`4'hF` cuando `display_en == 0`). |

### 6.2. Módulo `bin_deco` (`bin_deco.sv`)

| Señal | Dirección | Ancho | Función |
| :--- | :---: | :---: | :--- |
| `in_deco` | `input` | `[2:0]` (3 bits) | Índice binario del display activo (0 a 7). |
| `out_deco` | `output` | `[7:0]` (8 bits) | Salida decodificada activa en bajo (pone en `0` únicamente el bit indicado por `in_deco`). |

### 6.3. Módulo `sevenseg_rom` (`sevenseg.sv`)

| Señal | Dirección | Ancho | Función |
| :--- | :---: | :---: | :--- |
| `in` | `input` | `[3:0]` (4 bits) | Dígito BCD (0 a 9) a representar; valores 10 a 15 apagan todos los segmentos. |
| `segments` | `output` | `[6:0]` (7 bits) | Patrón de 7 segmentos activo en bajo (`{ca, cb, cc, cd, ce, cf, cg}`). |

---

## 7. Módulos de Comunicación Serial UART

### 7.1. Módulo `uart_basic` (`uart_basic.v`)

| Señal / Parámetro | Dirección / Tipo | Ancho | Función |
| :--- | :---: | :---: | :--- |
| `CLK_FREQUENCY` | `parameter` | Entero (`100000000`) | Frecuencia del reloj de entrada en Hz (100 MHz). |
| `BAUD_RATE` | `parameter` | Entero (`115200`) | Velocidad de transmisión/recepción serial en baudios. |
| `clk`, `reset` | `input` | 1 bit c/u | Reloj del sistema y reinicio síncrono. |
| `rx`, `tx` | `input` / `output` | 1 bit c/u | Líneas físicas seriales de recepción y transmisión. |
| `rx_data` | `output` | `[7:0]` (8 bits) | Byte recibido desde `uart_rx`. |
| `rx_ready` | `output` | 1 bit | Pulso de 1 ciclo de reloj generado por detector de flanco ascendente sobre `rx_ready_pre`. |
| `tx_start` | `input` | 1 bit | Orden de inicio de transmisión hacia `uart_tx`. |
| `tx_data` | `input` | `[7:0]` (8 bits) | Byte a transmitir por `uart_tx`. |
| `tx_busy` | `output` | 1 bit | Indica que `uart_tx` está transmitiendo y habilita el generador `baud_tick_blk`. |
| `baud8_tick` | Interna | 1 bit | Pulso de sobremuestreo ($8 \times \text{BAUD\_RATE}$) para recepción en `uart_rx`. |
| `baud_tick` | Interna | 1 bit | Pulso a frecuencia de baudios ($1 \times \text{BAUD\_RATE}$) para transmisión en `uart_tx`. |
| `rx_ready_pre` | Interna | 1 bit | Señal de dato listo proveniente de `uart_rx` (dura 1 periodo de `baud8_tick`). |
| `rx_ready_sync` | Registro interno | 1 bit | Registro de retardo de 1 ciclo sobre `rx_ready_pre` para conformar el detector de flanco `rx_ready`. |

### 7.2. Módulo `uart_baud_tick_gen` (`uart_baud_tick_gen.v`)

| Señal / Parámetro | Dirección / Tipo | Ancho | Función |
| :--- | :---: | :---: | :--- |
| `OVERSAMPLING` | `parameter` | Entero (`1` u `8`) | Factor de multiplicación sobre `BAUD_RATE`. |
| `clk` | `input` | 1 bit | Reloj del sistema. |
| `enable` | `input` | 1 bit | Habilita el acumulador de fase (`1'b1` permanente en RX, `tx_busy` en TX). |
| `tick` | `output` | 1 bit | Bit de desborde (`acc[ACC_WIDTH]`) que genera un pulso periódico a la tasa deseada. |
| `acc` | Registro interno | `[ACC_WIDTH:0]` | Acumulador de fase que suma la constante `INCREMENT` en cada ciclo de reloj. |

### 7.3. Módulo `uart_rx` (`uart_rx.v`) y `data_sync` (`data_sync.v`)

| Señal | Módulo | Dirección / Tipo | Ancho | Función |
| :--- | :---: | :---: | :---: | :--- |
| `in` | `data_sync` | `input` | 1 bit | Señal asíncrona externa (`rx`). |
| `in_sync_sr` | `data_sync` | Registro interno | `[1:0]` (2 bits) | Doble flip-flop sincronizador para evitar metaestabilidad. |
| `in_sync` | `data_sync` | Interna | 1 bit | Salida sincronizada (`in_sync_sr[0]`). |
| `sync_counter`, `sync_counter_next` | `data_sync` | Registros internos | `[1:0]` (2 bits) | Contador de saturación (0 a 3) para filtrar ruido/pulsos espurios cortos en `rx`. |
| `stable_out`, `stable_out_next` | `data_sync` | `output` / Interna | 1 bit | Línea `rx` filtrada y sincronizada entregada como `rx_bit` a `uart_rx`. |
| `rx_bit` | `uart_rx` | Interna | 1 bit | Señal `rx` limpia proveniente de `data_sync`. |
| `spacing_counter`, `spacing_counter_next` | `uart_rx` | Registros internos | `[2:0]` (3 bits) | Cuenta pulsos `baud8_tick` (0 a 7) para muestrear en el centro de cada bit. |
| `next_bit` | `uart_rx` | Interna | 1 bit | Pulso activo cuando `spacing_counter == 4` (punto medio del bit). |
| `bit_counter`, `bit_counter_next` | `uart_rx` | Registros internos | `[2:0]` (3 bits) | Cuenta los 8 bits de datos recibidos (0 a 7) en el estado `RX_RECV`. |
| `rx_data`, `rx_data_next` | `uart_rx` | `output` / Interna | `[7:0]` (8 bits) | Registro de desplazamiento que ensambla los 8 bits recibidos. |
| `state`, `state_next` | `uart_rx` | Registros FSM | `[2:0]` (3 bits) | Estado de recepción (`RX_IDLE`, `RX_START`, `RX_RECV`, `RX_STOP`, `RX_READY`). |

### 7.4. Módulo `uart_tx` (`uart_tx.v`)

| Señal | Dirección / Tipo | Ancho | Función |
| :--- | :---: | :---: | :--- |
| `tx_data_reg` | Registro interno | `[7:0]` (8 bits) | Captura `tx_data` al recibir `tx_start` en `TX_IDLE`. |
| `counter`, `counter_next` | Registros internos | `[2:0]` (3 bits) | Índice del bit de datos (0 a 7) que se está enviando por la línea `tx`. |
| `state`, `state_next` | Registros FSM | `[1:0]` (2 bits) | Estado del transmisor (`TX_IDLE`, `TX_START`, `TX_SEND`, `TX_STOP`). |

---

## 8. Puertos de los IP Cores de Vivado

### 8.1. IP Clocking Wizard (`clk_wiz_0`)

| Puerto | Dirección | Ancho | Función |
| :--- | :---: | :---: | :--- |
| `clk_in1` | `input` | 1 bit | Reloj de entrada de 100 MHz (`clk`). |
| `reset` | `input` | 1 bit | Reinicio activo en alto (`reset`). |
| `clk_out1` | `output` | 1 bit | Reloj de salida sintetizado de 100 MHz. |
| `locked` | `output` | 1 bit | Indica que el reloj `clk_out1` es estable. |

### 8.2. IP Block Memory Generator (`blk_mem_gen_0` — `BRAM_A` y `BRAM_B`)

| Puerto | Dirección | Ancho | Función |
| :--- | :---: | :---: | :--- |
| `clka`, `clkb` | `input` | 1 bit c/u | Relojes de sincronización para Puerto A y Puerto B (ambos conectados a `clk_out1`). |
| `ena`, `enb` | `input` | 1 bit c/u | Habilitación de operación para Puerto A (escritura) y Puerto B (lectura). |
| `wea`, `web` | `input` | `[0:0]` (1 bit) | Habilitación de escritura para Puerto A (`wea_A`/`B`) y Puerto B (`1'b0`). |
| `addra`, `addrb` | `input` | `[9:0]` (10 bits) | Direcciones de acceso (0 a 1023) para Puerto A y Puerto B. |
| `dina`, `dinb` | `input` | `[10:0]` (11 bits) | Datos de entrada para escritura en Puerto A (`dina`) y Puerto B (`11'd0`). |
| `douta`, `doutb` | `output` | `[10:0]` (11 bits) | Datos de salida leídos desde Puerto A y Puerto B (`doutb_A`, `doutb_B`). |

### 8.3. IP CORDIC Square Root (`cordic_0`)

| Puerto | Dirección | Ancho | Función |
| :--- | :---: | :---: | :--- |
| `aclk` | `input` | 1 bit | Reloj de operación AXI-Stream (`clk_out1`). |
| `s_axis_cartesian_tvalid` | `input` | 1 bit | Indica que el radicando en `s_axis_cartesian_tdata` es válido (`cordic_valid`). |
| `s_axis_cartesian_tdata` | `input` | `[31:0]` (32 bits) | Radicando entero sin signo ($\sum (A_i - B_i)^2$ almacenado en `data_reg`). |
| `m_axis_dout_tvalid` | `output` | 1 bit | Indica que el resultado de la raíz cuadrada es válido (`cordic_ready`). |
| `m_axis_dout_tdata` | `output` | `[15:0]` (16 bits) | Raíz cuadrada entera truncada $\lfloor\sqrt{\sum (A_i - B_i)^2}\rfloor$ (`cordic_dout`). |
