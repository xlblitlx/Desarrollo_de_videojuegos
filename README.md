# 🚀 Orbital Attack

**Un videojuego 3D Roguelite de supervivencia orbital, gestión de energía y combate interplanetario.**

![Godot Engine](https://img.shields.io/badge/Godot_Engine-v4.x-blue?style=for-the-badge&logo=godotengine&logoColor=white)
![Status](https://img.shields.io/badge/Estado-Vertical_Slice_(Demo)-00E5FF?style=for-the-badge)
![Architecture](https://img.shields.io/badge/Arquitectura-Event--Driven_&_SRP-purple?style=for-the-badge)
![License](https://img.shields.io/badge/Licencia-MIT-green?style=for-the-badge)

---

## 🌌 Acerca del Proyecto

**Orbital Attack** es una experiencia de acción espacial en **Godot 4** que combina generación procedural tridimensional, físicas de contención gravitacional y toma de decisiones tácticas bajo presión creciente.

El jugador pilota una nave en un sistema estelar abierto donde el vacío consume soporte vital y los planetas funcionan como **baterías finitas**. Para sobrevivir a las oleadas enemigas cada vez más agresivas, debes administrar el combustible del propulsor, saltar entre órbitas antes de que se agoten y aprovechar cinturones de asteroides interactivos en tus rutas de vuelo.

---

## ✨ Características Principales

* 🌌 **Constelación Procedural en 3D (`GeneradorMapa`):** Distribución volumétrica de planetas y rutas intermedias calculada borde-a-borde para evitar solapamientos orbitales y garantizar saltos alcanzables según la capacidad del tanque.
* 🪐 **Planetas con Reserva Finita (`Planeta` + `ReservaOrbital`):** Cúpulas orbitales con enfriamiento de regeneración y retroalimentación visual dinámica (las órbitas y el radar cambian a naranja y rojo al agotarse).
* ☄️ **Cinturones de Asteroides Tácticos (`CampoAsteroides` + `Asteroide`):** Nubes 3D con deriva orbital lenta, cobertura física contra perseguidores, cosecha estática por proximidad y cápsulas de recursos.
* 📈 **Escalado Progresivo de Oleadas (`GestorOleadas`):** Cronómetro de supervivencia que acelera el ritmo de aparición y despliega escuadrones de refuerzo conforme avanza la partida.
* 📡 **HUD Táctico y Radar 3D (`RadarPlanetas`):** Indicadores direccionales proyectados en pantalla que reflejan la ubicación y el estado energético de cada planeta en tiempo real.
* 📐 **Arquitectura Clean Code & SRP:** Diseño modular guiado por bus de eventos (`EventosJuego`) y composición por nodos, optimizado para mantener **60 FPS** sin acoplamiento entre módulos del equipo.

---

## 🧭 Guía Táctica del Entorno

### Tipos de Planetas
| Tipo | Color de Órbita | Efecto Principal | Comportamiento |
| :--- | :--- | :--- | :--- |
| **Estándar** | 🔵 Cian | Recarga propulsor (`1.0x`) | Reserva equilibrada y gravedad media. |
| **Energético** | 🟡 Ámbar | Recarga ultrarrápida (`1.8x`) | Reserva compacta y baja gravedad para escapes rápidos. |
| **Biológico / Denso** | 🟢 Verde | Repara casco (`+2.5 HP/s`) | Alta reserva y fuerte atracción gravitacional. |

### Variantes de Asteroides
| Variante | Color | Interacción |
| :--- | :--- | :--- |
| **Común** | ⚪ Gris | Bloquea enemigos; `30 %` de probabilidad de soltar reparación de casco (`+15 HP`). |
| **Volátil** | 🔴 Naranja/Rojo | Detona en área al destruirse, dañando y empujando hordas cercanas. |
| **Energético** | 🔵 Cian | **Cosecha estática:** recarga propulsor al volar cerca; suelta celda de energía (`+30`). |
| **Mineral** | 🟡 Dorado | Mayor resistencia; libera **3 orbes de experiencia** al romperse. |

---

## 👥 Equipo de Desarrollo (OA Studios)

| Integrante | Rol | Módulo Principal |
| :--- | :--- | :--- |
| **Isaac Mosquera** | Lead Architect / Dev | Propulsión Interplanetaria, Generación Procedural 3D, Órbitas Finitas, Asteroides, Oleadas y HUD |
| **Diego Vela** | Gameplay Dev | Spawning de Enemigos, IA de Persecución 3D y Lógica de Game Over |
| **Alba Celis** | Mechanics Dev | Sistema de Disparo, Colisiones, Variantes Enemigas y Recompensas (Orbes) |
| **César Martínez** | Audio & 3D Artist | Modelado 3D, Texturizado, VFX y Sistema Sonoro (SFX/BGM) |

---

## 🔌 Contratos de Integración (Bus de Eventos)

Para conectar nuevos sistemas (Game Over, enemigos adicionales o efectos audiovisuales) sin modificar la lógica existente:

* **Grupos de Escena:** `"jugador"`, `"enemigos"` (requiere método `recibir_dano(cantidad)`), `"planetas"`.
* **Señales Globales (`EventosJuego`):**
  * `tiempo_supervivencia_actualizado(segundos_totales, nivel_intensidad)`
  * `oleada_cambiada(nuevo_nivel)`
  * `planeta_agotado(planeta)`
  * `evento_iniciado(nombre, duracion)` / `evento_finalizado(nombre)`

---

## 🎮 Controles

| Acción | Entrada |
| :--- | :--- |
| **Desplazamiento Direccional** | `W A S D` / Flechas |
| **Propulsor Interplanetario** | `Espacio` |
| **Orientación de Cámara** | Ratón |

---

## 🛠️ Requisitos e Instalación

* **Motor:** Godot Engine **4.x** (Compatibility / Forward+).

1. Clona el repositorio:
   ```bash
   git clone [https://github.com/TU_USUARIO/orbital-attack.git](https://github.com/TU_USUARIO/orbital-attack.git)
