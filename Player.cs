using Godot;
using System;

public partial class Player : Node2D
{
	[Export] public float Speed = 200f;

	private AnimatedSprite2D animatedSprite;
	private bool isAttacking = false;

	public override void _Ready()
	{
		animatedSprite = GetNode<AnimatedSprite2D>("Animacion");
	}

	public override void _Process(double delta)
	{
		// Si estamos atacando, ignoramos movimiento y otras animaciones
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

		// Animación de movimiento
		if (inputDirection != Vector2.Zero)
		{
			if (!animatedSprite.IsPlaying() || animatedSprite.Animation != "Andar")
				animatedSprite.Play("Andar");

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

		// Animación de ataque (clic izquierdo)
		if (Input.IsActionJustPressed("ataque"))
		{
			animatedSprite.Play("Ataque1_H");
			isAttacking = true;

			// Conectar señal para saber cuándo termina la animación
			animatedSprite.AnimationFinished += OnAnimationFinished;
		}
	}

	private void OnAnimationFinished()
	{
		if (animatedSprite.Animation == "Ataque1_H")
		{
			isAttacking = false;
			// Vuelve a Idle después del ataque
			animatedSprite.Play("Idle");

			// Desconectar la señal (importante para no duplicarla)
			animatedSprite.AnimationFinished -= OnAnimationFinished;
		}
	}
}
