extends SceneTree
## Pruebas de recursos, componentes y formulas sin modificar la demo.


func _initialize() -> void:
    call_deferred("_probar")


func _probar() -> void:
    var errores := 0
    var rutas := [
        "res://parteBrian/proyectil/proyectil.tscn",
        "res://parteBrian/orbe/orbe.tscn",
        "res://parteBrian/disparo/control_disparo.tscn",
        "res://parteBrian/pruebas/enemigo_prueba.tscn",
        "res://parteBrian/demo_combate_alba.tscn"
    ]

    for ruta in rutas:
        var recurso := load(ruta) as PackedScene
        if recurso == null:
            push_error("No cargo: " + ruta)
            errores += 1

    for nivel in range(2, 8):
        var valores := {2: 50, 3: 110, 4: 180, 5: 260, 6: 350, 7: 450}
        if GestorExperiencia.umbral_nivel(nivel) != valores[nivel]:
            errores += 1
            push_error("Umbral EXP incorrecto en nivel %d" % nivel)

    var escena_proyectil := load(rutas[0]) as PackedScene
    if escena_proyectil != null:
        var proyectil := escena_proyectil.instantiate() as Proyectil
        if proyectil == null or not proyectil.has_method("configurar"):
            errores += 1
        if proyectil != null:
            proyectil.free()

    var escena_orbe := load(rutas[1]) as PackedScene
    if escena_orbe != null:
        var orbe := escena_orbe.instantiate() as Orbe
        if orbe == null or not orbe.has_signal("orbe_recogido"):
            errores += 1
        if orbe != null:
            orbe.free()

    print("PRUEBAS COMBATE: %d error(es)" % errores)
    quit(0 if errores == 0 else 1)
