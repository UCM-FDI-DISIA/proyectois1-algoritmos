# Feudalia
## AlgoRitmos

### Wiki
Visita nuestra [Wiki](wiki) para mayor detalle.

---

### Índice

* [X Home](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki)

#### Documentación

* [Documento de Especificación de Requisitos](especificacionIEEE830.md).
    * [Sección 1: Introducción](IEEE830intro.md).
    * [Sección 2: Descripción general](IEEE830descrip.md).
    * [Sección 3: Requisitos específicos](IEEE830requis.md).
* [X Documento Técnico](documentotecnico.md).


#### Diseño gráfico

* [Estética y diseño](estetica_papel.md)
    * [Interfaz](diseno_interfaz.md).
    * [Diseño de personajes](diseno_personajes.md).
    * [Diseño de recursos](diseno_recursos.md).
* [Enlazado de recursos](Enlazado-de-recursos).

#### Proceso Scrum

* [Usuarios de _Feudalia_](https://github.com/UCM-FDI-DISIA/proyectois1-algoritmos/wiki/Historias-de-usuario).
    * [Historias de usuario](historiasusuario.md).
* [Planificación de los Sprints](sprints.md).
    * [Revisión de los Sprints](revisionSprints.md).
    * [Retrospectiva de los Sprints](retrospectivaSprints.md).
    * [Sprint Backlog](backlogSprint.md).
* [Reuniones del equipo](reuniones.md).
    * [MVP - Producto Mínimo Viable](MVP.md).
    * [X DoD (Definition of Done)](definitionOfDone.md). 
* [Pruebas de Feudalia (control de calidad)](pruebas_feudalia.md).

#### Control de calidad

* [Control de calidad](control_de_calidad.md).

#### Gestión de riesgos

* [Introducción](introduccionRiesgos.md). 
* [Priorización de riesgos del proyecto](priorizacionRiesgos.md).
* [Reducción, supervisión y gestión del riesgo](gestionRiesgos.md).
* [Planificación temporal](planificacionRiesgos.md).
* [Resumen](resumenRiesgos.md). 

##### Anexo

* [Documento IEEE830](https://docs.google.com/document/d/1hdwNOZvPmhaxj7iX_lu-zgpNqmKbLNv1iK7gSXKCvug/edit?tab=t.0#heading=h.u2atzjnlxad) (previo al Sprint 1).
* [Referencias y recursos](recursosyreferencias.md).
* [Referencias - diseño](referencias_diseno.md).
* [Product Backlog](productBacklog.md).

---
### Versiones

### Estado del proyecto:
- Sprint 1: Definición del alcance, mecánicas y organización inicial.
- Sprint 2: Prototipo ejecutable básico.
  
### Proyecto

**Descripción:**
Feudalia se plantea como un videojuego de desarrollo independiente con todo su código de acceso libre publicado en GitHub. Se pretende que, siendo de código abierto, llegue a un público amplio interesado en probar, modificar, compartir y mejorar el proyecto.

**Visualización**

Capturas:
<img width="1149" height="646" alt="Captura de pantalla 2025-10-11 121954" src="https://github.com/user-attachments/assets/e7ae3ea2-d047-4f52-a60c-65d4131aca61" />

### Arquitectura
**Herramientas**
- Motor de desarrollo: Godot
- Lenguaje: C# Sharp
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

**Objetivo a largo plazo**: ganar puntuación para subir en el ranking.
**Objetivo a corto plazo**: conquistar territorios enemigos para ganar la partida.
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
		
  <img width="200" height="400" alt="Captura de pantalla 2025-10-11 121954-colorpalette" src="https://github.com/user-attachments/assets/1ce4bd8f-fc18-4968-92fe-4252d2bb348c" />

   - Pantalla principal:
  
  <img width="200" height="400" alt="Captura de pantalla 2025-10-11 122014-colorpalette" src="https://github.com/user-attachments/assets/bdef18e7-ea73-4bd3-8549-1e24ec256408" />

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


## Trabajos previos a la creación del repositorio:

- Carpeta de trabajo de Drive: https://drive.google.com/drive/folders/1AqEUSHkFcv267KFLV2Ws3VApdfcuCPCo?usp=drive_link

- Documento de especificación de Requisitos original: https://docs.google.com/document/d/1hdwNOZvPmhaxj7iX_lu-zgpNqmKbLNv1iK7gSXKCvug/edit?tab=t.0#heading=h.u2atzjnlxad
