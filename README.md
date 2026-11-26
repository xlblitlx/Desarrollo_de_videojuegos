# Orbital Attack

Roguelite 3D de supervivencia espacial y gestión de energía desarrollado en **Godot 4**.

![Godot Engine](https://img.shields.io/badge/Godot_Engine-4.x-478CBF?style=flat-square&logo=godotengine&logoColor=white)
![Estado](https://img.shields.io/badge/Estado-Demo_Jugable-00B4D8?style=flat-square)
![Licencia](https://img.shields.io/badge/Licencia-MIT-2EA043?style=flat-square)

---

## Descripción

En **Orbital Attack** pilotas una nave a través de un sistema estelar abierto donde el vacío consume soporte vital y los planetas funcionan como baterías finitas. Para aguantar el avance de las oleadas debes administrar el propulsor, saltar de órbita en órbita antes de agotar cada planeta, aprovechar cinturones de asteroides como cobertura y sobrevivir al encuentro contra el **Acorazado Leviatán**.

---

## Sistemas Implementados

- **Constelación Procedural 3D (`GeneradorMapa`):** Distribuye planetas y rutas intermedias calculando distancias borde a borde para evitar solapamientos orbitales y garantizar que cada salto sea alcanzable según la capacidad del propulsor.
- **Planetas con Reserva Finita y Biomas Procedurales (`Planeta` / `ReservaOrbital`):** Cúpulas orbitales con enfriamiento de regeneración e indicadores de estado en tiempo real (cian, ámbar y rojo al agotarse). Los modelos planetarios generan texturas, relieves y atmósferas procedurales mediante `FastNoiseLite` y degradados por bioma.
- **Cinturones de Asteroides (`CampoAsteroides` / `Asteroide`):** Nubes orbitales con deriva lenta que sirven de cobertura física frente a perseguidores, permiten cosecha de energía por proximidad y sueltan cápsulas de recursos.
- **Escalado de Oleadas y Jefe Orbital (`GestorOleadas` / `JefeOrbital`):** La dificultad escala por tiempo acelerando los spawns y desplegando escuadrones de refuerzo. Al llegar al minuto `2:30` aparece el **Acorazado Leviatán**, un jefe de dos fases con ataques aleatorios (abanico de plasma, ráfaga predictiva, anillo 360° y embestida física con propulsión).
- **HUD y Radar 3D (`RadarPlanetas`):** Proyección direccional en pantalla que muestra la posición y el nivel de carga de cada planeta en tiempo real.
- **Arquitectura Modular:** Comunicación desacoplada mediante un bus global de señales (`EventosJuego`) y composición por nodos.

---

## Guía del Entorno

### Tipos de Planetas

| Tipo | Órbita | Efecto Principal | Comportamiento |
| :--- | :--- | :--- | :--- |
| **Estándar** | Cian | Recarga propulsor (`1.0x`) | Reserva equilibrada y gravedad media. |
| **Energético** | Ámbar | Recarga rápida (`1.8x`) | Reserva compacta y baja gravedad para escapes rápidos. |
| **Biológico / Denso** | Verde | Repara casco (`+2.5 HP/s`) | Alta reserva y fuerte atracción gravitacional. |

### Variantes de Asteroides

| Variante | Color | Interacción |
| :--- | :--- | :--- |
| **Común** | Gris | Cobertura física; `30%` de probabilidad de soltar reparación de casco (`+15 HP`). |
| **Volátil** | Rojo / Naranja | Explota en área al destruirse, dañando y empujando enemigos cercanos. |
| **Energético** | Cian | Recarga propulsor al pasar cerca y suelta celdas de energía (`+30`). |
| **Mineral** | Dorado | Mayor resistencia; libera 3 orbes de experiencia al romperse. |

---

## Controles

| Acción | Tecla / Entrada |
| :--- | :--- |
| **Movimiento** | `W A S D` / Flechas |
| **Propulsor Interplanetario** | `Espacio` |
| **Apuntado / Cámara** | Ratón |
| **Disparo** | Clic Izquierdo |

---

## Arquitectura e Integración

Para conectar nuevos módulos sin tocar el núcleo existente:

- **Grupos de escena:** `"jugador"`, `"enemigos"` (implementan `recibir_dano(cantidad)`), `"jefe"`, `"planetas"`.
- **Señales principales (`EventosJuego`):**
  - `tiempo_supervivencia_actualizado(segundos_totales, nivel_intensidad)`
  - `oleada_cambiada(nuevo_nivel)`
  - `planeta_agotado(planeta)`
  - `enemigo_eliminado(posicion)`
  - `partida_terminada(estadisticas)`

---

## Equipo (OA Studios)

| Integrante | Rol | Áreas principales |
| :--- | :--- | :--- |
| **Isaac Mosquera** | Lead Architect / Dev | Propulsión, Generación Procedural 3D, Planetas, Asteroides, Oleadas, Jefe Orbital y HUD |
| **Diego Vela** | Gameplay Dev | Spawning de Enemigos, IA de Persecución 3D y Game Over |
| **Alba Celis** | Mechanics Dev | Sistema de Disparo, Colisiones, Variantes Enemigas y Experiencia |
| **César Martínez** | Audio & 3D Artist | Modelado 3D, Texturizado, VFX y Audio (SFX/BGM) |

---

## Instalación y Ejecución

Requiere **Godot Engine 4.x** (renderizador *Compatibility* o *Forward+*).

```bash
git clone [https://github.com/TU_USUARIO/orbital-attack.git](https://github.com/TU_USUARIO/orbital-attack.git)
