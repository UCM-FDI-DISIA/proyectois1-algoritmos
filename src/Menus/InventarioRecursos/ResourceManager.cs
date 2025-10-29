using Godot;
using System;

public partial class ResourceManager : Node
{
	[Signal] public delegate void ResourceUpdatedEventHandler(string resourceName, int newValue);
	[Signal] public delegate void VillagerCapacityUpdatedEventHandler();

	private int houseCount = 0;
	private const int VILLAGERS_PER_HOUSE = 50;

	private int CRECIMIENTO_ALDEANOS = 0;
	private const float TIEMPO_CRECIMIENTO = 10f;
	private Timer actualizarTimer;

	private const int MAX_RESOURCE = 99;

	private const int CASA_WOOD_COST = 20;
	private const int CASA_GOLD_COST = 10;
	private const int CASA_STONE_COST = 5;

	[Export] public Node2D contenedorCasas;
	[Export] public PackedScene casaScene;

	private Godot.Collections.Dictionary<string, int> resources = new()
	{
		{ "wood", 0 },
		{ "stone", 0 },
		{ "gold", 0 },
		{ "villager", 0 }
	};

	public int GetCasaWoodCost() => CASA_WOOD_COST;
	public int GetCasaGoldCost() => CASA_GOLD_COST;
	public int GetCasaStoneCost() => CASA_STONE_COST;

	public override void _Ready()
	{
		GD.Print("[ResourceManager] Iniciando...");

		if (contenedorCasas == null)
			GD.PrintErr("contenedorCasas no asignado.");
		if (casaScene == null)
			GD.PrintErr("casaScene no asignada.");

		actualizarTimer = new Timer { WaitTime = TIEMPO_CRECIMIENTO, OneShot = false };
		actualizarTimer.Timeout += OnActualizarTimeout;
		AddChild(actualizarTimer);
	}

	// --- Recursos ---
	public void AddResource(string name, int amount = 1)
	{
		if (!resources.ContainsKey(name)) return;

		if (name == "villager")
			resources[name] = Mathf.Min(resources[name] + amount, GetVillagerCapacity());
		else
			resources[name] = Mathf.Min(resources[name] + amount, MAX_RESOURCE);

		EmitSignal(nameof(ResourceUpdated), name, resources[name]);
	}

	public bool RemoveResource(string name, int amount)
	{
		if (!resources.ContainsKey(name) || resources[name] < amount)
			return false;

		resources[name] -= amount;
		EmitSignal(nameof(ResourceUpdated), name, resources[name]);
		return true;
	}

	public int GetResource(string name) =>
		resources.ContainsKey(name) ? resources[name] : 0;

	// --- Casas ---
	public bool PuedoComprarCasa() =>
		resources["wood"] >= CASA_WOOD_COST &&
		resources["gold"] >= CASA_GOLD_COST &&
		resources["stone"] >= CASA_STONE_COST;

	public void PagarCasa()
	{
		RemoveResource("wood", CASA_WOOD_COST);
		RemoveResource("gold", CASA_GOLD_COST);
		RemoveResource("stone", CASA_STONE_COST);
	}

	public void AddHouse()
	{
		houseCount++;
		EmitSignal(nameof(VillagerCapacityUpdated));
	}

	public void RemoveHouse()
	{
		houseCount = Math.Max(0, houseCount - 1);
		EmitSignal(nameof(VillagerCapacityUpdated));
	}

	public int GetVillagerCapacity() => houseCount * VILLAGERS_PER_HOUSE;
	public int GetHouseCount() => houseCount;

	// --- Aldeanos ---
	public void ActualizarAldeanos(int n)
	{
		CRECIMIENTO_ALDEANOS = n;
		if (actualizarTimer.IsStopped())
			BucleAldeanos();
	}

	private void OnActualizarTimeout()
	{
		if (CRECIMIENTO_ALDEANOS > 0)
		{
			int current = resources["villager"];
			int maxVillagers = GetVillagerCapacity();

			if (current < maxVillagers)
				AddResource("villager", CRECIMIENTO_ALDEANOS);
		}
	}

	public void BucleAldeanos()
	{
		if (CRECIMIENTO_ALDEANOS > 0)
			actualizarTimer.Start();
		else
			actualizarTimer.Stop();
	}
}
