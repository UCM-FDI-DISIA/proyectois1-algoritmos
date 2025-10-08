using Godot;
using System;

public partial class Player : Node2D
{
	[Export] public float Speed = 300f;

	private AnimatedSprite2D animatedSprite;
	private bool isAttacking = false;

	// Última dirección para determinar animación de ataque
	private Vector2 lastDirection = Vector2.Right;

	public override void _Ready()
	{
		animatedSprite = GetNode<AnimatedSprite2D>("Animacion");
	}

	public override void _Process(double delta)
	{
		if (isAttacking)
			return;

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

		// Movimiento
		Position += inputDirection * Speed * (float)delta;

		// Guardar dirección si hay movimiento
		if (inputDirection != Vector2.Zero)
			lastDirection = inputDirection;

		// Animación de movimiento
		if (inputDirection != Vector2.Zero)
		{
			if (!animatedSprite.IsPlaying() || animatedSprite.Animation != "Andar")
				animatedSprite.Play("Andar");

			// Flip para mirar a la izquierda o derecha
			if (inputDirection.X < 0)
				animatedSprite.FlipH = true;
			else if (inputDirection.X > 0)
				animatedSprite.FlipH = false;
		}
		else
		{
			if (animatedSprite.Animation != "Idle")
				animatedSprite.Play("Idle");
		}

		// Ataque 1: click izquierdo
		if (Input.IsActionJustPressed("ataque"))
		{
			StartAttack(1);
		}

		// Ataque 2: click derecho
		if (Input.IsActionJustPressed("ataque2"))
		{
			StartAttack(2);
		}
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
		{
			if (dir.Y < 0)
				return "W"; // Arriba
			else
				return "S"; // Abajo
		}
		else
		{
			return "H"; // Horizontal
		}
	}

	private void OnAnimationFinished()
	{
		if (animatedSprite.Animation.ToString().StartsWith("Ataque"))
		{
			isAttacking = false;
			animatedSprite.Play("Idle");
			animatedSprite.AnimationFinished -= OnAnimationFinished;
		}
	}
}
