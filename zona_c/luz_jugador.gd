class_name LuzJugador
extends OmniLight3D
## Luz de la nave y prueba de EXP de la zona C.
## Es hija del Jugador para moverse con él.

signal subio_nivel(nivel: int)

@export var rango := 3.0
@export var altura := 0.85
@export var energia_base := 1.1
@export var luz_aura: OmniLight3D
@export var luz_principal: DirectionalLight3D
@export var texto_estado: Label

var experiencia_total := 0
var nivel_actual := 1
var destello := 0.0
var modo_sombras := "Solo estrella"
var modo_bias := "Bias 3 / Normal 6"


func _ready() -> void:
    position = Vector3(0.0, altura, 0.0)
    light_color = Color("#38B6FF")
    light_energy = energia_base
    omni_range = rango
    omni_attenuation = 2.0
    shadow_enabled = false
    if luz_aura != null:
        luz_aura.light_color = Color("#FFCB50")
        luz_aura.shadow_enabled = false
    if luz_principal != null:
        luz_principal.shadow_enabled = true
        luz_principal.shadow_bias = 3.0
        luz_principal.shadow_normal_bias = 6.0
    print("Atenuacion 1, 2, 4 m: ", atenuacion(1.0), " / ", atenuacion(2.0), " / ", atenuacion(4.0))
    var n := Vector3(0, 1, 0)
    var l := Vector3(0, 1, 1)
    print("Blinn-Phong caso 1: ", blinn_phong(n, l, Vector3(0, 1, -1), 32.0))
    print("Blinn-Phong caso 2: ", blinn_phong(n, l, Vector3(0, 1, 0), 32.0))
    actualizar_texto()


func _process(delta: float) -> void:
    destello = maxf(0.0, destello - delta)
    light_energy = energia_base + destello * 1.5
    if luz_aura != null:
        luz_aura.light_energy = lerpf(0.35, 1.9, progreso_exp()) + destello * 2.0
    actualizar_texto()


func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey:
        return
    var tecla := event as InputEventKey
    if not tecla.pressed or tecla.echo:
        return
    match tecla.keycode:
        KEY_E:
            sumar_experiencia(10)  # Para probar: en el juego cada nucleo suma 1.
        KEY_1:
            cambiar_sombras(true, true, true)
            modo_sombras = "Tres luces"
        KEY_2:
            cambiar_sombras(true, false, false)
            modo_sombras = "Solo estrella"
        KEY_3:
            cambiar_sombras(false, false, false)
            modo_sombras = "Sin sombras"
        KEY_4:
            cambiar_bias(0.0, 0.0)
            modo_bias = "Bias 0 / Normal 0"
        KEY_5:
            cambiar_bias(3.0, 6.0)
            modo_bias = "Bias 3 / Normal 6"
        KEY_6:
            cambiar_bias(20.0, 6.0)
            modo_bias = "Bias 20 / Normal 6"
    actualizar_texto()


func cambiar_sombras(sol: bool, aura: bool, nave: bool) -> void:
    if luz_principal != null:
        luz_principal.shadow_enabled = sol
    if luz_aura != null:
        luz_aura.shadow_enabled = aura
    shadow_enabled = nave


func cambiar_bias(bias: float, normal_bias: float) -> void:
    if luz_principal != null:
        luz_principal.shadow_bias = bias
        luz_principal.shadow_normal_bias = normal_bias


func sumar_experiencia(cantidad: int) -> void:
    if cantidad <= 0:
        return
    experiencia_total += cantidad
    while experiencia_total >= umbral_nivel(nivel_actual + 1):
        nivel_actual += 1
        destello = 0.5
        subio_nivel.emit(nivel_actual)
        print("Calibracion: nivel ", nivel_actual)
    actualizar_texto()


func progreso_exp() -> float:
    var inicio := umbral_nivel(nivel_actual)
    var siguiente := umbral_nivel(nivel_actual + 1)
    return clampf(float(experiencia_total - inicio) / float(siguiente - inicio), 0.0, 1.0)


static func umbral_nivel(nivel: int) -> int:
    if nivel <= 1:
        return 0
    if nivel == 2:
        return 50
    if nivel == 3:
        return 110
    if nivel == 4:
        return 180
    var extra := nivel - 4
    return 180 + 80 * extra + 5 * extra * (extra - 1)


static func atenuacion(distancia: float, exponente: float = 2.0) -> float:
    return 1.0 / pow(maxf(distancia, 0.0001), exponente)


static func blinn_phong(normal: Vector3, hacia_luz: Vector3,
        hacia_ojo: Vector3, brillo: float) -> float:
    var n := normal.normalized()
    var l := hacia_luz.normalized()
    var v := hacia_ojo.normalized()
    var h := (l + v).normalized()
    return pow(maxf(0.0, n.dot(h)), brillo)


func actualizar_texto() -> void:
    if texto_estado == null:
        return
    var siguiente := umbral_nivel(nivel_actual + 1)
    texto_estado.text = "ZONA C  |  ORBITAL ATTACK\nNivel %d  -  EXP: %d / %d  -  Aura: %d%%\n" % [nivel_actual, experiencia_total, siguiente, int(progreso_exp() * 100.0)]
    texto_estado.text += "WASD: mover  |  E: +10 EXP de prueba\n"
    texto_estado.text += "1: tres sombras  |  2: sol  |  3: ninguna\n"
    texto_estado.text += "4: Bias 0  |  5: Bias 3/6  |  6: Bias 20\n"
    texto_estado.text += "Estado: %s  -  %s" % [modo_sombras, modo_bias]
