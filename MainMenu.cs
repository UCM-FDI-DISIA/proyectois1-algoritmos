using Godot;
using System;

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
		GetTree().ChangeSceneToFile("res://main.tscn");
	}
}
