using Godot;
using System;

public partial class Player : CharacterBody2D
{
	[Export] public float Speed = 300f;

	private AnimatedSprite2D animatedSprite;
	private bool isAttacking = false;
	private Vector2 lastDirection = Vector2.Right;

	public override void _Ready()
	{
		animatedSprite = GetNode<AnimatedSprite2D>("Animacion");

		// Centrar personaje en pantalla al iniciar (opcional)
		Position = GetViewport().GetVisibleRect().Size / 2;
	}

	public override void _PhysicsProcess(double delta)
	{
		if (isAttacking)
		{
			Velocity = Vector2.Zero;
			MoveAndSlide();
			return;
		}

		Vector2 inputDirection = Vector2.Zero;

		if (Input.IsActionPressed("ui_right"))
			inputDirection.X += 1;
		if (Input.IsActionPressed("ui_left"))
			inputDirection.X -= 1;
		if (Input.IsActionPressed("ui_down"))
			inputDirection.Y += 1;
		if (Input.IsActionPressed("ui_up"))
			inputDirection.Y -= 1;

		inputDirection = inputDirection.Normalized();
		Velocity = inputDirection * Speed;
		MoveAndSlide();

		if (inputDirection != Vector2.Zero)
			lastDirection = inputDirection;

		// Animaciones de movimiento
		if (inputDirection != Vector2.Zero)
		{
			if (!animatedSprite.IsPlaying() || animatedSprite.Animation != "Andar")
				animatedSprite.Play("Andar");

			animatedSprite.FlipH = inputDirection.X < 0;
		}
		else
		{
			if (animatedSprite.Animation != "Idle")
				animatedSprite.Play("Idle");
		}

		// Ataques
		if (Input.IsActionJustPressed("ataque"))
			StartAttack(1);
		if (Input.IsActionJustPressed("ataque2"))
			StartAttack(2);

		// 🟢 ORDEN DE DIBUJO SEGÚN ALTURA
		ZIndex = (int)Position.Y;
	}

	private void StartAttack(int attackNumber)
	{
		if (isAttacking)
			return;

		isAttacking = true;

		string directionSuffix = GetDirectionSuffix(lastDirection);
		string animationName = $"Ataque{attackNumber}_{directionSuffix}";

		animatedSprite.Play(animationName);
		animatedSprite.AnimationFinished += OnAnimationFinished;
	}

	private string GetDirectionSuffix(Vector2 dir)
	{
		if (Mathf.Abs(dir.Y) > Mathf.Abs(dir.X))
			return dir.Y < 0 ? "W" : "S"; // W = arriba, S = abajo
		else
			return "H"; // Horizontal
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
