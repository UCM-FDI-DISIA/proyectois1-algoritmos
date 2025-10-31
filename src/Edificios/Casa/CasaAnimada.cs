using Godot;
using System;

public partial class CasaAnimada : Node2D
{
	private const int CRECIMIENTO_POR_CASA = 2;
	public bool EsPreview = false;

	public override void _Ready()
	{
		// Si es preview, no ejecutar lógica de crecimiento
		if (EsPreview)
			return;

		var manager = GetNode<ResourceManager>("/root/Main/ResourceManager");

		manager.AddHouse(); // ✅ Se suma una sola vez
		manager.ActualizarAldeanos(CRECIMIENTO_POR_CASA * manager.GetHouseCount());

		GD.Print($"[Casa] Construida nueva casa. Total casas: {manager.GetHouseCount()}");
	}

	public override void _ExitTree()
	{
		if (EsPreview)
			return;

		var manager = GetNode<ResourceManager>("/root/Main/ResourceManager");
		manager.RemoveHouse();
		manager.ActualizarAldeanos(CRECIMIENTO_POR_CASA * manager.GetHouseCount());

		GD.Print($"[Casa] Se ha destruido una casa. Total casas: {manager.GetHouseCount()}");
	}
}
