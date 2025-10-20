using Godot;
using System;

public partial class ResourcesHud : CanvasLayer
{
	private Label woodLabel;
	private Label stoneLabel;
	private Label goldLabel;
	private Label villagerLabel;

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
				villagerLabel.Text = newValue.ToString();
				break;
		}
	}
}
