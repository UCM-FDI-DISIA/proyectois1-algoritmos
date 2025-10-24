using Godot;
using System;

public partial class ResourcesHud : CanvasLayer
{
	private Label woodLabel;
	private Label stoneLabel;
	private Label goldLabel;
	private Label villagerLabel;

	private ResourceManager manager;

	public override void _Ready()
	{
		woodLabel = GetNode<Label>("HBoxContainer/WoodContainer/WoodLabel");
		stoneLabel = GetNode<Label>("HBoxContainer/StoneContainer/StoneLabel");
		goldLabel = GetNode<Label>("HBoxContainer/GoldContainer/GoldLabel");
		villagerLabel = GetNode<Label>("HBoxContainer/VillagerContainer/VillagerLabel");

		manager = GetNode<ResourceManager>("/root/Main/ResourceManager");
		manager.ResourceUpdated += OnResourceUpdated;
		manager.VillagerCapacityUpdated += OnVillagerCapacityUpdated;

		UpdateVillagerLabel();
	}

	private void OnResourceUpdated(string resourceName, int newValue)
	{
		switch (resourceName)
		{
			case "wood":
				woodLabel.Text = newValue.ToString();
				break;
			case "stone":
				stoneLabel.Text = newValue.ToString();
				break;
			case "gold":
				goldLabel.Text = newValue.ToString();
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

	private void UpdateVillagerLabel()
	{
		int currentVillagers = manager.GetResource("villager");
		int maxVillagers = manager.GetVillagerCapacity();

		villagerLabel.Text = $"{currentVillagers} / {maxVillagers}";

		// Color: rojo si alcanza el máximo
		villagerLabel.AddThemeColorOverride("font_color",
			currentVillagers >= maxVillagers ? new Color(1, 0, 0) : new Color(1, 1, 1));
	}
}
