.data

cls:
	.asciz "\x1b[H\x1b[2J"
	lencls = . - cls

mapa1:
	.ascii "#######"
	.ascii "#  .  #"
	.ascii "#  $  #"
	.ascii "#  @  #"
	.asciz "#######"

.align 2
mapa1_filas: .word 5
mapa1_columnas: .word 7

mapa2:
	.ascii "########"
	.ascii "#  #   #"
	.ascii "# $ .  #"
	.ascii "#  @ $ #"
	.ascii "#   .  #"
	.asciz "########"

.align 2
mapa2_filas: .word 6
mapa2_columnas: .word 8

mapa3:
	.ascii "##########"
	.ascii "#   ..   #"
	.ascii "#  $$$$  #"
	.ascii "#   @    #"
	.ascii "#   ..   #"
	.asciz "##########"

.align 2
mapa3_filas: .word 6
mapa3_columnas: .word 10

matriz_activa: .space 100
filas_activas: .word 0
columnas_activas: .word 0

msg_menu: .asciz "Elija un mapa para practicar(1, 2 o 3): "
len_menu = . - msg_menu
buffer_entrada: .space 2
buffer_numero:  .space 3


@necesarios para cargar y mostrar mapa:

texto_movs: .asciz "\nMovimientos: "
cambio_linea: .asciz "\n"
buffer: .space 2

@necesario para los movimientos:
msg_pedir_mov: .asciz "\nMovimiento (W/A/S/D, R reinicia, Q sale): "
len_pedir_mov = . - msg_pedir_mov
buffer_mov: .space 2

.align 2
elemento_bajo_personaje: .byte ' '

msg_victoria: .asciz "\n¡Victoria! Has completado el mapa.\n"
len_victoria = . - msg_victoria

@se guarda el mapa actual para reiniciarlo con R
mapa_actual: .word 1

@si se activa, no se vuelve a limpiar la pantalla antes de pedir otro movimiento
saltar_redibujar: .word 0

msg_fail: .asciz "\n - Failed! Movimiento no permitido."
len_fail = . - msg_fail

.text
.global main

main:
menu_juego:

    mov r0, #1
    ldr r1, =msg_menu
    ldr r2, =len_menu
    mov r7, #4
    swi 0


    mov r0, #0
    ldr r1, =buffer_entrada
    mov r2, #2
    mov r7, #3
    swi 0

    ldr r1, =buffer_entrada
    ldrb r2, [r1]

    cmp r2, #'1'
    beq cargar_mapa1
    cmp r2, #'2'
    beq cargar_mapa2
    cmp r2, #'3'
    beq cargar_mapa3
    b menu_juego

cargar_mapa1:
    ldr r0, =mapa1
    ldr r1, =mapa1_filas
    ldr r2, =mapa1_columnas
    mov r3, #1
    ldr r4, =mapa_actual
    str r3, [r4]
    b preparar_carga

cargar_mapa2:
    ldr r0, =mapa2
    ldr r1, =mapa2_filas
    ldr r2, =mapa2_columnas
    mov r3, #2
    ldr r4, =mapa_actual
    str r3, [r4]
    b preparar_carga

cargar_mapa3:
    ldr r0, =mapa3
    ldr r1, =mapa3_filas
    ldr r2, =mapa3_columnas
    mov r3, #3
    ldr r4, =mapa_actual
    str r3, [r4]
    b preparar_carga

preparar_carga:
    ldr r1, [r1]
    ldr r3, =filas_activas
    str r1, [r3]
    ldr r2, [r2]
    ldr r3, =columnas_activas
    str r2, [r3]


    bl cargar_mapa
    mov r4, r0
    mov r5, #0

bucle_juego:

    ldr r0, =saltar_redibujar
    ldr r1, [r0]
    cmp r1, #1
    beq omitir_limpieza

    ldr r0, =matriz_activa
    mov r1, r5
    bl mostrar_mapa

    b continuar_bucle

omitir_limpieza:
    mov r1, #0
    ldr r0, =saltar_redibujar
    str r1, [r0]

continuar_bucle:

    bl pedir_movimiento
    mov r6, r0


    cmp r6, #'q'
    beq salir_programa
    cmp r6, #'Q'
    beq salir_programa

    cmp r6, #'r'
    beq reiniciar_mapa
    cmp r6, #'R'
    beq reiniciar_mapa


    mov r0, r4
    mov r1, r6
    bl obtener_posicion_siguiente
    mov r7, r0

    mov r0, r4
    mov r1, r6
    bl movimiento_posible
    cmp r0, #0
    beq mostrar_fail

    mov r0, r7
    mov r1, r4
    mov r2, r6
    bl verificar_y_mover

    cmp r0, #1
    addeq r5, r5, #1
    moveq r4, r7

    cmp r0, #1
    beq comprobar_puntos_mapa

    b mostrar_fail

mostrar_fail:
    ldr r0, =matriz_activa
    mov r1, r5
    bl mostrar_mapa

    mov r0, #1
    ldr r1, =msg_fail
    ldr r2, =len_fail
    mov r7, #4
    swi 0

    b continuar_bucle

reiniciar_mapa:
    ldr r4, =mapa_actual
    ldr r3, [r4]
    cmp r3, #1
    beq cargar_mapa1
    cmp r3, #2
    beq cargar_mapa2
    cmp r3, #3
    beq cargar_mapa3
    b menu_juego

comprobar_puntos_mapa:
    ldr r0, =matriz_activa
    bl hay_puntos_en_mapa
    cmp r0, #0
    beq mostrar_victoria
    b bucle_juego

mostrar_victoria:
    mov r0, #1
    ldr r1, =cls
    ldr r2, =lencls
    mov r7, #4
    swi 0

    mov r0, #1
    ldr r1, =msg_victoria
    ldr r2, =len_victoria
    mov r7, #4
    swi 0

    b menu_juego

salir_programa:
    mov r0, #0
    mov r7, #1
    swi 0

@SUBRUTINAS

hay_puntos_en_mapa:
    push {r4, r5, r6, lr}

    mov r4, r0
    mov r5, #0
    mov r6, #0

mientras_hay_puntos:
    ldrb r1, [r4, r5]
    cmp r1, #0
    beq fin_hay_puntos
    cmp r1, #'.'
    addeq r6, r6, #1
    add r5, r5, #1
    b mientras_hay_puntos

fin_hay_puntos:
    mov r0, r6
    pop {r4, r5, r6, pc}

cargar_mapa:

	push {r4, r5, r6, r7, r8, lr}

	ldr r8, =elemento_bajo_personaje
  	mov r3, #' '
   	strb r3, [r8]


	mov r1, #0
	mov r4, #0
	ldr r3, =matriz_activa

mientras_cargar:
	ldrb r2, [r0,r1]
	cmp r2, #0
	beq fin_cargar
	strb r2, [r3,r1]

	cmp r2, #'@'
	beq guardar_posicion
	cmp r2, #'+'
	beq guardar_posicion_mas
        b continuar_mientras

guardar_posicion_mas:
        mov r4, r1
        mov r2, #'.'
        strb r2, [r8]
        b continuar_mientras

guardar_posicion:
	mov r4, r1

continuar_mientras:
	add r1,r1, #1
	b mientras_cargar

fin_cargar:
	mov r0, r4
	pop {r4, r5, r6, r7, r8, pc}

mostrar_mapa:
	push {r4, r5, r6, r7, r8, lr}


	mov r4, r0
	mov r5, r1

@limpiar la pantalla
	mov r0, #1
	ldr r1, =cls
	ldr r2, =lencls
	mov r7, #4
	swi 0

	mov r1, #0
	ldr r6, =columnas_activas
	ldr r6, [r6]
	mov r8, #0

mientras_mostrar:
	ldrb r2, [r4,r1]
	cmp r2, #0
	beq fin_mientras_mostrar

	ldr r3, =buffer
	strb r2,[r3]
	push {r0,r1,r2,r7}
	mov r0, #1
	mov r1, r3
	mov r2, #1
	mov r7, #4
	swi 0
	pop {r0,r1,r2,r7}

	add r8,r8,#1
	cmp r8,r6
	bne cambiar_linea
	push {r0,r1,r2,r7}
	mov r0, #1
	ldr r1, = cambio_linea
	mov r2, #1
	mov r7, #4
	swi 0
	pop {r0,r1,r2,r7}
	mov r8, #0

cambiar_linea:
	add r1,r1,#1
	b mientras_mostrar

fin_mientras_mostrar:
	mov r0, #1
	ldr r1, =texto_movs
	mov r2, #14
	mov r7, #4
	swi 0

	mov r0, r5
	bl pasar_numero_a_ascii
	mov r2, r1
	mov r1, r0
	mov r0, #1
	mov r7, #4
	swi 0

	pop {r4, r5, r6, r7, r8, pc}


pasar_numero_a_ascii:
    push {r4, lr}
    mov r1, #0

if_decenas:
    cmp r0, #10
    blt fin_decenas
    sub r0, r0, #10
    add r1, r1, #1
    b if_decenas

fin_decenas:
    add r1, r1, #48         @convertir decenas a ascii
    add r0, r0, #48         @convertir unidades a ascii

    ldr r2, =buffer_numero
    strb r1, [r2]           @guardo la decena
    strb r0, [r2, #1]       @guardo la unidad
    mov r3, #0
    strb r3, [r2, #2]

    mov r0, r2
    mov r1, #2
    pop {r4, pc}




pedir_movimiento:

    push {r4, lr}

mientras_pedir_mov:

    mov r0, #1
    ldr r1, =msg_pedir_mov
    ldr r2, =len_pedir_mov
    mov r7, #4
    swi 0

    mov r0, #0
    ldr r1, =buffer_mov
    mov r2, #2
    mov r7, #3
    swi 0

    ldr r1, =buffer_mov
    ldrb r0, [r1]

    cmp r0, #'w'
    beq mov_valido
    cmp r0, #'W'
    beq mov_valido

    cmp r0, #'a'
    beq mov_valido
    cmp r0, #'A'
    beq mov_valido

    cmp r0, #'s'
    beq mov_valido
    cmp r0, #'S'
    beq mov_valido

    cmp r0, #'d'
    beq mov_valido
    cmp r0, #'D'
    beq mov_valido

    cmp r0, #'r'
    beq mov_valido
    cmp r0, #'R'
    beq mov_valido

    cmp r0, #'q'
    beq mov_valido
    cmp r0, #'Q'
    beq mov_valido

    b mientras_pedir_mov

mov_valido:
    pop {r4, pc}


obtener_posicion_siguiente:

    push {r4, r5, lr}

    mov r4, r0
    ldr r5, =columnas_activas
    ldr r5, [r5]


    cmp r1, #'w'
    beq mov_arriba
    cmp r1, #'W'
    beq mov_arriba

    cmp r1, #'s'
    beq mov_abajo
    cmp r1, #'S'
    beq mov_abajo

    cmp r1, #'a'
    beq mov_izquierda
    cmp r1, #'A'
    beq mov_izquierda

    cmp r1, #'d'
    beq mov_derecha
    cmp r1, #'D'
    beq mov_derecha

    @ Si fue R o Q no mueve la posicion
    mov r0, r4
    b fin_obtener_pos

mov_arriba:
    sub r0, r4, r5
    b fin_obtener_pos

mov_abajo:
    add r0, r4, r5
    b fin_obtener_pos

mov_izquierda:
    sub r0, r4, #1
    b fin_obtener_pos

mov_derecha:
    add r0, r4, #1

fin_obtener_pos:
    pop {r4, r5, pc}

verificar_y_mover:

    push {r4, r5, r6, r7, r8, r9, lr}

    mov r4, r0
    mov r5, r1
    mov r6, r2

    mov r8, #0
    ldr r9, =matriz_activa


    ldrb r7, [r9, r4]
 
    cmp r7, #'#'
    beq fin_verificar_y_mover


    cmp r7, #' '
    beq mover_piso_o_meta
    cmp r7, #'.'
    beq mover_piso_o_meta


    cmp r7, #'$'
    beq mover_caja
    cmp r7, #'*'
    beq mover_caja

    b fin_verificar_y_mover

mover_piso_o_meta:

    ldr r0, =elemento_bajo_personaje
    ldrb r1, [r0]
    strb r1, [r9, r5]


    strb r7, [r0]


    cmp r7, #'.'
    moveq r1, #'+'
    movne r1, #'@'
    strb r1, [r9, r4]

    mov r8, #1
    b fin_verificar_y_mover

mover_caja:

    mov r0, r4
    mov r1, r6
    bl obtener_posicion_siguiente
    mov r3, r0


    ldrb r1, [r9, r3]


    cmp r1, #' '
    beq empujar_caja_valido
    cmp r1, #'.'
    beq empujar_caja_valido

    b fin_verificar_y_mover

empujar_caja_valido:

    cmp r1, #'.'
    moveq r2, #'*'
    movne r2, #'$'
    strb r2, [r9, r3]


    ldr r0, =elemento_bajo_personaje
    ldrb r2, [r0]
    strb r2, [r9, r5]


    cmp r7, #'*'
    beq es_caja_en_meta


    mov r2, #' '
    strb r2, [r0]
    mov r2, #'@'
    strb r2, [r9, r4]
    b continuar_empuje

es_caja_en_meta:

    mov r2, #'.'
    strb r2, [r0]
    mov r2, #'+'
    strb r2, [r9, r4]

continuar_empuje:
    mov r8, #1

fin_verificar_y_mover:
    mov r0, r8
    pop {r4, r5, r6, r7, r8, r9, pc}

movimiento_posible:

    push {r4, r5, r6, r7, r8, r9, lr}

    mov r4, r0
    mov r5, r1
    ldr r6, =columnas_activas
    ldr r6, [r6]
    ldr r7, =filas_activas
    ldr r7, [r7]


    mov r8, r4
    mov r9, #0

calcular_fila:
    cmp r8, r6
    blt calcular_columna
    sub r8, r8, r6
    add r9, r9, #1
    b calcular_fila

calcular_columna:
    @ r8 = columna actual

    cmp r5, #'w'
    beq validar_arriba
    cmp r5, #'W'
    beq validar_arriba

    cmp r5, #'s'
    beq validar_abajo
    cmp r5, #'S'
    beq validar_abajo

    cmp r5, #'a'
    beq validar_izquierda
    cmp r5, #'A'
    beq validar_izquierda

    cmp r5, #'d'
    beq validar_derecha
    cmp r5, #'D'
    beq validar_derecha

    mov r0, #1
    b fin_movimiento_posible

validar_arriba:
    cmp r9, #0
    beq movimiento_imposible
    b movimiento_posible_ok

validar_abajo:
    sub r0, r7, #1
    cmp r9, r0
    beq movimiento_imposible
    b movimiento_posible_ok

validar_izquierda:
    cmp r8, #0
    beq movimiento_imposible
    b movimiento_posible_ok

validar_derecha:
    sub r0, r6, #1
    cmp r8, r0
    beq movimiento_imposible
    b movimiento_posible_ok

movimiento_posible_ok:
    mov r0, #1
    b fin_movimiento_posible

movimiento_imposible:
    mov r0, #0

fin_movimiento_posible:
    pop {r4, r5, r6, r7, r8, r9, pc}

