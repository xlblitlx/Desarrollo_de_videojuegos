class_name BusEventos
extends Node
## Bus central de eventos del juego. Desacopla sistemas, HUD, audio y VFX.

# Eventos orbitales y de nave
signal orbita_entrada(planeta: Node3D)
signal orbita_rota(posicion: Vector3)
signal planeta_agotado(planeta: Node3D)

# Eventos espaciales dinámicos
signal evento_iniciado(id_evento: String, titulo: String, objetivo: Node3D, duracion: float)
signal evento_progreso(texto_estado: String, porcentaje: float)
signal evento_finalizado(id_evento: String, exito: bool)

# Progresión global (listo para Fase 2 y Fase 4)
signal oleada_cambiada(numero_oleada: int)
signal jugador_destruido(tiempo_partida: float)
signal tiempo_supervivencia_actualizado(segundos_totales: float, nivel_intensidad: int)


func _enter_tree() -> void:
	add_to_group("eventos_juego")
