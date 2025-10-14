using Godot;
using System;

//NO CAMBIAR

public partial class MainMenu : Control
{
	public override void _Ready()
	{
		Button playButton = GetNode<Button>("PlayButton");
		playButton.Pressed += OnPlayButtonPressed;
	}

	private void OnPlayButtonPressed()
	{
		// Cambia a la escena principal del juego
		// El main esta en la carpeta src 
		GetTree().ChangeSceneToFile("res://src/main.tscn");
	}
}
