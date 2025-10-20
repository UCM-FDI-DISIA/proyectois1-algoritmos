using Godot;
using System;

public partial class ArbolAnimado : StaticBody2D
{
	private AnimatedSprite2D anim;
	private CollisionShape2D collisionShape;
	
	
	// Atributos auxiliares para la 
	// RECOLECCION DE RECURSOS
	
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
	
	
	
	/* --------------------
	RECOLECCION DE RECURSOS
	----------------------*/
	
	// Detecta que ha sido golpeado
	public void Hit()
	{
		// Actualizo madera disponible 
		// He dejado el recurso como "finito" por si en versiones posteriores quisieramos tocarlo.
		if (isDead) return;
		isDead = (maderaQueda <= 0);
		maderaQueda--;
		
		if (isDead) {
			anim.Play("Die");
			// Si el arbol muere, puedes atravesar el tronco (se puede omitir si preferis)
			if (collisionShape != null) collisionShape.Disabled = true;
		}
		else {
			anim.Play("chop");
			// Hago que la animacion termine y se resetee a Idle correctamente
			// OnAnimFinished tambien suma la madera (para que se actualice el contador despues de la animacion)
			anim.AnimationFinished += OnAnimFinished;
		}
	}
	
	// Realmente, esto solo se ejecuta si "chop"
	//    - Cuando termina la animacion de "chop" cambio el contador.
	// Con "Die" entra en bucle y no llega a llamarlo
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
