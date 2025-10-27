using Godot;
using System;

public partial class ControlSoldados : Control
{
	private CanvasLayer menuSoldados;

	public override void _Ready()
	{
		// Desde este nodo (ControlSoldados), MenuSoldados es hijo directo
		menuSoldados = GetNode<CanvasLayer>("MenuSoldados");
		menuSoldados.Visible = false; // Oculto inicialmente
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
			// Tecla M
			if (keyEvent.Keycode == Key.M)
			{
				ToggleMenu();
			}
		}
	}
}
