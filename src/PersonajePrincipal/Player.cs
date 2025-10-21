using Godot;
using System;

public partial class Player : CharacterBody2D
{
	[Export] public float Speed = 300f;

	private AnimatedSprite2D animatedSprite;
	private Area2D attackArea;
	private bool isAttacking = false;
	private Vector2 lastDirection = Vector2.Right;
	
	//Como el Main de Player
	public override void _Ready()
	{
		animatedSprite = GetNode<AnimatedSprite2D>("Animacion");
		//Esta es el AttackArea que determina el rango de ataque
		attackArea = GetNode<Area2D>("AttackArea");
		attackArea.Monitoring = true; // habilitar detección de cuerpos

		Position = GetViewport().GetVisibleRect().Size / 2;
		ZIndex = (int)Position.Y;
	}

	public override void _PhysicsProcess(double delta)
	{
		if (isAttacking) // si atacando, no moverse
		{
			Velocity = Vector2.Zero;
			MoveAndSlide();
			ZIndex = (int)Position.Y;
			return;
		}

		// Entrada de movimiento
		Vector2 inputDir = Vector2.Zero;
		if (Input.IsActionPressed("ui_right")) inputDir.X += 1;
		if (Input.IsActionPressed("ui_left")) inputDir.X -= 1;
		if (Input.IsActionPressed("ui_down")) inputDir.Y += 1;
		if (Input.IsActionPressed("ui_up")) inputDir.Y -= 1;

		inputDir = inputDir.Normalized();
		Velocity = inputDir * Speed;
		MoveAndSlide();

		if (inputDir != Vector2.Zero)
			lastDirection = inputDir;

		// Animaciones de movimiento
		if (inputDir != Vector2.Zero)
		{
			if (!animatedSprite.IsPlaying() || animatedSprite.Animation != "Andar")
				animatedSprite.Play("Andar");
			animatedSprite.FlipH = inputDir.X < 0;
		}
		else if (animatedSprite.Animation != "Idle")
			animatedSprite.Play("Idle");

		// Ataques
		if (Input.IsActionJustPressed("ataque")) StartAttack(1);
		if (Input.IsActionJustPressed("ataque2")) StartAttack(2);

		ZIndex = (int)Position.Y; // actualizar ZIndex
	}

	private void StartAttack(int attackNumber)
	{
		if (isAttacking) return;
		
		isAttacking = true;
		//Honestamente, ni idea
		string dirSuffix = GetDirectionSuffix(lastDirection);
		animatedSprite.Play($"Ataque{attackNumber}_{dirSuffix}");
		animatedSprite.AnimationFinished += OnAnimationFinished;

		CheckAttackHits(); // chequeo de colisiones de ataque
	}
	
	//Colisiones de ataque
	private void CheckAttackHits()
	{
		if (attackArea == null) return;

		foreach (var obj in attackArea.GetOverlappingBodies())
		{
			if (obj is ArbolAnimado arbol)
				arbol.Hit(); // notificar golpe
			// Si golpea una mina de oro
			else if (obj is MinaOroAnimado mina)
			{
				mina.Hit();
			}
			else if (obj is MinaPiedraAnimado roca)
				roca.Hit();
			//Se puede añadir para cualquier objeto de esa forma
			//En el hit actualizas el objeto
			//Y aqui o dodne mejor venga contadores y todo lo necesario
			//Implementable a futuro para enemigos y todo
		}
	}

	private string GetDirectionSuffix(Vector2 dir)
	{
		if (Mathf.Abs(dir.Y) > Mathf.Abs(dir.X))
			return dir.Y < 0 ? "W" : "S"; // arriba/abajo
		else
			return "H"; // horizontal
	}

	private void OnAnimationFinished()
	{
		if (((string)animatedSprite.Animation).StartsWith("Ataque"))
		{
			isAttacking = false;
			animatedSprite.Play("Idle");
			animatedSprite.AnimationFinished -= OnAnimationFinished;
		}
	}
}
