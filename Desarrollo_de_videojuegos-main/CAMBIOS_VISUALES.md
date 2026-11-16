# Cambios visuales (la jugabilidad no se tocó)

Nuevos: scripts en `script_componentes/entidades/modelo_nave.gd`, `entorno/modelo_planeta.gd`,
`entorno/fondo_espacial.gd`, `utilidades/util_modelos.gd`; modelos en `assets/modelos/` y `assets/fondos/step_2.jpg`.
Editados (solo visual): `Demo_Orbital.tscn`, `escenas/jugador.tscn`, `escenas/Enemigo.tscn`, `escenas/planeta.tscn`, `project.godot` (color de fondo).

Si algo se ve raro:
- Nave de espaldas: en `jugador.tscn` / `Enemigo.tscn`, nodo `ModeloNave` -> `giro_y` = 0 (o 90 / -90).
- Fondo muy borroso: en `Demo_Orbital` nodo `FondoEspacial` desmarca `usar_panorama`.
- Planetas de un solo color: faltan las texturas PNG de ToyPlanets; ponlas junto al .fbx.
