using Godot;
using System;

public partial class ResourceManager : Node
{
	[Signal]
	public delegate void ResourceUpdatedEventHandler(string resourceName, int newValue);

	[Signal]
	public delegate void VillagerCapacityUpdatedEventHandler(); // Nueva señal para el HUD

	// Variables para el crecimiento de aldeanos
	private int CRECIMIENTO_ALDEANOS = 0;
	private const float TIEMPO_CRECIMIENTO = 10f; // segundos 
	private Timer actualizarTimer;

	// Diccionario de recursos
	private Godot.Collections.Dictionary<string, int> resources = new Godot.Collections.Dictionary<string, int>
	{
		{ "wood", 0 },
		{ "villager", 0 },
		{ "stone", 0 },
		{ "gold", 0 }
	};

	// Control de casas
	private int houseCount = 0;
	private const int VILLAGERS_PER_HOUSE = 50;

	public override void _Ready()
	{
		// Crear e inicializar el Timer
		actualizarTimer = new Timer();
		actualizarTimer.WaitTime = TIEMPO_CRECIMIENTO;
		actualizarTimer.OneShot = false;
		actualizarTimer.Timeout += OnActualizarTimeout;
		AddChild(actualizarTimer);
	}

	/*-----------------------
		MANEJO DE RECURSOS
	-------------------------*/

	public void AddResource(string resourceName, int amount = 1)
	{
		if (!resources.ContainsKey(resourceName))
			return;

		// Si el recurso es villager, aplicamos el límite de capacidad
		if (resourceName == "villager")
		{
			int maxVillagers = GetVillagerCapacity();
			int newValue = Mathf.Min(resources["villager"] + amount, maxVillagers);
			resources["villager"] = newValue;
		}
		else
		{
			resources[resourceName] += amount;
		}

		EmitSignal(nameof(ResourceUpdated), resourceName, resources[resourceName]);
	}

	public void SetResource(string resourceName, int value)
	{
		if (!resources.ContainsKey(resourceName))
			return;

		// También limitamos a la capacidad máxima
		if (resourceName == "villager")
			value = Mathf.Min(value, GetVillagerCapacity());

		resources[resourceName] = value;
		EmitSignal(nameof(ResourceUpdated), resourceName, resources[resourceName]);
	}

	public int GetResource(string resourceName)
	{
		return resources.ContainsKey(resourceName) ? resources[resourceName] : 0;
	}
	
	public bool RemoveResource(string name, int amount)
{
	if (!resources.ContainsKey(name) || resources[name] < amount)
		return false;

	resources[name] -= amount;
	return true;
}

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

			//  No seguir creciendo si ya está lleno
			if (current < maxVillagers)
			{
				AddResource("villager", CRECIMIENTO_ALDEANOS);
				GD.Print($"Aldeanos actualizados. Cantidad actual: {resources["villager"]}");
			}
			else
			{
				GD.Print("Capacidad máxima de aldeanos alcanzada. No se añaden más.");
			}
		}
	}

	public void BucleAldeanos()
	{
		if (CRECIMIENTO_ALDEANOS > 0)
			actualizarTimer.Start();
		else
			actualizarTimer.Stop();
	}

	/*-----------------------
		CASAS Y CAPACIDAD
	-------------------------*/

	public void AddHouse()
	{
		houseCount++;
		EmitSignal(nameof(VillagerCapacityUpdated));
	}

	public void RemoveHouse()
	{
		houseCount = Mathf.Max(0, houseCount - 1);
		EmitSignal(nameof(VillagerCapacityUpdated));

		// ⚠️ Si hay más villagers que capacidad, ajustar
		int maxVillagers = GetVillagerCapacity();
		if (resources["villager"] > maxVillagers)
		{
			resources["villager"] = maxVillagers;
			EmitSignal(nameof(ResourceUpdated), "villager", resources["villager"]);
		}
	}

	public int GetVillagerCapacity()
	{
		return houseCount * VILLAGERS_PER_HOUSE;
	}
}
