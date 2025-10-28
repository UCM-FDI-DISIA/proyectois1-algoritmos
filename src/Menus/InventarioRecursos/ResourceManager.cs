using Godot;
using System;

public partial class ResourceManager : Node
{
	[Signal] public delegate void ResourceUpdatedEventHandler(string resourceName, int newValue);
	[Signal] public delegate void VillagerCapacityUpdatedEventHandler();

	// --- Variables generales ---
	private int houseCount = 0;
	private const int VILLAGERS_PER_HOUSE = 50;

	// --- Crecimiento de aldeanos ---
	private int CRECIMIENTO_ALDEANOS = 0;
	private const float TIEMPO_CRECIMIENTO = 10f;
	private Timer actualizarTimer;

	// --- Límite máximo de recursos ---
	private const int MAX_RESOURCE = 99;

	// --- Costos de casa ---
	private const int CASA_WOOD_COST = 20;
	private const int CASA_GOLD_COST = 10;
	private const int CASA_STONE_COST = 5;

	// --- Referencias ---
	public Node2D contenedorCasas;

	// --- Diccionario de recursos ---
	private Godot.Collections.Dictionary<string, int> resources = new()
	{
		{ "wood", 0 },
		{ "stone", 0 },
		{ "gold", 0 },
		{ "villager", 0 }
	};

	// --- Escena de la casa ---
	public PackedScene casaScene;

	public override void _Ready()
	{
		// Inicializar temporizador
		actualizarTimer = new Timer
		{
			WaitTime = TIEMPO_CRECIMIENTO,
			OneShot = false
		};
		actualizarTimer.Timeout += OnActualizarTimeout;
		AddChild(actualizarTimer);

		// Cargar escena y contenedor
		casaScene = GD.Load<PackedScene>("res://src/Edificios/Casa/CasaAnimada.tscn");
		contenedorCasas = GetNode<Node2D>("Objetos/Edificios/CasasCompradas");
	}

	/*-----------------------
		MANEJO DE RECURSOS
	-------------------------*/

	public void AddResource(string name, int amount = 1)
	{
		if (!resources.ContainsKey(name)) return;

		if (name == "villager")
		{
			int maxVillagers = GetVillagerCapacity();
			resources[name] = Mathf.Min(resources[name] + amount, maxVillagers);
		}
		else
		{
			resources[name] = Mathf.Min(resources[name] + amount, MAX_RESOURCE);
		}

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

	public int GetResource(string name)
	{
		return resources.ContainsKey(name) ? resources[name] : 0;
	}

	/*-----------------------
		CASAS Y COMPRA
	-------------------------*/

	public bool PuedoComprarCasa()
	{
		return resources["wood"] >= CASA_WOOD_COST &&
			   resources["gold"] >= CASA_GOLD_COST &&
			   resources["stone"] >= CASA_STONE_COST;
	}

	public void PagarCasa()
	{
		resources["wood"] -= CASA_WOOD_COST;
		resources["gold"] -= CASA_GOLD_COST;
		resources["stone"] -= CASA_STONE_COST;

		EmitSignal(nameof(ResourceUpdated), "wood", resources["wood"]);
		EmitSignal(nameof(ResourceUpdated), "gold", resources["gold"]);
		EmitSignal(nameof(ResourceUpdated), "stone", resources["stone"]);
	}

	public void AddHouse()
	{
		houseCount++;
		EmitSignal(nameof(VillagerCapacityUpdated));
	}

	public void RemoveHouse()
	{
		houseCount = Mathf.Max(0, houseCount - 1);
		EmitSignal(nameof(VillagerCapacityUpdated));

		int maxVillagers = GetVillagerCapacity();
		if (resources["villager"] > maxVillagers)
		{
			resources["villager"] = maxVillagers;
			EmitSignal(nameof(ResourceUpdated), "villager", resources["villager"]);
		}
	}

	public int GetVillagerCapacity() => houseCount * VILLAGERS_PER_HOUSE;

	/*-----------------------
		CRECIMIENTO DE ALDEANOS
	-------------------------*/

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
