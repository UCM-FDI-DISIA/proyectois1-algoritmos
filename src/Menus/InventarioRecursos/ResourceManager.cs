using Godot;
using System;

public partial class ResourceManager : Node
{
	[Signal]
	public delegate void ResourceUpdatedEventHandler(string resourceName, int newValue);
	
	// Variables para el crecimiento de aldeanos
	private int CRECIMIENTO_ALDEANOS = 0;
	private const float TIEMPO_CRECIMIENTO = 10f; // segundos 
	
	// El Timer para actualizar
	private Timer actualizarTimer;



	private Godot.Collections.Dictionary<string, int> resources = new Godot.Collections.Dictionary<string, int>
	{
		{ "wood", 0 },
		{ "villager", 0 },
		{ "stone", 0 },
		{ "gold", 0 }
	};

	public void AddResource(string resourceName, int amount = 1)
	{
		if (resources.ContainsKey(resourceName))
		{
			resources[resourceName] += amount;
			EmitSignal(nameof(ResourceUpdated), resourceName, resources[resourceName]);
		}
	}
	
	public override void _Ready()
	{
		// 1. Crea una instancia del Timer.
		actualizarTimer = new Timer();
		
		// 2. Establece el tiempo de espera.
		actualizarTimer.WaitTime = TIEMPO_CRECIMIENTO;
		
		// 3. Establece el temporizador para que se repita.
		actualizarTimer.OneShot = false; 
		
		// 4. Conecta la señal 'timeout' a un método.
		// La sintaxis 'actualizarTimer.Timeout += OnActualizarTimeout;' es la forma moderna en C#.
		actualizarTimer.Timeout += OnActualizarTimeout;
		
		// 5. Añade el Timer como hijo del ResourceManager.
		AddChild(actualizarTimer);
		
		// El temporizador se iniciará al llamar a BucleAldeanos().
	}
	
	
	/*-----------------------
	CRECIMIENTO DE POBLACIÓN
	-------------------------*/
	
	public void ActualizarAldeanos(int n)
	{
		CRECIMIENTO_ALDEANOS = n;
		// Si el valor cambia y ya estaba en marcha, reinicia el temporizador.
		if (actualizarTimer.IsStopped())
		{
			BucleAldeanos();
		}
	}
	
	// Este método se ejecutará cada vez que el temporizador se agote.
	private void OnActualizarTimeout() 
	{
		// Solo añade aldeanos si hay un crecimiento configurado.
		if (CRECIMIENTO_ALDEANOS > 0)
		{
			AddResource("villager", CRECIMIENTO_ALDEANOS);
			GD.Print($"Aldeanos actualizados. Cantidad actual: {resources["villager"]}");
		}
	}
	
	public void BucleAldeanos() 
	{
		// Inicia el temporizador. Esto es mucho más eficiente que un bucle 'while'.
		if (CRECIMIENTO_ALDEANOS > 0)
			actualizarTimer.Start();
		else
			actualizarTimer.Stop();
	}
}
