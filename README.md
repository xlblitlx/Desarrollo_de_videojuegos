# 🚀 Orbital Attack

**Un videojuego 3D Roguelite de exploración orbital y combate interplanetario.**

![Godot Engine](https://img.shields.io/badge/Godot_Engine-v4.x-blue?style=for-the-badge&logo=godotengine&logoColor=white)
![Status](https://img.shields.io/badge/Estado-Vertical_Slice_(Demo)-neon?style=for-the-badge)
![License](https://img.shields.io/badge/Licencia-MIT-green?style=for-the-badge)

---

## 🌌 Acerca del Proyecto

**Orbital Attack** es una experiencia espacial desarrollada en **Godot 4** que combina generación procedural de sistemas estelares, físicas de contención orbital y navegación rápida por el espacio abierto. 

El jugador toma el control de una nave confinada en la órbita de un planeta inicial, con la capacidad de activar sus propulsores para vencer el campo de fuerza orbital, combatir naves enemigas y recolectar energía mientras viaja hacia nuevos horizontes celestes.

---

## ✨ Características Principales (Demo Jugable)

- 🪐 **Generación Procedural de Sistemas:** Distribución orgánica de planetas mediante algoritmos de distancias (*Poisson Disk Sampling*).
- 🛡️ **Físicas y Cúpulas Orbitales:** Campo de fuerza holográfico neón (`#00E5FF`) que contiene y acopla al jugador a la órbita activa.
- 🚀 **Propulsión Interplanetaria:** Transición entre vuelo orbital y transporte espacial a alta velocidad.
- 👾 **Encuentros y Combate:** Enjambres de enemigos con IA de persecución en 3D.
- 💎 **Sistema de Recompensas (Loot):** Recolección dinámica de orbes de energía lanzados por enemigos destruidos.
- 📐 **Arquitectura Clean Code & SRP:** Diseño 100% modular, desacoplado y guiado por eventos (*Event-Driven Architecture* mediante Señales de Godot).

---

## 👥 Equipo de Desarrollo (OA Studios)

| Integrante | Rol | Módulo Principal |
| :--- | :--- | :--- |
| **Isaac Mosquera** | Lead Architect / Dev | Propulsión Interplanetaria, GeneradorMapa, GestorOrbita e Integración |
| **Diego Vela** | Gameplay Dev | Spawning de Enemigos e IA de Persecución 3D |
| **Alba Celis** | Mechanics Dev | Sistema de Disparo, Colisiones y Recompensas (Orbes) |
| **César Martínez** | Audio & 3D Artist | Modelado 3D, Texturizado y Sistema Sonoro (SFX/BGM) |

---

## 🛠️ Requisitos e Instalación

1. Clona el repositorio:
   ```bash
   git clone [https://github.com/TU_USUARIO/orbital-attack.git](https://github.com/TU_USUARIO/orbital-attack.git)
