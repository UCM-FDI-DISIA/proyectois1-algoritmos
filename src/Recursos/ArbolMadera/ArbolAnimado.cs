using Godot;
using System;

public partial class ArbolAnimado : StaticBody2D
{
	private AnimatedSprite2D anim;
	private CollisionShape2D collisionShape;
	private bool isDead = false;

	[Export] public Vector2I CellSize = new Vector2I(64, 64);

	public override void _Ready()
	{
		anim = GetNode<AnimatedSprite2D>("AnimacionArbol");
		collisionShape = GetNode<CollisionShape2D>("CollisionShape2D");

		if (collisionShape.Shape is RectangleShape2D rect)
			rect.Size = CellSize;

		anim.Play("Idle");
		ZIndex = (int)Position.Y;
		anim.AnimationFinished += OnAnimFinished;
	}
	
	//Detecta que ha sido golpeado
	public void Hit()
	{
		if (isDead) return;
		isDead = true;

		if (collisionShape != null) collisionShape.Disabled = true;
		anim.Play("Die");
	}
	
	//Esto nunca ocurre porque he hecho la animacion un bucle infinto, pero que se puede a futuro vamos
	private void OnAnimFinished()
	{
		if (anim.Animation == "Die")
			QueueFree(); // eliminar árbol tras morir
	}
}
