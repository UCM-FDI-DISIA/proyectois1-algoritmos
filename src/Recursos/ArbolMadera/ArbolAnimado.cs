using Godot;
using System;

public partial class ArbolAnimado : StaticBody2D
{
	private AnimatedSprite2D anim;
	private AnimatedSprite2D animTronco;
	private CollisionShape2D collisionShape;
	private Timer regenTimer;       // para regenerar el árbol
	private Timer deathDelayTimer;  // para retrasar la animación "Die"

	private bool isDead = false;
	private int maderaQueda = 3;
	private const int MADERA = 5;
	private const int MADERA_INICIAL = 3;
	private const float TIEMPO_REGENERACION = 30f; // segundos
	private const float TIEMPO_MORIR = 0.01f; // Esperar 1 segundo antes de "Die"

	[Export] public Vector2I CellSize = new Vector2I(64, 64);

	public override void _Ready()
	{
		anim = GetNode<AnimatedSprite2D>("AnimacionArbol");
		animTronco = GetNode<AnimatedSprite2D>("AnimacionTronco");
		collisionShape = GetNode<CollisionShape2D>("CollisionShape2D");

		if (collisionShape.Shape is RectangleShape2D rect)
			rect.Size = CellSize;

		anim.Play("Idle");

		// Timer para regenerar
		regenTimer = new Timer
		{
			WaitTime = TIEMPO_REGENERACION,
			OneShot = true
		};
		AddChild(regenTimer);
		regenTimer.Timeout += OnRegenTimerTimeout;

		// Timer para retrasar la animación de "Die"
		deathDelayTimer = new Timer
		{
			WaitTime = TIEMPO_MORIR,
			OneShot = true
		};
		AddChild(deathDelayTimer);
		deathDelayTimer.Timeout += OnDeathDelayTimeout;
	}

	/* --------------------
	   RECOLECCIÓN DE RECURSOS
	----------------------*/
	public void Hit()
	{
		if (isDead)
			return;

		maderaQueda--;
		GD.Print($"Árbol golpeado. Madera restante: {maderaQueda}");

		anim.Play("chop");
		animTronco.Play("tronquito"); 
		anim.AnimationFinished += OnAnimFinished;
	}

	private void OnAnimFinished()
	{
		if (anim.Animation == "chop")
		{
			// === SUMAR MADERA ANTES DE MORIR ===
			var manager = GetNode<ResourceManager>("/root/Main/ResourceManager");
			manager.AddResource("wood", MADERA);
			GD.Print("Madera añadida: +5");

			anim.AnimationFinished -= OnAnimFinished;

			if (maderaQueda <= 0)
			{
				isDead = true;
				deathDelayTimer.Start(); // Espera 1 segundo antes de morir
			}
			else
			{
				anim.Play("Idle");
			}
		}
	}

	private void OnDeathDelayTimeout()
	{
		anim.Play("Die");
		if (collisionShape != null)
			collisionShape.Disabled = true;

		GD.Print("Árbol caído. Regenerando en 30 segundos...");
		regenTimer.Start();
	}

	private void OnRegenTimerTimeout()
	{
		GD.Print("Árbol regenerado.");
		isDead = false;
		maderaQueda = MADERA_INICIAL;
		anim.Play("Idle");
		if (collisionShape != null)
			collisionShape.Disabled = false;
	}
}
