# Feudalia - AlgoRitmos

### Instrucciones de uso (EJECUTABLE)
1. Localiza la carpeta para la plataforma correspondiente en la carpeta `/executable` (Windows o Linux) y descárgala.
2. Ejecuta el juego haciendo doble clic en el archivo correspondiente (Windows: .exe, Linux: .x86_64 o .sh).
3. (Opcional en Windows) Puedes abrir la consola de depuración para ver, en tiempo real, información detallada sobre señales, eventos, interacciones, conexiones...

### Instrucciones de uso (Ejecución en el entorno + DEPURACIÓN / COMPILACIÓN)
1. Descarga [Godot Engine 4.5.](https://godotengine.org/releases/4.5/) (es suficiente con la versión estándar, sin .NET) 
2. Descarga este repositorio completo en una carpeta local (por ejemplo `/carpeta_local`).
3. Abre Godot 4.5. e importa el proyecto seleccionando la carpeta `/carpeta_local` (la que contiene el archivo project.godot)
4. Ejecuta y compila el proyecto pulsando Reproducir Proyecto (F5).

<br>

> [!WARNING]
> El modo multijugador PVP utiliza GDSync, un plugin avanzado de Godot especializado en sincronización en red. Para que funcione correctamente, deben cumplirse las siguientes condiciones:
> - Tener conexión a internet estable.
> - Tener acceso permitido a conexiones WebSocket (ws) hacia el servidor de GDSync.
> Si ocurre algún problema, el juego mostrará un mensaje informativo en pantalla.

> [!NOTE]
> Para más información sobre la depuración/"compilación" en Godot 4.5., véase el siguiente archivo: [README_Instrucciones.txt](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/blob/main/executable/README_Instrucciones.txt)

> [!NOTE]
> ¡También se puede jugar a _Feudalia_ online en el modo PVE (un jugador contra la máquina)!: [Feudalia PVE](https://andy-uno.itch.io/feudalia)

<br>

----
## Wiki
Visita nuestra [Wiki](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki) para mayor detalle.

### Índice
---

<details>
<summary><strong>📘 Documentación</strong></summary>
<br>

* [Documento de Especificación de Requisitos](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/especificacionIEEE830.md)
    * [Sección 1: Introducción](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/IEEE830intro.md)
    * [Sección 2: Descripción general](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/IEEE830descrip.md)
    * [Sección 3: Requisitos específicos](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/IEEE830requis.md)
* [Documento técnico - TDD](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/documentoTecnico.md)
* [Manual del Usuario](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/manualDelUsuario.md)

</details>

---

<details>
<summary><strong>🎨 Diseño gráfico</strong></summary>
<br>

* [Estética y diseño](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/estetica_papel.md)
    * [Interfaz](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/diseno_interfaz.md)
    * [Diseño de personajes](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/diseno_personajes.md)
    * [Diseño de recursos](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/diseno_recursos.md)
* [Enlazado de recursos](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/Enlazado-de-recursos)

</details>

---

<details>
<summary><strong>🧩 Proceso Scrum</strong></summary>
<br>

* [Usuarios de _Feudalia_](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/Historias-de-usuario)
    * [Historias de usuario](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/historiasusuario.md)
    * [Product Backlog](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/productBacklog.md)
* [Planificación de los Sprints](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/sprints.md)
    * [Revisión de los Sprints](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/revisionSprints.md)
    * [Retrospectiva de los Sprints](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/retrospectivaSprints.md)
    * [Sprint Backlog](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/backlogSprint.md)
* [Reuniones del equipo](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/reuniones.md)
    * [MVP - Producto Mínimo Viable](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/MVP.md)
    * [DoD (Definition of Done)](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/definitionOfDone.md)

</details>

---

<details>
<summary><strong>🧪 Control de calidad</strong></summary>
<br>

* [Gestión de Control de Calidad del Software](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/gestion_de_control_de_calidad_del_software.md)
    * [Registro de las Revisiones Técnicas Formales](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/RTF.md)
* [Estándares de diseño](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/Est%C3%A1ndares-de-dise%C3%B1o)
* [Estándares PEGI](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/PEGI12)
* [Metodología de pruebas de Feudalia](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/pruebas_feudalia.md)
* [Control de calidad de otros equipos](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/control_calidad_externo.md)
    * [Feedback para el equipo G2 (Veneris)](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/control_de_calidad_G2.md)
    * [Feedback para el equipo G3 (LogBait)](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/control_de_calidad_G3.md)
    * [Feedback para el equipo G4 (Scrabble)](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/control_de_calidad_G4.md)
* [Plan de acción sobre nuestras RTF](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/RTF.md)

</details>

---

<details>
<summary><strong>⚠️ Gestión de riesgos</strong></summary>
<br>

* [Introducción](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/introduccionRiesgos.md)
* [Priorización de riesgos del proyecto](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/priorizacionRiesgos.md)
* [Reducción, supervisión y gestión del riesgo](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/gestionRiesgos.md)
* [Planificación temporal](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/planificacionRiesgos.md)
* [Resumen](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/resumenRiesgos.md)
* [Issue Tracker](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/issueTracker.md)

</details>

---

<details>
<summary><strong>📎 Anexo</strong></summary>
<br>

* [Documento IEEE830](https://docs.google.com/document/d/1hdwNOZvPmhaxj7iX_lu-zgpNqmKbLNv1iK7gSXKCvug/edit?tab=t.0#heading=h.u2atzjnlxad) (previo al Sprint 1)
* [Referencias y recursos](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/recursosyreferencias.md)
* [Referencias - diseño](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/referencias_diseno.md)

</details>

---

<details>
<summary><strong>🛠️ Ayudas</strong></summary>
<br>

* [Guía Git](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/Gu%C3%ADa-de-actualizaci%C3%B3n-del-repositorio-%E2%80%94-Proyecto-Feudalia-(Windows))

</details>

---

### Versiones

### Estado del proyecto:
- Sprint 1: Definición del alcance, mecánicas y organización inicial.
- Sprint 2: Prototipo ejecutable básico.
- Sprint 3: Mecánicas de recolección de recursos, construcción de casas y reclutamiento de soldados.
- Sprint 4: Multijugador, ataque y refinamiento de la construcción de casas.
- Sprint 5: Refinamiento de multijugador, NPCs (recolectores automáticos) y bot para 1 jugador.
  
### Proyecto

**Descripción:**
Feudalia se plantea como un videojuego de desarrollo independiente con todo su código de acceso libre publicado en GitHub. Se pretende que, siendo de código abierto, llegue a un público amplio interesado en probar, modificar, compartir y mejorar el proyecto.

**Visualización**

Capturas:
<img width="1141" height="645" alt="Captura de Pantalla 2025-11-30 a las 14 28 13" src="https://github.com/user-attachments/assets/69da9bf0-dab5-4557-b28c-9bdac0e0235e" />
<img width="1141" height="645" alt="Captura de Pantalla 2025-11-30 a las 14 28 42" src="https://github.com/user-attachments/assets/f4e7161e-3e87-4e89-8809-32b7e2dd1908" />
<img width="1141" height="645" alt="Captura de Pantalla 2025-11-30 a las 14 29 01" src="https://github.com/user-attachments/assets/91b251fd-a158-4086-88d3-7145685cc738" />
<img width="1097" height="645" alt="Captura de Pantalla 2025-11-30 a las 14 29 26" src="https://github.com/user-attachments/assets/466101a6-c9ad-4585-85e1-f868134b1234" />



### Arquitectura
**Herramientas**
- Motor de desarrollo: Godot
- Lenguaje: GDScript
- Repositorio: GitHub

**Assets**


Recursos prediseñados para la inspiración del Diseño Gráfico de Feudalia. Las siguientes son todas [librerías de assets de uso libre](https://itch.io/game-assets/free/tag-pixel-art) seleccionadas dentro del enlace:
- [Tiny Swords](https://pixelfrog-assets.itch.io/tiny-swords) - Pack general de edificios y personajes + UI + terreno
- [Pixel Crawler](https://anokolisa.itch.io/free-pixel-art-asset-pack-topdown-tileset-rpg-16x16-sprites) - Extras de estaciones y edificios customizables + props
- [Hana Caraka Bundle](https://itch.io/s/101184/hana-caraka-bundle) - Un poco de todo con otro estilo.
- [Cute Fantasy Free](https://kenmi-art.itch.io/cute-fantasy-rpg) - Animales y terreno.
- UI asset pack - Tiny Swords v0.
- [Forest nature pack](https://toffeecraft.itch.io/forest-nature-pack) - Vegetación.
- [16x16-mini-world-sprites](https://merchant-shade.itch.io/16x16-mini-world-sprites) - Mapa.

Las siguientes son [librerías de uso libre](https://opengameart.org/) de varias funcionalidades, especialmente música y efectos de sonido:
- Asset packs generales
- [Librerías de sonidos](https://opengameart.org/art-search-advanced?keys=&title=&field_art_tags_tid_op=or&field_art_tags_tid=&name=&field_art_type_tid%5B%5D=13&sort_by=count&sort_order=DESC&items_per_page=24&Collection=)
- [Librerías de música](https://opengameart.org/art-search-advanced?keys=&field_art_type_tid%5B%5D=12&sort_by=count&sort_order=DESC)

### Ficha técnica
- Título: Feudalia
- Rating: +12
- Propósito del juego: Entrar al mercado con una idea original y rompedora que mezcla las mejores mecánicas y características de los juegos RTS, de gestión y de estrategia.
- Género: Estrategia en tiempo real (RTS) con gestión de recursos y rol.
- Público: Jugadores interesados en estrategia, simulación y construcción.

### Ciclos de juego

**Objetivo a largo plazo**: conquistar territorios enemigos para ganar la partida.
**Objetivo a corto plazo**: crecer el ejercito para vencer en las batallas contra otros feudos.
**Descripción de los ciclos**
- Recolección: obtener recursos que permitan expandir el ejército y aumentar capacidades de defensa y ataque.
- Combate: declaración de una batalla para la que se accede al círculo de combate donde se determina el resultado y quién expande su territorio.
- Expansión: se desarrolla la actividad normal en el nuevo territorio adquirido.

**Interacciones entre los ciclos:**
- Recolección → Combate: Una vez que se ha recolectado suficiente recursos, el jugador puede lanzar un ataque. Si el jugador ha fortalecido bien su ejército, está listo para enfrentarse a los enemigos.
- Combate → Expansión: Tras una victoria en el combate, el jugador pasa al ciclo de expansión, donde gestionará el nuevo territorio y lo hará más fuerte para futuras conquistas.
- Expansión → Recolección: La expansión de un nuevo territorio crea más oportunidades para recolectar recursos adicionales, lo que a su vez fortalece la capacidad de luchar y defenderse en el futuro.

### Estética

**Visual**
- Paleta de colores
  
	- Menú de inicio:
 
   <img width="300"  alt="Captura de Pantalla 2025-11-30 a las 14 28 13-colorpalette" src="https://github.com/user-attachments/assets/0ff50bc8-b1f7-4472-8e0f-ba202b8e21e6" />
 

   - Pantalla principal:
     
	<img width="300" alt="Captura de Pantalla 2025-11-30 a las 14 29 01-colorpalette" src="https://github.com/user-attachments/assets/59fa2a58-4ba5-409a-ab2d-67e824543fd8" />

	- Campo de batalla:
	<img width="300" alt="Captura de Pantalla 2025-11-30 a las 14 29 26-colorpalette" src="https://github.com/user-attachments/assets/511b63de-b7dc-451c-8962-7150860a42b6" />


- Referencias
<img width="643" height="673" alt="refes" src="https://github.com/user-attachments/assets/8ad00280-b59f-4aec-a862-502e4459fb39" />


**Musical**

- [Librerías de sonidos](https://opengameart.org/art-search-advanced?keys=&title=&field_art_tags_tid_op=or&field_art_tags_tid=&name=&field_art_type_tid%5B%5D=13&sort_by=count&sort_order=DESC&items_per_page=24&Collection=)
- [Librerías de música](https://opengameart.org/art-search-advanced?keys=&field_art_type_tid%5B%5D=12&sort_by=count&sort_order=DESC)
  
### Controles
- Movimiento: WASD
- Ataque: clicks izquierdo y derecho
  
## Organización del repositorio
- `/docs`: Documentación del juego (visión, mecánicas, backlog).
- `/src`: Código fuente.
- `/assets`: Recursos gráficos, sonoros y otros.
- `/design`: Bocetos visuales y mockups.
- `/tests`: Pruebas unitarias y de integración.

## Equipo:
- Julia Ceregido Andrade.
- Míriam Elena Cheikho Ferariu.
- Andrés García-Redondo Gallego.
- David Morales Bravo.
- Inés Pérez Herrera.
- Carla Tomás Aguilar.
- Claudia Villodre Pérez.

## FAQ
1. ¿Cómo comienzo a recolectar recursos?

- Al inicio del juego, recibirás un mapa con zonas de recolección básicas.
- Haz clic en las áreas marcadas para recolectar materiales como madera, piedra y hierbas.
- Cada recurso tiene un tiempo de recarga, así que revisa regularmente los puntos de recolección.


2. ¿Puedo jugar con amigos?
Sí, puedes competir en arenas PvP para ver quién tiene la mejor estrategia.


## Trabajos previos a la creación del repositorio:

- Carpeta de trabajo de Drive: https://drive.google.com/drive/folders/1AqEUSHkFcv267KFLV2Ws3VApdfcuCPCo?usp=drive_link

- Documento de especificación de Requisitos original: https://docs.google.com/document/d/1hdwNOZvPmhaxj7iX_lu-zgpNqmKbLNv1iK7gSXKCvug/edit?tab=t.0#heading=h.u2atzjnlxad
