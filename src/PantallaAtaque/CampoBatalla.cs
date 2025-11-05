using Godot;
using System;
using System.Collections.Generic;

public partial class CampoBatalla : Node2D
{
	private Node2D tropasNode; // referencia al contenedor de tropas
	private GameState gameState;

	public override void _Ready()
	{
		// Obtener referencia a GameState
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

		// Crear tropas del jugador
		SpawnTroops();
	}

	private void SpawnTroops()
	{
		Dictionary<string, int> troopCounts = gameState.GetAllTroopCounts();

		// Rutas de las escenas
		var troopScenes = new Dictionary<string, PackedScene>
		{
			{"Archer", (PackedScene)GD.Load("res://src/NPCs/Archer.tscn")},
			{"Lancer", (PackedScene)GD.Load("res://src/NPCs/Lancer.tscn")},
			{"Monk", (PackedScene)GD.Load("res://src/NPCs/Monk.tscn")},
			{"Warrior", (PackedScene)GD.Load("res://src/NPCs/Warrior.tscn")}
		};

		// 📍 Posición inicial base en la mitad del mapa
		Vector2 startPosition = GetViewportRect().Size / 2;
		float spacing = 64f; // distancia entre soldados
		int index = 0;

		foreach (var entry in troopCounts)
		{
			string troopName = entry.Key;
			int count = entry.Value;

			if (count <= 0) continue; // no hay de ese tipo

			if (!troopScenes.ContainsKey(troopName))
			{
				GD.PrintErr($"❌ No se encontró la escena de {troopName}");
				continue;
			}

			var scene = troopScenes[troopName];

			for (int i = 0; i < count; i++)
			{
				Node2D troop = scene.Instantiate<Node2D>();
				
				// Posicionar en forma de cuadrícula sin solaparse
				float xOffset = (i % 5) * spacing;
				float yOffset = (index * spacing * 1.2f) + (i / 5) * spacing;
				
				troop.Position = startPosition + new Vector2(xOffset, yOffset);
				
				tropasNode.AddChild(troop);
			}

			index++;
		}

		GD.Print("✅ Tropas instanciadas en el campo de batalla");
	}
}
