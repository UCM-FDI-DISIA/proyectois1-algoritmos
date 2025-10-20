using Godot;
using System;

public partial class ArbolAnimado : StaticBody2D
{
	private AnimatedSprite2D anim;
	private CollisionShape2D collisionShape;
	private bool isDead = false;
	private int maderaQueda = 10000;
	private const int MADERA = 5;

	[Export] public Vector2I CellSize = new Vector2I(64, 64);

	public override void _Ready()
	{
		anim = GetNode<AnimatedSprite2D>("AnimacionArbol");
		collisionShape = GetNode<CollisionShape2D>("CollisionShape2D");

		if (collisionShape.Shape is RectangleShape2D rect)
			rect.Size = CellSize;

		anim.Play("Idle");
		ZIndex = (int)Position.Y;
		// Nota: aqui antes se comprobaba si la animacion termina. Esto lo hago solo si hace falta.
	}
	
	//Detecta que ha sido golpeado
	public void Hit()
	{
		if (isDead) return;
		isDead = (maderaQueda <= 0);
		maderaQueda--;
		
		if (isDead) {
			anim.Play("Die");
			if (collisionShape != null) collisionShape.Disabled = true;
		}
		else {
			anim.Play("chop");
			anim.AnimationFinished += OnAnimFinished;
		}
	}
	
	//Esto nunca ocurre porque he hecho la animacion un bucle infinto, pero que se puede a futuro vamos
	private void OnAnimFinished()
	{
		if (anim.Animation == "Die")
			QueueFree(); // eliminar árbol tras morir
		
		if (anim.Animation == "chop")
		{
			anim.Play("Idle");
			
			// === SUMAR 5 A MADERA ===
			var manager = GetNode<ResourceManager>("/root/Main/ResourceManager");
			manager.AddResource("wood", MADERA); 
			
			anim.AnimationFinished -= OnAnimFinished;
		}
	}
}
