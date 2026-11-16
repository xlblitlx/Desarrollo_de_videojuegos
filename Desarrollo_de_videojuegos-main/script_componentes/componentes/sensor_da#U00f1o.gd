class_name SensorDano
extends Node

signal evento(posicion: Vector3)

func _enter_tree() -> void:
	add_to_group("disparadores")

func procesar_prueba_dano(posicion_actual: Vector3) -> void:
	if Input.is_key_pressed(KEY_T):
		evento.emit(posicion_actual)
