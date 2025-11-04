using Godot;
using System;

public partial class ResourcesHud : CanvasLayer
{
	// ----------------------------
	// LABELS DE RECURSOS
	// ----------------------------
	private Label woodLabel;
	private Label stoneLabel;
	private Label goldLabel;
	private Label villagerLabel;

	// ----------------------------
	// RECURSOS Y REFERENCIAS
	// ----------------------------
	private ResourceManager manager;
	private const int MAX_RESOURCE = 99;

	public override void _Ready()
	{
		// Referencias a las etiquetas de interfaz
		woodLabel = GetNode<Label>("HBoxContainer/WoodContainer/WoodLabel");
		stoneLabel = GetNode<Label>("HBoxContainer/StoneContainer/StoneLabel");
		goldLabel = GetNode<Label>("HBoxContainer/GoldContainer/GoldLabel");
		villagerLabel = GetNode<Label>("HBoxContainer/VillagerContainer/VillagerLabel");

		// Obtener el ResourceManager principal
		manager = GetNode<ResourceManager>("/root/Main/ResourceManager");

		// Suscribirse a las señales de actualización
		manager.ResourceUpdated += OnResourceUpdated;
		manager.VillagerCapacityUpdated += OnVillagerCapacityUpdated;

		// Inicializar los valores al iniciar la escena
		UpdateAllLabels();
	}

	// ----------------------------
	// ACTUALIZACIONES DE RECURSOS
	// ----------------------------
	private void OnResourceUpdated(string resourceName, int newValue)
	{
		switch (resourceName)
		{
			case "wood":
				UpdateResourceLabel(woodLabel, newValue);
				break;
			case "stone":
				UpdateResourceLabel(stoneLabel, newValue);
				break;
			case "gold":
				UpdateResourceLabel(goldLabel, newValue);
				break;
			case "villager":
				UpdateVillagerLabel();
				break;
		}
	}

	private void OnVillagerCapacityUpdated()
	{
		UpdateVillagerLabel();
	}

	// ----------------------------
	// ACTUALIZAR LABELS INDIVIDUALES
	// ----------------------------
	private void UpdateResourceLabel(Label label, int value)
	{
		label.Text = value.ToString();

		// Cambiar color al alcanzar el límite máximo
		label.AddThemeColorOverride(
			"font_color",
			value >= MAX_RESOURCE ? new Color(1, 0, 0) : new Color(1, 1, 1)
		);
	}

	private void UpdateVillagerLabel()
	{
		int currentVillagers = manager.GetResource("villager");
		int maxVillagers = manager.GetVillagerCapacity();

		// Mostrar formato "actual / máximo"
		villagerLabel.Text = $"{currentVillagers} / {maxVillagers}";

		// Si se alcanza el límite → texto rojo
		villagerLabel.AddThemeColorOverride(
			"font_color",
			currentVillagers >= maxVillagers ? new Color(1, 0, 0) : new Color(1, 1, 1)
		);
	}

	// ----------------------------
	// ACTUALIZAR TODOS LOS RECURSOS
	// ----------------------------
	private void UpdateAllLabels()
	{
		UpdateResourceLabel(woodLabel, manager.GetResource("wood"));
		UpdateResourceLabel(stoneLabel, manager.GetResource("stone"));
		UpdateResourceLabel(goldLabel, manager.GetResource("gold"));
		UpdateVillagerLabel();
	}
}
