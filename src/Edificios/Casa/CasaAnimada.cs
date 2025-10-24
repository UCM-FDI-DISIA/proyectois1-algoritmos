using Godot;
using System;

public partial class CasaAnimada : Node2D
{
	public static int numCasas = 0;

	// Cuántos aldeanos nuevos produce cada casa por ciclo de crecimiento
	private const int CRECIMIENTO_POR_CASA = 2;

	public override void _Ready()
	{
		numCasas++;

		var manager = GetNode<ResourceManager>("/root/Main/ResourceManager");

		//Notificamos al ResourceManager que hay una nueva casa
		manager.AddHouse();

		//Ajustamos el ritmo de crecimiento global en función de cuántas casas hay
		manager.ActualizarAldeanos(CRECIMIENTO_POR_CASA * numCasas);

		GD.Print($"[Casa] Construida nueva casa. Total casas: {numCasas}");
		GD.Print($"[Casa] Crecimiento actual de aldeanos: +{CRECIMIENTO_POR_CASA * numCasas} por ciclo");
	}

	public override void _ExitTree()
	{
		// Cuando se elimina la casa del árbol, se reduce el número de casas
		numCasas = Math.Max(0, numCasas - 1);

		var manager = GetNode<ResourceManager>("/root/Main/ResourceManager");
		manager.RemoveHouse();

		// Recalcular el crecimiento según las casas restantes
		manager.ActualizarAldeanos(CRECIMIENTO_POR_CASA * numCasas);

		GD.Print($"[Casa] Se ha destruido una casa. Total casas: {numCasas}");
		GD.Print($"[Casa] Crecimiento actualizado: +{CRECIMIENTO_POR_CASA * numCasas} por ciclo");
	}
}
