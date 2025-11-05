using Godot;
using System;
using System.Collections.Generic;

public partial class GameState : Node
{
	private static GameState _instance;

	// --- Tiempo total recolectado (si lo usas en otras partes del juego)
	private double collectedSeconds = 0;

	// --- Conteo de tropas por tipo
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
			// No eliminar al cambiar de escena
			GetTree().Root.AddChild(this);
			this.Owner = null;
			GD.Print("✅ [GameState] Inicializado y persistente entre escenas.");
		}
		else
		{
			QueueFree(); // Evita duplicados
		}
	}

	// -----------------------------
	// ⏱️ SISTEMA DE TIEMPO
	// -----------------------------
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
	// ⚔️ SISTEMA DE TROPAS
	// -----------------------------

	// 🔹 Guarda las tropas (ejemplo: se llamará desde el menú de soldados)
	public void SaveCurrentTroopsFromMenu()
	{
		GD.Print("💾 [GameState] Guardando número actual de tropas antes de batalla...");

		// ⚠️ TEMPORAL: aquí puedes poner tus valores reales desde el menú
		troopCounts["Archer"] = 3;
		troopCounts["Lancer"] = 2;
		troopCounts["Monk"] = 1;
		troopCounts["Warrior"] = 2;

		GD.Print($"🏹 Arqueros: {troopCounts["Archer"]}, ⚔️ Lancero: {troopCounts["Lancer"]}, 🧙 Monje: {troopCounts["Monk"]}, 🪓 Guerrero: {troopCounts["Warrior"]}");
	}

	// 🔹 Devuelve los conteos actuales
	public Dictionary<string, int> GetTroopCounts()
	{
		return new Dictionary<string, int>(troopCounts); // devuelve una copia segura
	}

	// 🔹 Permite modificar los conteos desde otras escenas
	public void SetTroopCount(string type, int count)
	{
		if (troopCounts.ContainsKey(type))
			troopCounts[type] = count;
	}

	public int GetTroopCount(string type)
	{
		if (troopCounts.ContainsKey(type))
			return troopCounts[type];
		return 0;
	}
	public void AddTroops(string type, int amount)
	{
		if (!troopCounts.ContainsKey(type)) return;
		troopCounts[type] = Math.Max(0, troopCounts[type] + amount);
		EmitSignal(nameof(type));
	}
	public Dictionary<string, int> GetAllTroopCounts()
	{
		// devolvemos una copia para evitar modificaciones externas directas
		return new Dictionary<string,int>(troopCounts);
	}
}
