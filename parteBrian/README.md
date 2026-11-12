# Orbital Attack — Modulo de combate y recompensas (Alba)

Cada sistema tiene su carpeta y sus scripts correspondientes:

- `proyectil/`: escena y script del proyectil.
- `orbe/`: escena y script del orbe recolectable.
- `disparo/`: disparo automatico y seleccion del enemigo mas cercano.
- `recompensas/`: genera los orbes al recibir la senal `destruido`.
- `experiencia/`: acumula EXP y actualiza el nivel.
- `pruebas/`: enemigo y generador temporales, HUD de demostracion, registro del jugador y prueba de formulas.
- `demo_combate_alba.tscn`: escena independiente para probar la integracion.

## Integracion

Copia la carpeta `parteBrian` en la **raiz del proyecto** (donde esta `project.godot`).
En Godot abre `res://parteBrian/demo_combate_alba.tscn` y pulsa F6.
No reemplaces `Demo_Orbital.tscn`, `project.godot` ni las carpetas de tus companeros.

La escena de prueba usa `Demo_Orbital.tscn` y su jugador, asi que requiere el resto del repositorio.
Todavia hay que verificar visualmente la escena en Godot: aqui solo se validaron rutas y archivos.
