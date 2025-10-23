using Godot;
using System;

public partial class MinaPiedraAnimado : StaticBody2D
{
	private AnimatedSprite2D animExplosion;
	private CollisionShape2D collisionShape;
	private Node2D rocasGrandes;
	private Node2D rocasPequenas;
	private Timer regenTimer;
	private Timer depletionDelayTimer;

	private bool isDepleted = false;
	private int rocaQueda = 3;
	private const int ROCA = 3;
	private const int ROCA_INICIAL = 3;
	private const float TIEMPO_REGENERACION = 30f;
	private const float TIEMPO_AGOTARSE = 0.4f;

	[Export] public Vector2I CellSize = new Vector2I(168, 58);

	public override void _Ready()
	{
		rocasGrandes = GetNode<Node2D>("BigRocksContainer");
		rocasPequenas = GetNode<Node2D>("SmallRocksContainer");
		animExplosion = GetNode<AnimatedSprite2D>("AnimacionExplosion");
		collisionShape = GetNode<CollisionShape2D>("CollisionShape2D");

		if (collisionShape.Shape is RectangleShape2D rect)
			rect.Size = CellSize;

		collisionShape.Disabled = false;
		ZIndex = (int)Position.Y;

		SetRocasVisibles(rocasGrandes, true);
		SetRocasVisibles(rocasPequenas, false);
		animExplosion.Visible = false;

		// Conexión única del temporizador de regeneración
		regenTimer = new Timer
		{
			WaitTime = TIEMPO_REGENERACION,
			OneShot = true
		};
		AddChild(regenTimer);
		regenTimer.Timeout += OnRegenTimerTimeout;

		// Conexión única del temporizador de retraso tras agotarse
		depletionDelayTimer = new Timer
		{
			WaitTime = TIEMPO_AGOTARSE,
			OneShot = true
		};
		AddChild(depletionDelayTimer);
		depletionDelayTimer.Timeout += OnDepletionDelayTimeout;

		// **CAMBIO:** Conexión única de la señal de animación en _Ready().
		// No es necesario conectarla y desconectarla cada vez que se golpea.
		animExplosion.AnimationFinished += OnExplosionFinished;
	}

	public void Hit()
	{
		if (isDepleted)
			return;

		rocaQueda--;
		GD.Print($"Roca golpeada. Rocas restantes: {rocaQueda}");

		// Efectos visuales
		ShakeRocas();
		animExplosion.Visible = true;
		animExplosion.Play("Collect");

		// Añadir recurso
		var manager = GetNode<ResourceManager>("/root/Main/ResourceManager");
		manager.AddResource("stone", ROCA);
		GD.Print("Piedra añadida: +3");

		// Si se agotó la roca
		if (rocaQueda <= 0)
		{
			isDepleted = true;
			// Ya no necesitas volver a conectar la señal aquí
			depletionDelayTimer.Start(); // Esperar antes de mostrar las rocas pequeñas
		}
	}

	private void OnExplosionFinished()
	{
		animExplosion.Visible = false;
		// Ya no necesitas desconectar, ya que la conexión es permanente
	}

	private void OnDepletionDelayTimeout()
	{
		GD.Print("Mina de roca agotada.");

		SetRocasVisibles(rocasGrandes, false);
		SetRocasVisibles(rocasPequenas, true);

		if (collisionShape != null)
			collisionShape.Disabled = true;

		GD.Print("Regenerando en 30 segundos...");
		regenTimer.Start();
	}

	private void ShakeRocas()
	{
		var tween = CreateTween();
		foreach (var child in rocasGrandes.GetChildren())
		{
			if (child is Node2D rock)
			{
				Vector2 original = rock.Position;
				tween.TweenProperty(rock, "position:x", original.X + GD.Randf() * 4f - 2f, 0.05f);
				tween.TweenProperty(rock, "position:x", original.X, 0.05f);
			}
		}
	}

	private void OnRegenTimerTimeout()
	{
		GD.Print("Mina de roca regenerada.");
		isDepleted = false;
		rocaQueda = ROCA_INICIAL;

		SetRocasVisibles(rocasPequenas, false);
		SetRocasVisibles(rocasGrandes, true);

		if (collisionShape != null)
			collisionShape.Disabled = false;
	}

	private void SetRocasVisibles(Node2D grupo, bool visible)
	{
		foreach (var child in grupo.GetChildren())
		{
			if (child is Sprite2D node)
				node.Visible = visible;
		}
	}
}
