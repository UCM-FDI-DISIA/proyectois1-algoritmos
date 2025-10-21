using Godot;
using System;

public partial class MinaOroAnimado : StaticBody2D
{
	private AnimatedSprite2D anim;
	private AnimatedSprite2D animOro;
	private CollisionShape2D collisionShape;
	private Timer regenTimer;          // para regenerar la mina
	private Timer depletionDelayTimer; // para retrasar la animación "Apagada"

	private bool isDepleted = false;
	private int oroQueda = 3;
	private const int ORO = 3;
	private const int ORO_INICIAL = 3;
	private const float TIEMPO_REGENERACION = 30f; // segundos
	private const float TIEMPO_AGOTARSE = 0.3f;    // retraso antes de "Apagada"

	[Export] public Vector2I CellSize = new Vector2I(64, 64);

	public override void _Ready()
	{
		anim = GetNode<AnimatedSprite2D>("AnimacionMina");
		animOro = GetNode<AnimatedSprite2D>("AnimacionOro");
		collisionShape = GetNode<CollisionShape2D>("CollisionShape2D");

		if (collisionShape.Shape is RectangleShape2D rect)
			rect.Size = CellSize;

		anim.Play("Idle");
		ZIndex = (int)Position.Y;

		// Crear e inicializar el Timer para regenerar
		regenTimer = new Timer
		{
			WaitTime = TIEMPO_REGENERACION,
			OneShot = true
		};
		AddChild(regenTimer);
		regenTimer.Timeout += OnRegenTimerTimeout;

		// Crear e inicializar el Timer para retrasar "Apagada"
		depletionDelayTimer = new Timer
		{
			WaitTime = TIEMPO_AGOTARSE,
			OneShot = true
		};
		AddChild(depletionDelayTimer);
		depletionDelayTimer.Timeout += OnDepletionDelayTimeout;
	}

	/* --------------------
	   RECOLECCIÓN DE RECURSOS
	----------------------*/
	public void Hit()
	{
		if (isDepleted)
			return;

		oroQueda--;
		GD.Print($"Mina golpeada. Oro restante: {oroQueda}");

		anim.Play("Collect");
		animOro.Play("bolsita");
		anim.AnimationFinished += OnAnimFinished;
	}

	private void OnAnimFinished()
	{
		if (anim.Animation == "Collect")
		{
			// === SUMAR ORO ===
			var manager = GetNode<ResourceManager>("/root/Main/ResourceManager");
			manager.AddResource("gold", ORO);
			GD.Print("Oro añadido: +3");

			anim.AnimationFinished -= OnAnimFinished;

			if (oroQueda <= 0)
			{
				isDepleted = true;
				depletionDelayTimer.Start(); // Espera 0.3 segundos antes de apagarse
			}
			else
			{
				anim.Play("Idle");
			}
		}
	}

	// Espera un poco y luego apaga la mina
	private void OnDepletionDelayTimeout()
	{
		anim.Play("Depleted");

		GD.Print("Mina agotada. Regenerando en 30 segundos...");
		regenTimer.Start(); // inicia regeneración tras agotarse
	}

	// Regenerar la mina tras 30 segundos
	private void OnRegenTimerTimeout()
	{
		GD.Print("Mina regenerada.");
		isDepleted = false;
		oroQueda = ORO_INICIAL;
		anim.Play("Idle");
		if (collisionShape != null)
			collisionShape.Disabled = false;
	}
}
