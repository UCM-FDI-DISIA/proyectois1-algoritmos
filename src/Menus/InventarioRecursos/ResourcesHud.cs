using Godot;
using System;

public partial class ResourcesHud : CanvasLayer
{
	private Label woodLabel;
	private Label stoneLabel;
	private Label goldLabel;
	private Label villagerLabel;

	private const int MAX_RESOURCE = 99;
	private Color normalColor = new Color(1, 1, 1); // Blanco
	private Color maxColor = new Color(1, 0, 0);   // Rojo

	public override void _Ready()
	{
		woodLabel = GetNode<Label>("HBoxContainer/WoodContainer/WoodLabel");
		stoneLabel = GetNode<Label>("HBoxContainer/StoneContainer/StoneLabel");
		goldLabel = GetNode<Label>("HBoxContainer/GoldContainer/GoldLabel");
		villagerLabel = GetNode<Label>("HBoxContainer/VillagerContainer/VillagerLabel");

		var manager = GetNode<ResourceManager>("/root/Main/ResourceManager");
		manager.ResourceUpdated += OnResourceUpdated;
	}

	private void OnResourceUpdated(string resourceName, int newValue)
	{
		// Limitar el valor a 99 antes de mostrarlo
		int clampedValue = Mathf.Min(newValue, MAX_RESOURCE);

		Label targetLabel = null;

		switch (resourceName)
		{
			case "wood":
				targetLabel = woodLabel;
				break;
			case "villager":
				targetLabel = villagerLabel;
				break;
			case "stone":
				targetLabel = stoneLabel;
				break;
			case "gold":
				targetLabel = goldLabel;
				break;
		}

		if (targetLabel != null)
		{
			targetLabel.Text = clampedValue.ToString();
			targetLabel.AddThemeColorOverride("font_color", clampedValue >= MAX_RESOURCE ? maxColor : normalColor);
		}
	}
}
