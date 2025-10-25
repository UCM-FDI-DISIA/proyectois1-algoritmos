using Godot;
using System;

public partial class SoldiersHud : CanvasLayer
{
	private Label warriorLabel;
	private Label archerLabel;
	private Label lancerLabel;
	private Label monkLabel;

	private Button buttonWarrior;
	private Button buttonArcher;
	private Button buttonLancer;
	private Button buttonMonk;

	private SoldierManager soldierManager;
	private ResourceManager resourceManager;

	public override void _Ready()
	{
		// Labels
		warriorLabel = GetNode<Label>("HBoxContainer/WarriorContainer/WarriorLabel");
		archerLabel = GetNode<Label>("HBoxContainer/ArcherContainer/ArcherLabel");
		lancerLabel = GetNode<Label>("HBoxContainer/LancerContainer/LancerLabel");
		monkLabel = GetNode<Label>("HBoxContainer/MonkContainer/MonkLabel");

		// Botones
		buttonWarrior = GetNode<Button>("HBoxContainer/WarriorContainer/ButtonWarrior");
		buttonArcher = GetNode<Button>("HBoxContainer/ArcherContainer/ButtonArcher");
		buttonLancer = GetNode<Button>("HBoxContainer/LancerContainer/ButtonLancer");
		buttonMonk = GetNode<Button>("HBoxContainer/MonkContainer/ButtonMonk");

		// Managers
		soldierManager = GetNode<SoldierManager>("/root/Main/SoldierManager");
		resourceManager = GetNode<ResourceManager>("/root/Main/ResourceManager");

		// Eventos
		soldierManager.SoldierUpdated += OnSoldierUpdated;
		resourceManager.ResourceUpdated += OnResourceChanged;

		// Botones conectados
		buttonWarrior.Pressed += () => OnButtonPressed("warrior");
		buttonArcher.Pressed += () => OnButtonPressed("archer");
		buttonLancer.Pressed += () => OnButtonPressed("lancer");
		buttonMonk.Pressed += () => OnButtonPressed("monk");

		UpdateAllLabels();
		UpdateButtonsState();
	}

	private void OnButtonPressed(string type)
	{
		soldierManager.AddSoldier(type);
		PlayButtonAnimation(type);
		UpdateButtonsState();
	}

	private void OnSoldierUpdated(string type, int newValue)
	{
		switch (type)
		{
			case "warrior": warriorLabel.Text = newValue.ToString(); break;
			case "archer": archerLabel.Text = newValue.ToString(); break;
			case "lancer": lancerLabel.Text = newValue.ToString(); break;
			case "monk": monkLabel.Text = newValue.ToString(); break;
		}
	}

	private void OnResourceChanged(string name, int newValue)
	{
		UpdateButtonsState();
	}

	private void UpdateAllLabels()
	{
		warriorLabel.Text = soldierManager.GetSoldierCount("warrior").ToString();
		archerLabel.Text = soldierManager.GetSoldierCount("archer").ToString();
		lancerLabel.Text = soldierManager.GetSoldierCount("lancer").ToString();
		monkLabel.Text = soldierManager.GetSoldierCount("monk").ToString();
	}

	private void UpdateButtonsState()
	{
		buttonWarrior.Disabled = !soldierManager.CanAfford("warrior");
		buttonArcher.Disabled = !soldierManager.CanAfford("archer");
		buttonLancer.Disabled = !soldierManager.CanAfford("lancer");
		buttonMonk.Disabled = !soldierManager.CanAfford("monk");
	}

	private void PlayButtonAnimation(string type)
	{
		Button btn = type switch
		{
			"warrior" => buttonWarrior,
			"archer" => buttonArcher,
			"lancer" => buttonLancer,
			"monk" => buttonMonk,
			_ => null
		};

		if (btn != null)
		{
			var tween = CreateTween();
			btn.Scale = new Vector2(1.2f, 1.2f);
			tween.TweenProperty(btn, "scale", Vector2.One, 0.2f)
				.SetTrans(Tween.TransitionType.Back)
				.SetEase(Tween.EaseType.Out);
		}
	}
}
