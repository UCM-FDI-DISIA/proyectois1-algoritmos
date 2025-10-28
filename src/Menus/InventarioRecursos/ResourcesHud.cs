using Godot;
using System;

public partial class ResourcesHud : CanvasLayer
{
	private Label woodLabel;
	private Label stoneLabel;
	private Label goldLabel;
	private Label villagerLabel;

	private ResourceManager manager;
	private const int MAX_RESOURCE = 99;

	public override void _Ready()
	{
		woodLabel = GetNode<Label>("HBoxContainer/WoodContainer/WoodLabel");
		stoneLabel = GetNode<Label>("HBoxContainer/StoneContainer/StoneLabel");
		goldLabel = GetNode<Label>("HBoxContainer/GoldContainer/GoldLabel");
		villagerLabel = GetNode<Label>("HBoxContainer/VillagerContainer/VillagerLabel");

		manager = GetNode<ResourceManager>("/root/Main/ResourceManager");
		manager.ResourceUpdated += OnResourceUpdated;
		manager.VillagerCapacityUpdated += OnVillagerCapacityUpdated;

		UpdateAllLabels();
	}

	private void OnResourceUpdated(string resourceName, int newValue)
	{
		switch (resourceName)
		{
			case "wood": UpdateResourceLabel(woodLabel, newValue); break;
			case "stone": UpdateResourceLabel(stoneLabel, newValue); break;
			case "gold": UpdateResourceLabel(goldLabel, newValue); break;
			case "villager": UpdateVillagerLabel(); break;
		}
	}

	private void OnVillagerCapacityUpdated()
	{
		UpdateVillagerLabel();
	}

	private void UpdateResourceLabel(Label label, int value)
	{
		label.Text = value.ToString();
		label.AddThemeColorOverride("font_color", value >= MAX_RESOURCE ? new Color(1, 0, 0) : new Color(1, 1, 1));
	}

	private void UpdateVillagerLabel()
	{
		int currentVillagers = manager.GetResource("villager");
		int maxVillagers = manager.GetVillagerCapacity();

		villagerLabel.Text = $"{currentVillagers} / {maxVillagers}";
		villagerLabel.AddThemeColorOverride("font_color",
			currentVillagers >= maxVillagers ? new Color(1, 0, 0) : new Color(1, 1, 1));
	}

	private void UpdateAllLabels()
	{
		UpdateResourceLabel(woodLabel, manager.GetResource("wood"));
		UpdateResourceLabel(stoneLabel, manager.GetResource("stone"));
		UpdateResourceLabel(goldLabel, manager.GetResource("gold"));
		UpdateVillagerLabel();
	}
}
