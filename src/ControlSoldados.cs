using Godot;
using System;

public partial class ControlSoldadosScript : Control
{
	private CanvasLayer menuSoldados;
	private Button botonMenu;

	public override void _Ready()
	{
		// Desde este nodo (ControlSoldados), MenuSoldados es hijo directo
		menuSoldados = GetNode<CanvasLayer>("MenuSoldados");
		menuSoldados.Visible = false; // Oculto inicialmente

		// Botón está en otra parte, usamos ruta absoluta
		botonMenu = GetNode<Button>("/root/Main/BotonSoldados/Boton");

		botonMenu.Pressed += OnBotonMenuPressed;
	}

	private void OnBotonMenuPressed()
	{
		ToggleMenu();
	}

	private void ToggleMenu()
	{
		menuSoldados.Visible = !menuSoldados.Visible;
		GD.Print($"MenuSoldados.Visible = {menuSoldados.Visible}");
	}

	public override void _Input(InputEvent @event)
	{
		if (@event is InputEventKey keyEvent && keyEvent.Pressed && !keyEvent.Echo)
		{
			if (keyEvent.Keycode == Key.C)
			{
				ToggleMenu();
			}
		}
	}
}
