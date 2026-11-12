extends SceneTree
## Verificaciones numericas de la zona C. Se ejecuta desde la terminal.

func _initialize() -> void:
    var errores := 0

    var valores := {2: 50, 3: 110, 4: 180, 5: 260, 6: 350, 7: 450}
    for nivel in valores:
        var esperado: int = valores[nivel]
        var real := LuzJugador.umbral_nivel(nivel)
        if real != esperado:
            push_error("EXP nivel %d: esperaba %d, obtuvo %d" % [nivel, esperado, real])
            errores += 1

    if absf(LuzJugador.atenuacion(1.0) - 1.0) > 0.0001:
        push_error("Fallo atenuacion a 1 m")
        errores += 1
    if absf(LuzJugador.atenuacion(2.0) - 0.25) > 0.0001:
        push_error("Fallo atenuacion a 2 m")
        errores += 1
    if absf(LuzJugador.atenuacion(4.0) - 0.0625) > 0.0001:
        push_error("Fallo atenuacion teorica a 4 m")
        errores += 1

    var escena := load("res://zona_c.tscn") as PackedScene
    if escena == null:
        push_error("No se pudo cargar zona_c.tscn")
        errores += 1
    else:
        var zona := escena.instantiate()
        if not zona.has_node("Jugador/LuzJugador"):
            push_error("Falta Jugador/LuzJugador")
            errores += 1
        if not zona.has_node("Jugador/LuzAura"):
            push_error("Falta Jugador/LuzAura")
            errores += 1
        if not zona.has_node("Sol"):
            push_error("Falta la luz Sol")
            errores += 1
        if not zona.has_node("EsferaBrillo"):
            push_error("Falta EsferaBrillo")
            errores += 1
        zona.free()

    if errores == 0:
        print("OK: formulas y nodos basicos de la Zona C.")
    else:
        push_error("Pruebas con %d error(es)." % errores)
    quit(1 if errores > 0 else 0)
