using Godot;
using System;
using System.Collections.Generic;

public partial class GameState : Node
{
	/*
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
	*/
[Signal] public delegate void TroopCountsChangedEventHandler();

	private Dictionary<string, int> troopCounts = new Dictionary<string, int>()
	{
		{ "Archer", 0 },
		{ "Lancer", 0 },
		{ "Monk", 0 },
		{ "Warrior", 0 }
	};

	public override void _Ready()
	{
		GD.Print("GameState listo");
	}

	public void SetTroopCount(string type, int count)
	{
		if (!troopCounts.ContainsKey(type)) return;
		troopCounts[type] = Math.Max(0, count);
		EmitSignal(nameof(TroopCountsChanged));
	}

	public void AddTroops(string type, int amount)
	{
		if (!troopCounts.ContainsKey(type)) return;
		troopCounts[type] = Math.Max(0, troopCounts[type] + amount);
		EmitSignal(nameof(TroopCountsChanged));
	}

	public int GetTroopCount(string type)
	{
		return troopCounts.ContainsKey(type) ? troopCounts[type] : 0;
	}

	public Dictionary<string, int> GetAllTroopCounts()
	{
		// devolvemos una copia para evitar modificaciones externas directas
		return new Dictionary<string,int>(troopCounts);
	}

	public void ResetTroops()
	{
		foreach (var k in new List<string>(troopCounts.Keys))
			troopCounts[k] = 0;
		EmitSignal(nameof(TroopCountsChanged));
	}
	
}
