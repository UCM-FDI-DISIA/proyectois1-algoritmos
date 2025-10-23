using Godot;
using System;

public partial class MenuCanvas : CanvasLayer
{
	// Referencia al nodo del menú
	private Control menuSoldados;

	public override void _Ready()
	{
		// Obtener referencia al menú
		menuSoldados = GetNode<Control>("MenuSoldados");

		// Conectar la señal del botón
		var botonMenu = GetNode<Button>("BotonMenu");
		botonMenu.Pressed += OnBotonMenuPressed;

		// Asegurar que el menú comience oculto (opcional)
		menuSoldados.Visible = false;
	}

	private void OnBotonMenuPressed()
	{
		// Alternar visibilidad
		menuSoldados.Visible = !menuSoldados.Visible;
	}
}
