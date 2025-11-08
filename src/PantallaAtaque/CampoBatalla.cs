using Godot;
using System;
using System.Collections.Generic;

public partial class CampoBatalla : Node2D
{
	private Node2D tropasNode;
	private GameState gameState;

	[Export] public float Spacing = 96f; // separación entre tropas
	[Export] public Vector2 TroopScale = new Vector2(3f, 3f); // tamaño de las tropas

	// tamaño aproximado del campo (en tiles o en tu sistema)
	private readonly Vector2 TileSize = new Vector2(64, 64);
	private readonly Vector2 BattlefieldTiles = new Vector2(60, 30);

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
	}

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
			}

			index++;
		}

		GD.Print("✅ Tropas del jugador instanciadas en la mitad izquierda");
	}

	private void SpawnEnemyTroops()
	{
		var troopScenes = new Dictionary<string, PackedScene>
		{
			{"Archer", (PackedScene)GD.Load("res://src/NPCs/Archer.tscn")},
			{"Lancer", (PackedScene)GD.Load("res://src/NPCs/Lancer.tscn")},
			{"Monk", (PackedScene)GD.Load("res://src/NPCs/Monk.tscn")},
			{"Warrior", (PackedScene)GD.Load("res://src/NPCs/Warrior.tscn")}
		};

		// 🟥 Mitad derecha del campo
		Vector2 battlefieldSize = BattlefieldTiles * TileSize;
		Rect2 derecha = new Rect2(battlefieldSize.X / 2, 0, battlefieldSize.X / 2, battlefieldSize.Y);

		Vector2 startPosition = derecha.Position + new Vector2(100, 100);
		int index = 0;
		Random random = new Random();

		foreach (var entry in troopScenes)
		{
			string troopName = entry.Key;

			// número aleatorio de tropas de este tipo (entre 2 y 10 por ejemplo)
			int count = random.Next(2, 10);
			var scene = entry.Value;

			for (int i = 0; i < count; i++)
			{
				Node2D troop = scene.Instantiate<Node2D>();
				troop.Scale = TroopScale;
				// Girar al enemigo para que mire hacia la izquierda
				troop.Scale = new Vector2(-TroopScale.X, TroopScale.Y);

				// formación en cuadrícula espejo (empezando desde la derecha)
				float xOffset = (i % 5) * Spacing;
				float yOffset = (index * Spacing * 1.2f) + (i / 5) * Spacing;

				// invertimos el offset X para que crezcan hacia la izquierda
				troop.Position = new Vector2(
					derecha.Position.X + derecha.Size.X - 100 - xOffset,
					startPosition.Y + yOffset
				);

				tropasNode.AddChild(troop);
			}

			index++;
		}

		GD.Print("🟥 Tropas enemigas instanciadas ordenadamente en la mitad derecha (cantidades aleatorias)");
	}
}
