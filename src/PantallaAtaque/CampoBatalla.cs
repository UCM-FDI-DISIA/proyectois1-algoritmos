using Godot;
using System;
using System.Collections.Generic;

public partial class CampoBatalla : Node2D
{
	private Node2D tropasNode;
	private GameState gameState;

	[Export] public float Spacing = 96f; // separación entre tropas
	[Export] public Vector2 TroopScale = new Vector2(3f, 3f); // tamaño de las tropas
	[Export] public PackedScene SmokeScene;
	[Export] public string MainScenePath = "res://src/UI/Main.tscn";
	[Export] public float TweenDuration = 3f;

	// tamaño aproximado del campo (en tiles o en tu sistema)
	private readonly Vector2 TileSize = new Vector2(64, 64);
	private readonly Vector2 BattlefieldTiles = new Vector2(60, 30);

	private List<Node2D> playerTroops = new();
	private List<Node2D> enemyTroops = new();
	private Dictionary<string, int> enemyCounts = new();

	private int tweensCompleted = 0;
	private int totalTweens = 0;

	public override void _Ready()
	{
		gameState = GetNode<GameState>("/root/GameState");
		tropasNode = GetNode<Node2D>("Objetos/Tropas");

		if (gameState == null)
		{
			GD.PrintErr("❌ No se encontró GameState");
			return;
		}

		if (tropasNode == null)
		{
			GD.PrintErr("❌ No se encontró Tropas dentro de Objetos");
			return;
		}

		SpawnPlayerTroops();
		SpawnEnemyTroops();
		StartBattleCountdown();
	}

	// ------------------ SPAWN JUGADOR ------------------
	private void SpawnPlayerTroops()
	{
		Dictionary<string, int> troopCounts = gameState.GetAllTroopCounts();

		var troopScenes = new Dictionary<string, PackedScene>
		{
			{"Archer", (PackedScene)GD.Load("res://src/NPCs/Archer.tscn")},
			{"Lancer", (PackedScene)GD.Load("res://src/NPCs/Lancer.tscn")},
			{"Monk", (PackedScene)GD.Load("res://src/NPCs/Monk.tscn")},
			{"Warrior", (PackedScene)GD.Load("res://src/NPCs/Warrior.tscn")}
		};

		// ⚔️ Mitad izquierda del campo
		Vector2 battlefieldSize = BattlefieldTiles * TileSize;
		Rect2 izquierda = new Rect2(0, 0, battlefieldSize.X / 2, battlefieldSize.Y);

		Vector2 startPosition = izquierda.Position + new Vector2(100, 100);
		int index = 0;

		foreach (var entry in troopCounts)
		{
			string troopName = entry.Key;
			int count = entry.Value;
			if (count <= 0) continue;
			if (!troopScenes.ContainsKey(troopName)) continue;

			var scene = troopScenes[troopName];

			for (int i = 0; i < count; i++)
			{
				Node2D troop = scene.Instantiate<Node2D>();
				troop.Scale = TroopScale;

				// misma formación cuadrícula
				float xOffset = (i % 5) * Spacing;
				float yOffset = (index * Spacing * 1.2f) + (i / 5) * Spacing;

				troop.Position = startPosition + new Vector2(xOffset, yOffset);
				tropasNode.AddChild(troop);
				playerTroops.Add(troop);
			}

			index++;
		}

		GD.Print("✅ Tropas del jugador instanciadas en la mitad izquierda");
	}

	// ------------------ SPAWN ENEMIGO ------------------
	private void SpawnEnemyTroops()
	{
		var troopScenes = new Dictionary<string, PackedScene>
		{
			{"Archer", (PackedScene)GD.Load("res://src/NPCs/Archer.tscn")},
			{"Lancer", (PackedScene)GD.Load("res://src/NPCs/Lancer.tscn")},
			{"Monk", (PackedScene)GD.Load("res://src/NPCs/Monk.tscn")},
			{"Warrior", (PackedScene)GD.Load("res://src/NPCs/Warrior.tscn")}
		};

		Vector2 battlefieldSize = BattlefieldTiles * TileSize;
		Rect2 derecha = new Rect2(battlefieldSize.X / 2, 0, battlefieldSize.X / 2, battlefieldSize.Y);

		Vector2 startPosition = derecha.Position + new Vector2(100, 100);
		int index = 0;
		Random random = new Random();

		foreach (var entry in troopScenes)
		{
			string troopName = entry.Key;
			int count = random.Next(2, 10);
			enemyCounts[troopName] = count;

			var scene = entry.Value;

			for (int i = 0; i < count; i++)
			{
				Node2D troop = scene.Instantiate<Node2D>();
				// Mirroring horizontal para mirar a la izquierda
				troop.Scale = new Vector2(-TroopScale.X, TroopScale.Y);

				float xOffset = (i % 5) * Spacing;
				float yOffset = (index * Spacing * 1.2f) + (i / 5) * Spacing;

				troop.Position = new Vector2(
					derecha.Position.X + derecha.Size.X - 100 - xOffset,
					startPosition.Y + yOffset
				);

				tropasNode.AddChild(troop);
				enemyTroops.Add(troop);
			}

			index++;
		}

		GD.Print("🟥 Tropas enemigas instanciadas en la mitad derecha (cantidades aleatorias)");
	}

	// ------------------ CUENTA ATRÁS ------------------
	private async void StartBattleCountdown()
	{
		GD.Print("⏱️ Cuenta atrás iniciada...");

		CanvasLayer canvas = new CanvasLayer();
		AddChild(canvas);

		Label label = new Label();
		label.HorizontalAlignment = HorizontalAlignment.Center;
		label.VerticalAlignment = VerticalAlignment.Center;
		label.AddThemeFontSizeOverride("font_size", 64);
		label.AddThemeColorOverride("font_color", Colors.White);
		canvas.AddChild(label);

		Vector2 screenCenter = GetViewportRect().Size / 2;
		label.Position = screenCenter;

		for (int i = 3; i > 0; i--)
		{
			label.Text = i.ToString();
			GD.Print($"   ⏳ {i}...");
			await ToSignal(GetTree().CreateTimer(1f), SceneTreeTimer.SignalName.Timeout);
		}

		label.Text = "¡BATALLA!";
		GD.Print("🔥 Batalla comienza!");
		await ToSignal(GetTree().CreateTimer(1f), SceneTreeTimer.SignalName.Timeout);
		label.QueueFree();

		StartBattle();
	}

	// ------------------ AVANCE AL CENTRO ------------------
	private void StartBattle()
	{
		GD.Print("🏃 Tropas avanzando hacia el centro...");

		float centerX = (BattlefieldTiles.X * TileSize.X) / 2;
		totalTweens = playerTroops.Count + enemyTroops.Count;
		tweensCompleted = 0;

		foreach (var troop in playerTroops)
			TweenTroop(troop, centerX - 50);

		foreach (var troop in enemyTroops)
			TweenTroop(troop, centerX + 50);
	}

	private void TweenTroop(Node2D troop, float targetX)
	{
		var tween = CreateTween();
		tween.TweenProperty(troop, "position:x", targetX, TweenDuration)
			 .SetTrans(Tween.TransitionType.Linear)
			 .SetEase(Tween.EaseType.InOut);

		tween.Finished += () =>
		{
			tweensCompleted++;
			if (tweensCompleted >= totalTweens)
				TriggerCentralExplosion();
		};
	}

	// ------------------ HUMO CENTRAL ------------------
	private async void TriggerCentralExplosion()
	{
		GD.Print("💥 Tropas llegan al centro. Explosión de humo.");

		Vector2 center = new Vector2(BattlefieldTiles.X * TileSize.X / 2, BattlefieldTiles.Y * TileSize.Y / 2);

		if (SmokeScene != null)
		{
			Node2D smoke = SmokeScene.Instantiate<Node2D>();
			smoke.Position = center;
			smoke.Scale = new Vector2(5f, 5f);
			tropasNode.AddChild(smoke);
		}

		foreach (var t in playerTroops) t.Visible = false;
		foreach (var t in enemyTroops) t.Visible = false;

		await ToSignal(GetTree().CreateTimer(2f), SceneTreeTimer.SignalName.Timeout);

		ShowBattleResult();
	}

	// ------------------ RESULTADO ------------------
	private async void ShowBattleResult()
	{
		GD.Print("📊 Calculando resultado...");

		var weights = new Dictionary<string, int>
		{
			{ "Archer", 1 },
			{ "Lancer", 2 },
			{ "Monk", 3 },
			{ "Warrior", 4 }
		};

		int playerPower = 0;
		foreach (var kvp in gameState.GetAllTroopCounts())
			if (weights.ContainsKey(kvp.Key))
				playerPower += kvp.Value * weights[kvp.Key];

		int enemyPower = 0;
		foreach (var kvp in enemyCounts)
			if (weights.ContainsKey(kvp.Key))
				enemyPower += kvp.Value * weights[kvp.Key];

		string resultText = playerPower > enemyPower
			? $"🏆 ¡Gana el Jugador!"
			: playerPower < enemyPower
				? $"💀 ¡Gana el Enemigo!"
				: $"⚖️ ¡Empate!";

		GD.Print($"📣 Resultado → {resultText}");

		CanvasLayer canvas = new CanvasLayer();
		AddChild(canvas);

		Label result = new Label
		{	
			Text = resultText,
			HorizontalAlignment = HorizontalAlignment.Left,
			VerticalAlignment = VerticalAlignment.Top
		};
		result.AddThemeFontSizeOverride("font_size", 24); // tamaño más pequeño
		result.AddThemeColorOverride("font_color", Colors.White);
		canvas.AddChild(result);
		result.Position = new Vector2(20, 20); // esquina superior izquierda con un pequeño margen

		

		await ToSignal(GetTree().CreateTimer(2f), SceneTreeTimer.SignalName.Timeout);

		// Fade a negro completo
		ColorRect fade = new ColorRect();
		fade.Color = new Color(0, 0, 0, 0);
		fade.Size = GetViewportRect().Size; 
		fade.Position = Vector2.Zero;
		fade.ZIndex = 100;
		canvas.AddChild(fade);

		var fadeTween = CreateTween();
		fadeTween.TweenProperty(fade, "color:a", 1f, 2f)
				 .SetEase(Tween.EaseType.InOut)
				 .SetTrans(Tween.TransitionType.Linear);

		await ToSignal(fadeTween, "finished");

		GD.Print("📂 Cargando escena principal...");
		GetTree().ChangeSceneToFile(MainScenePath);
	}
}
