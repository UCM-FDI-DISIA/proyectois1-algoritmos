using Godot;
using System;
using System.Collections.Generic;

public partial class GameState : Node
{
	private static GameState _instance;

	private double collectedSeconds = 0;

	private Dictionary<string, int> troopCounts = new Dictionary<string, int>()
	{
		{ "Archer", 0 },
		{ "Lancer", 0 },
		{ "Monk", 0 },
		{ "Warrior", 0 }
	};

	[Signal]
	public delegate void CollectedTimeChangedEventHandler(double seconds);

	public static GameState GetInstance()
{
	if (_instance == null)
	{
		_instance = new GameState();
	}
	return _instance;
}

	public override void _Ready()
	{
		if (_instance == null)
		{
			_instance = this;
			GetTree().Root.AddChild(this);
			this.Owner = null;
			GD.Print("✅ [GameState] Inicializado y persistente entre escenas.");
		}
		else
		{
			QueueFree();
		}
	}

	private Timer collectionTimer;

	public void StartTimer()
	{
		if (collectionTimer != null) return;

		collectionTimer = new Timer();
		collectionTimer.WaitTime = 1.0;
		collectionTimer.OneShot = false;
		collectionTimer.Timeout += OnTimerTimeout;
		AddChild(collectionTimer);
		collectionTimer.Start();
	}

	private void OnTimerTimeout()
	{
		collectedSeconds += 1.0;
		EmitSignal(nameof(CollectedTimeChanged), collectedSeconds);
		GD.Print($"[GameState] Tiempo recolectado: {collectedSeconds}");
	}

	public double GetCollectedSeconds() => collectedSeconds;

	public void ResetCollectedTime()
	{
		collectedSeconds = 0;
		EmitSignal(nameof(CollectedTimeChanged), collectedSeconds);
	}

	// -----------------------------
	// TROPAS
	// -----------------------------
	public void SetTroopCount(string type, int count)
	{
		if (!troopCounts.ContainsKey(type)) return;
		troopCounts[type] = Math.Max(0, count);
	}

	public int GetTroopCount(string type)
	{
		if (troopCounts.ContainsKey(type)) return troopCounts[type];
		return 0;
	}

	public Dictionary<string, int> GetAllTroopCounts()
	{
		return new Dictionary<string,int>(troopCounts);
	}
	public void AddTroops(string type, int amount) { 
		if (!troopCounts.ContainsKey(type)) return; 
		troopCounts[type] = Math.Max(0, troopCounts[type] + amount); 
		EmitSignal(nameof(type)); 
		}
}
