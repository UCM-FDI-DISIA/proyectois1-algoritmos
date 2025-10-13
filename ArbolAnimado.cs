using Godot;
using System;

public partial class Arbol : StaticBody2D
{
	private AnimatedSprite2D anim;
	private CollisionShape2D collisionShape;

	[Export] public Vector2I CellSize = new Vector2I(64, 64); // Tamaño del tile

	public override void _Ready()
	{
		anim = GetNode<AnimatedSprite2D>("Animacion");
		collisionShape = GetNode<CollisionShape2D>("CollisionShape2D");

		anim.Play("Idle");
		ZIndex = (int)Position.Y;

		// Ajustar tamaño del collider automáticamente
		if (collisionShape.Shape is RectangleShape2D rect)
			rect.Size = CellSize;
	}
}
