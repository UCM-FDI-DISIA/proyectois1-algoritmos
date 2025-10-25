using Godot;
using System;
using System.Collections.Generic;

public partial class SoldierManager : Node
{
	private Dictionary<string, int> soldiers = new();

	public event Action<string, int> SoldierUpdated;

	private ResourceManager resourceManager;

	// Costes de cada tipo de soldado
	private Dictionary<string, Dictionary<string, int>> costs = new()
	{
		{ "warrior", new() { { "villager", 3 }, { "gold", 3 }, { "stone", 3 } } },
		{ "archer", new() { { "villager", 1 }, { "wood", 10 } } },
		{ "lancer", new() { { "villager", 1 }, { "wood", 3 }, { "stone", 5 } } },
		{ "monk", new() { { "villager", 3 }, { "gold", 5 } } }
	};

	public override void _Ready()
	{
		soldiers["warrior"] = 0;
		soldiers["archer"] = 0;
		soldiers["lancer"] = 0;
		soldiers["monk"] = 0;

		resourceManager = GetNode<ResourceManager>("/root/Main/ResourceManager");
	}

	public bool CanAfford(string type)
	{
		if (!costs.ContainsKey(type)) return false;

		foreach (var cost in costs[type])
		{
			if (resourceManager.GetResource(cost.Key) < cost.Value)
				return false;
		}
		return true;
	}

	public void AddSoldier(string type)
	{
		if (!CanAfford(type))
		{
			GD.Print($"No hay suficientes recursos para crear {type}");
			return;
		}

		// Restar recursos
		foreach (var cost in costs[type])
			resourceManager.RemoveResource(cost.Key, -cost.Value);

		// Sumar soldado
		soldiers[type]++;
		SoldierUpdated?.Invoke(type, soldiers[type]);
		GD.Print($"Se ha creado un {type}. Total: {soldiers[type]}");
	}

	public int GetSoldierCount(string type)
	{
		return soldiers.TryGetValue(type, out int count) ? count : 0;
	}
}
