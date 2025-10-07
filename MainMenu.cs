using Godot;
using System;

public partial class MainMenu : Control
{
	public override void _Ready()
	{
		// Conectamos el botón desde código (opcional, si no lo haces desde el editor)
		Button playButton = GetNode<Button>("PlayButton");
		playButton.Pressed += OnPlayButtonPressed;
	}

	private void OnPlayButtonPressed()
	{
		// Cambia a la escena del juego
		GetTree().ChangeSceneToFile("res://player.tscn");
	}
}
