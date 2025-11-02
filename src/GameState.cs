using Godot;
using System;

public partial class GameState : Node
{
	private double collectedSeconds = 0;
	private Timer collectionTimer;

	[Signal] public delegate void CollectedTimeChangedEventHandler(double seconds);

	public override void _Ready()
	{
		collectionTimer = new Timer();
		collectionTimer.WaitTime = 1.0; // cada segundo
		collectionTimer.OneShot = false;
		collectionTimer.Timeout += OnTimerTimeout;
		AddChild(collectionTimer);
		collectionTimer.Start(); // ⏰ comienza automáticamente al iniciar el juego
	}

	private void OnTimerTimeout()
	{
		collectedSeconds += 1.0;
		EmitSignal(nameof(CollectedTimeChanged), collectedSeconds);
		GD.Print($"Tiempo recolectado: {collectedSeconds}");
	}

	public double GetCollectedSeconds()
	{
		return collectedSeconds;
	}

	public void ResetCollectedTime()
	{
		collectedSeconds = 0;
		EmitSignal(nameof(CollectedTimeChanged), collectedSeconds);
	}
}
