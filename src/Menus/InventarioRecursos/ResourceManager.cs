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

	// --- Referencias asignables en Inspector ---
	[Export] public Node2D contenedorCasas;   // Nodo donde se agregarán las casas
	[Export] public PackedScene casaScene;    // Escena de la casa

	// --- Diccionario de recursos ---
	private Godot.Collections.Dictionary<string, int> resources = new()
	{
		{ "wood", 0 },
		{ "stone", 0 },
		{ "gold", 0 },
		{ "villager", 0 }
	};

	public override void _Ready()
	{
		GD.Print("[ResourceManager] Iniciando...");

		// Revisar si las referencias fueron asignadas en el Inspector
		if (contenedorCasas == null)
			GD.PrintErr("❌ ContenedorCasas no asignado en ResourceManager. Arrastra CasasCompradas en el Inspector.");
		if (casaScene == null)
			GD.PrintErr("❌ casaScene no asignada en ResourceManager. Arrastra CasaAnimada.tscn en el Inspector.");

		// Inicializar temporizador
		actualizarTimer = new Timer
		{
			WaitTime = TIEMPO_CRECIMIENTO,
			OneShot = false
		};
		actualizarTimer.Timeout += OnActualizarTimeout;
		AddChild(actualizarTimer);

		GD.Print("[ResourceManager] ResourceManager listo.");
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
		GD.Print($"[ResourceManager] Recurso {name} actualizado: {resources[name]}");
	}

	public bool RemoveResource(string name, int amount)
	{
		if (!resources.ContainsKey(name) || resources[name] < amount)
			return false;

		resources[name] -= amount;
		EmitSignal(nameof(ResourceUpdated), name, resources[name]);
		GD.Print($"[ResourceManager] Recurso {name} reducido a: {resources[name]}");
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

		GD.Print("[ResourceManager] Casa pagada. Recursos descontados.");
	}

	public void AddHouse()
	{
		houseCount++;
		EmitSignal(nameof(VillagerCapacityUpdated));
		GD.Print($"[ResourceManager] Nueva casa añadida. Total casas: {houseCount}");
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

		GD.Print($"[ResourceManager] Casa eliminada. Total casas: {houseCount}");
	}

	public int GetVillagerCapacity() => houseCount * VILLAGERS_PER_HOUSE;

	/*-----------------------
		CRECIMIENTO DE ALDEANOS
	-------------------------*/

	public void ActualizarAldeanos(int n)
	{
		CRECIMIENTO_ALDEANOS = n;
		GD.Print($"[ResourceManager] ActualizarAldeanos llamado. Crecimiento por ciclo: {CRECIMIENTO_ALDEANOS}");
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
