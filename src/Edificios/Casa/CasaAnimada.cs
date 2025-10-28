using Godot;
using System;

public partial class CasaAnimada : Node2D
{
	public static int numCasas = 0;
	private const int CRECIMIENTO_POR_CASA = 2;

	// 🚧 Nueva variable para distinguir previews
	public bool EsPreview = false;

	public override void _Ready()
	{
		// Si es preview, no ejecutar lógica de crecimiento
		if (EsPreview)
			return;

		numCasas++;

		var manager = GetNode<ResourceManager>("/root/Main/ResourceManager");

		manager.AddHouse();
		manager.ActualizarAldeanos(CRECIMIENTO_POR_CASA * numCasas);

		GD.Print($"[Casa] Construida nueva casa. Total casas: {numCasas}");
		GD.Print($"[Casa] Crecimiento actual de aldeanos: +{CRECIMIENTO_POR_CASA * numCasas} por ciclo");
	}

	public override void _ExitTree()
	{
		// Si es preview, no restar tampoco
		if (EsPreview)
			return;

		numCasas = Math.Max(0, numCasas - 1);

		var manager = GetNode<ResourceManager>("/root/Main/ResourceManager");
		manager.RemoveHouse();
		manager.ActualizarAldeanos(CRECIMIENTO_POR_CASA * numCasas);

		GD.Print($"[Casa] Se ha destruido una casa. Total casas: {numCasas}");
		GD.Print($"[Casa] Crecimiento actualizado: +{CRECIMIENTO_POR_CASA * numCasas} por ciclo");
	}
}
