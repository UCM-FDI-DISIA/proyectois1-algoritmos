===================================
Instrucciones de uso (EJECUTABLE):
===================================

En la carpeta actual se pueden ver distintas subcarpetas para descargar un ejecutable de Feudalia en cada Plataforma. Esta opción no requiere tener instalado el entorno de desarrollo (Godot engine 4.5.).

1. Descargue la versión correspondiente al sistema operativo de su dispositivo. En esa carpeta encontrará: 
	- Un archivo ejecutable con el juego (Windows: .exe, Linux: .x86_64 o .sh).
	- Un archivo .pvk.
	- Un archivo ejecutable adicional de consola/depuración (Windows: .console.exe)
3. Ejecute el juego haciendo doble click en el fichero correspondiente. Se abrirá una pantalla con el fondo del juego y dos modos de juego: PVE (juego contra la máquina) y PVP (juego multijugador).
4. (Opcional) Para información adicional, puede abrir la consola de depuración, que contiene un detalle por texto de todas las señales, eventos, interacciones, conexiones, etc relevantes que se producen en cada momento. 


===========================================
Requisitos para el funcionamiento del PVP
===========================================

El modo multijugador, PVP, se ha programado a través de GDSync, un plugin avanzado de Godot especializado en la programación de esta funcionalidad. Para que funcione este modo de juego deben darse las condiciones necesarias para que este plugin se ejecute correctamente:

* Conexión a internet estable. 
* Acceso permitido a conexiones WebSocket (ws) hacia el servidor de GDSync. Si su red (firewall, proxy, red corporativa, etc.) bloquea WebSockets (como por ejemplo, la red de la UCM) o el acceso al servidor, el modo PVP puede no funcionar.

En cualquier caso, si se da alguno de estos inconvenientes, el jugador será informado por pantalla según corresponda.


===================================================
Ejecución en el entorno (DEPURACIÓN/COMPILACIÓN):
===================================================

En el repositorio de GitHub, se encuentra el código del proyecto completo, ejecutable en el entorno de desarrollo Godot 4.5.

Para compilar y ejecutar el código en el entorno de desarrollo se deben seguir las siguientes instrucciones:

1. Descargar Godot engine 4.5. (https://godotengine.org/releases/4.5/). Es suficiente con la versión "Godot engine", sin .NET.
2. Descargar el repositorio completo en una carpeta local (por ejemplo Feudalia/).
3. Abrir Godot 4.5.
4. Importar el proyecto seleccionando la carpeta Feudalia/ (la que contiene un project.godot).
5. Espere a que Godot termine de importar las librerías y archivos que hemos usado para este proyecto. 
6. Ejecute y compile el proyecto: Pulse el botón "Reproducir Proyecto" (F5) situado en la esquina superior derecha.

Para probar el PVP es necesario activar nuevas instancias de depuración (por defecto sólo se abrirá una).

1. Abra el menú Depurar > Personalizar instacias…
2. Marque la casilla "Habilitar múltiples instancias".
3. Seleccione al menos 2 instancias de depuración.
4. Cada instancia se ejecuta de forma independiente. Para controlar una, seleccione dicha ventana. 


Para ver la depuración del proyecto:

- En la barra inferior se encuentran las opciones de "Salida" (incluye nuestros propios mensajes de depuración) y "Depurador" (errores no fatales y warnings en cada instancia de depuración). 
- En caso de haber algún error fatal, se detiene la instancia de depuración en la que se haya producido y el texto de error se muestra directamente. 


ORGANIZACIÓN DEL PROYECTO (orientación rápida en Godot):

- Panel inferior izquierdo (Sistema de Archivos): contiene las carpetas del proyecto. 
- Las escenas .tscn, son las unidades estructurales principales (pantallas, niveles, personajes, mapas...).
- Para abrir una escena, basta con hacer doble click en su fichero .tscn, y entonces, se puede consultar lo siguiente en el entorno de desarrollo.
	- Panel superior izquierdo: Árbol de nodos.
	- Panel derecho: Inspector (propiedades del nodo seleccionado).
	- Barra superior: visualización 2D del nodo y de sus Scripts (aparecen como pergaminos al lado de su nodo correspondiente).
