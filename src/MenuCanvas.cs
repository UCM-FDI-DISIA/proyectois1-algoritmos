using Godot;
using System;

public partial class MenuCanvas : CanvasLayer
{
	private CanvasLayer menuSoldados2;
	private Button botonMenu;

	public override void _Ready()
	{
		menuSoldados2 = GetNode<CanvasLayer>("MenuSoldados/MenuSoldados2");
		botonMenu = GetNode<Button>("Boton");

		menuSoldados2.Visible = false;

		botonMenu.Pressed += OnBotonMenuPressed;
	}

	private void OnBotonMenuPressed()
	{
		ToggleMenu();
	}

	private void ToggleMenu()
	{
		menuSoldados2.Visible = !menuSoldados2.Visible;
		GD.Print($"MenuSoldados2.Visible = {menuSoldados2.Visible}");
	}

	public override void _Input(InputEvent @event)
	{
		// Detectar la tecla C
		if (@event is InputEventKey keyEvent && keyEvent.Pressed && !keyEvent.Echo)
		{
			if (keyEvent.Keycode == Key.C)
			{
				ToggleMenu();
			}
		}
	}
}
