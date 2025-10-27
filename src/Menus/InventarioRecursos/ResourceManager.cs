using Godot;
using System;

public partial class ResourceManager : Node
{
	[Signal]
	public delegate void ResourceUpdatedEventHandler(string resourceName, int newValue);

	[Signal]
	public delegate void VillagerCapacityUpdatedEventHandler();

	// Variables generales
	private int houseCount = 0;
	private const int VILLAGERS_PER_HOUSE = 50;

	// Crecimiento de aldeanos
	private int CRECIMIENTO_ALDEANOS = 0;
	private const float TIEMPO_CRECIMIENTO = 10f;
	private Timer actualizarTimer;
	
	//Variables compra casa
	private const int CASA_WOOD_COST = 20;
	private const int CASA_GOLD_COST = 10;
	private const int CASA_STONE_COST = 5;

	//Referencias
	public Node2D contenedorCasas;
	// Diccionario de recursos
	private Godot.Collections.Dictionary<string, int> resources = new Godot.Collections.Dictionary<string, int>
	{
		{ "wood", 0 },
		{ "villager", 0 },
		{ "stone", 0 },
		{ "gold", 0 }
	};

	// Escena de la casa
	public PackedScene casaScene = GD.Load<PackedScene>("res://src/Edificios/Casa/CasaAnimada.tscn");

	public override void _Ready()
	{
		actualizarTimer = new Timer();
		actualizarTimer.WaitTime = TIEMPO_CRECIMIENTO;
		actualizarTimer.OneShot = false;
		actualizarTimer.Timeout += OnActualizarTimeout;
		AddChild(actualizarTimer);
		
		// Carga la escena de la casa (ajusta la ruta si es distinta)
		casaScene = GD.Load<PackedScene>("res://src/Edificios/Casa/CasaAnimada.tscn");
		// Busca el nodo contenedor donde colocar las casas
		contenedorCasas = GetNode<Node2D>("Objetos/Edificios/CasasCompradas");
		
	}

	/*-----------------------
		MANEJO DE RECURSOS
	-------------------------*/

	public void AddResource(string resourceName, int amount = 1)
	{
		if (!resources.ContainsKey(resourceName))
			return;

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
		CASAS Y COMPRA
	-------------------------*/

public void ComprarCasa(Node contenedor = null)
{
	// Comprobamos si hay materiales suficientes
	if (resources["wood"] >= CASA_WOOD_COST && resources["gold"] >= CASA_GOLD_COST && resources["stone"] >= CASA_STONE_COST)
	{
		// Restamos los recursos
		resources["wood"] -= CASA_WOOD_COST;
		resources["gold"] -= CASA_GOLD_COST;
		resources["stone"] -= CASA_STONE_COST;

		// Instanciamos la casa
		Node2D nuevaCasa = (Node2D)casaScene.Instantiate();
		nuevaCasa.Position = new Vector2(200, 200);

		// Añadimos al contenedor correspondiente
		if (contenedor != null)
			contenedor.AddChild(nuevaCasa);
		else if (contenedorCasas != null)
			contenedorCasas.AddChild(nuevaCasa);
		else
			AddChild(nuevaCasa);
	}
	else
	{
		GD.Print("❌ No tienes materiales suficientes para construir una casa.");
	}
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

	public int GetVillagerCapacity()
	{
		return houseCount * VILLAGERS_PER_HOUSE;
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

			if (current < maxVillagers)
			{
				AddResource("villager", CRECIMIENTO_ALDEANOS);
				GD.Print($"Aldeanos actualizados. Cantidad actual: {resources["villager"]}");
			}
			else
			{
				GD.Print("Capacidad máxima de aldeanos alcanzada.");
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
}
