using Godot;
using System;

public partial class Arbol : StaticBody2D
{
	private AnimatedSprite2D anim;

	public override void _Ready()
	{
		anim = GetNode<AnimatedSprite2D>("Animacion");

		// Iniciar animación Idle
		anim.Play("Idle");

		// Ajustar ZIndex según Y
		ZIndex = (int)Position.Y;
	}

	public override void _Process(double delta)
	{
		// Solo si el árbol se mueve, sino se puede quitar
		ZIndex = (int)Position.Y;
	}
}
