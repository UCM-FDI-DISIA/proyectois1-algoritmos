using Godot;
using System;

public partial class Arbol : StaticBody2D
{
	private AnimatedSprite2D anim;

	public override void _Ready()
	{
		anim = GetNode<AnimatedSprite2D>("Animacion");

		ZAsRelative = false;
		ZIndex = (int)Position.Y;

		// Iniciar animación Idle y dejarla siempre en loop
		anim.Play("Idle");
	}

	public override void _Process(double delta)
	{
		// Mantener el orden de dibujo según la altura
		ZIndex = (int)Position.Y;
	}
}
