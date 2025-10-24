using Godot;
using System;

public partial class MenuConstruccion : CanvasLayer
{
	private TextureButton boton;
	private HBoxContainer menu;

	public override void _Ready()
	{
		// Verifica si el script se ejecuta correctamente
		GD.Print("¡Script cargado correctamente!");

		// Intentamos acceder a los nodos que necesitamos
		boton = GetNode<TextureButton>("Panel1/Button");
		menu = GetNode<HBoxContainer>("Panel1/HBoxContainer");

		// Imprimir si los nodos fueron encontrados correctamente
		if (boton != null)
			GD.Print("Botón encontrado correctamente");
		else
			GD.Print("No se encontró el botón");

		if (menu != null)
			GD.Print("Menú encontrado correctamente");
		else
			GD.Print("No se encontró el menú");

		// Inicialmente ocultamos el menú
		menu.Visible = false;
		GD.Print("Menú oculto al principio");

		// Conectar la señal del botón
		boton.Pressed += OnBotonPressed;
	}

	private void OnBotonPressed()
	{
		// Verificar si se presionó el botón
		GD.Print("¡Botón presionado!");

		// Alternar la visibilidad del HBoxContainer
		menu.Visible = !menu.Visible;

		// Imprimir el estado actual del menú
		GD.Print("Menú visible: " + menu.Visible);

		// Verificamos si el menú se hace visible
		if (menu.Visible)
		{
			GD.Print("El menú ahora es visible.");
		}
		else
		{
			GD.Print("El menú ahora está oculto.");
		}
	}
}
