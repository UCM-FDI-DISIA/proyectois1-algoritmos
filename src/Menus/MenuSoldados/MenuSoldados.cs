using Godot;
using System;
using System.Collections.Generic;

public partial class MenuSoldados : CanvasLayer
{
	// ----------------------------
	// LABELS Y SOLDADOS
	// ----------------------------
	private Dictionary<string, Label> labels = new();
	private Dictionary<string, int> soldierCounts = new()
	{
		{ "Warrior", 0 },
		{ "Archer", 0 },
		{ "Lancer", 0 },
		{ "Monk", 0 }
	};

	// ----------------------------
	// BOTONES
	// ----------------------------
	private TextureButton botonS;
	private TextureButton warriorButton;
	private TextureButton archerButton;
	private TextureButton lancerButton;
	private TextureButton monkButton;

	// Sprites "Mas" de cada tipo
	private Sprite2D warriorMas;
	private Sprite2D archerMas;
	private Sprite2D lancerMas;
	private Sprite2D monkMas;

	// Sprites del botón S
	private Sprite2D botonSMas;
	private Sprite2D botonSMenos;

	// ----------------------------
	// TOOLTIP
	// ----------------------------
	private Panel tooltipPreview;
	private Label tooltipLabel;
	private const int tooltipPadding = 6;

	// ----------------------------
	// RECURSOS Y COSTES
	// ----------------------------
	private ResourceManager resourceManager;
	private Dictionary<string, Dictionary<string, int>> soldierCosts = new()
	{
		{ "Warrior", new() { { "villager", 1 }, { "gold", 1 }, { "wood", 0 }, { "stone", 0 } } },
		{ "Archer",  new() { { "villager", 1 }, { "gold", 2 }, { "wood", 0 }, { "stone", 0 } } },
		{ "Lancer",  new() { { "villager", 1 }, { "gold", 3 }, { "wood", 0 }, { "stone", 0 } } },
		{ "Monk",    new() { { "villager", 1 }, { "gold", 5 }, { "wood", 0 }, { "stone", 0 } } }
	};

	// ----------------------------
	// TEMPORIZADOR VISIBILIDAD
	// ----------------------------
	private Timer hideTimer;
	private const float HIDE_TIME = 20f;

	public override void _Ready()
	{
		CallDeferred(nameof(InitializeMenu));
	}

	private void InitializeMenu()
	{
		// --- Labels ---
		labels["Warrior"] = GetNodeOrNull<Label>("Soldados/Warrior/WarriorLabel");
		labels["Archer"]  = GetNodeOrNull<Label>("Soldados/Archer/ArcherLabel");
		labels["Lancer"]  = GetNodeOrNull<Label>("Soldados/Lancer/LancerLabel");
		labels["Monk"]    = GetNodeOrNull<Label>("Soldados/Monk/MonkLabel");

		// --- ResourceManager ---
		resourceManager = GetNodeOrNull<ResourceManager>("../ResourceManager");
		if (resourceManager == null)
			GD.PrintErr("[MenuSoldados] ResourceManager no encontrado");
		else
			resourceManager.ResourceUpdated += OnResourceUpdated;

		// --- Botón externo ---
		botonS = GetNodeOrNull<TextureButton>("../ElementosPantalla/BotonS");
		if (botonS != null)
			botonS.Pressed += OnBotonSPressed;

		// Sprites del botón S
		botonSMas = botonS?.GetNodeOrNull<Sprite2D>("Mas");
		botonSMenos = botonS?.GetNodeOrNull<Sprite2D>("Menos");
		if (botonSMenos != null) botonSMenos.Visible = false;

		// --- Botones soldados ---
		warriorButton = GetNodeOrNull<TextureButton>("Soldados/Warrior/ButtonW/ButtonWarrior");
		archerButton  = GetNodeOrNull<TextureButton>("Soldados/Archer/ButtonA/ButtonArcher");
		lancerButton  = GetNodeOrNull<TextureButton>("Soldados/Lancer/ButtonL/ButtonLancer");
		monkButton    = GetNodeOrNull<TextureButton>("Soldados/Monk/ButtonM/ButtonMonk");

		// Sprites "Mas"
		warriorMas = GetNodeOrNull<Sprite2D>("Soldados/Warrior/ButtonW/Mas");
		archerMas  = GetNodeOrNull<Sprite2D>("Soldados/Archer/ButtonA/Mas");
		lancerMas  = GetNodeOrNull<Sprite2D>("Soldados/Lancer/ButtonL/Mas");
		monkMas    = GetNodeOrNull<Sprite2D>("Soldados/Monk/ButtonM/Mas");

		ConnectButtonEvents(warriorButton, "Warrior");
		ConnectButtonEvents(archerButton,  "Archer");
		ConnectButtonEvents(lancerButton,  "Lancer");
		ConnectButtonEvents(monkButton,    "Monk");

		// --- Tooltip ---
		tooltipPreview = new Panel();
		tooltipPreview.Modulate = new Color(1, 1, 1, 0.8f);
		tooltipPreview.Visible = false;
		AddChild(tooltipPreview);

		tooltipLabel = new Label();
		tooltipLabel.AddThemeColorOverride("font_color", Colors.White);
		tooltipPreview.AddChild(tooltipLabel);

		// --- Timer ---
		hideTimer = new Timer();
		hideTimer.WaitTime = HIDE_TIME;
		hideTimer.OneShot = true;
		hideTimer.Timeout += () => {
			HideMenu();
			// restaurar sprites del botón S al ocultar automáticamente
			if (botonSMas != null) botonSMas.Visible = true;
			if (botonSMenos != null) botonSMenos.Visible = false;
		};
		AddChild(hideTimer);

		UpdateAllLabels();
		Visible = false;
		UpdateButtonStates();
	}

	// ----------------------------
	// CONEXIÓN DE BOTONES
	// ----------------------------
	private void ConnectButtonEvents(TextureButton button, string type)
	{
		if (button == null) return;
		button.Pressed += () => OnRecruitPressed(type);
		button.MouseEntered += () => ShowTooltip(type);
		button.MouseExited += HideTooltip;
	}

	// ----------------------------
	// BOTÓN S PRESSED
	// ----------------------------
	private void OnBotonSPressed()
	{
		if (Visible)
		{
			HideMenu();
			hideTimer.Stop();

			// Cambiar sprites del botón S
			if (botonSMas != null) botonSMas.Visible = true;
			if (botonSMenos != null) botonSMenos.Visible = false;
		}
		else
		{
			Visible = true;
			hideTimer.Start();
			GD.Print("MenuSoldados mostrado");

			// Cambiar sprites del botón S
			if (botonSMas != null) botonSMas.Visible = false;
			if (botonSMenos != null) botonSMenos.Visible = true;
		}
	}

	// ----------------------------
	// RECURSOS ACTUALIZADOS
	// ----------------------------
	private void OnResourceUpdated(string resourceName, int newValue)
	{
		UpdateButtonStates();
	}

	// ----------------------------
	// RECLUTAMIENTO
	// ----------------------------
	private void OnRecruitPressed(string type)
	{
		if (resourceManager == null) return;
		if (!soldierCounts.ContainsKey(type)) return;

		hideTimer.Start();

		var costs = soldierCosts[type];

		// Verificar recursos
		bool canBuy = true;
		foreach (var res in costs)
			if (resourceManager.GetResource(res.Key) < res.Value)
				canBuy = false;

		if (!canBuy)
		{
			GD.Print($"No hay recursos suficientes para reclutar {type}");
			return;
		}

		// Restar recursos
		foreach (var res in costs)
			resourceManager.RemoveResource(res.Key, res.Value);

		soldierCounts[type]++;
		if (labels.ContainsKey(type))
			labels[type].Text = soldierCounts[type].ToString();

		GD.Print($"Reclutado 1 {type}. Total = {soldierCounts[type]}");

		UpdateButtonStates();
	}

	// ----------------------------
	// ACTUALIZAR ESTADO DE BOTONES
	// ----------------------------
	private void UpdateButtonStates()
	{
		foreach (var kv in soldierCosts)
		{
			string type = kv.Key;
			bool canAfford = true;

			foreach (var res in kv.Value)
			{
				if (resourceManager.GetResource(res.Key) < res.Value)
				{
					canAfford = false;
					break;
				}
			}

			TextureButton button = null;
			Sprite2D mas = null;

			switch (type)
			{
				case "Warrior": button = warriorButton; mas = warriorMas; break;
				case "Archer": button = archerButton; mas = archerMas; break;
				case "Lancer": button = lancerButton; mas = lancerMas; break;
				case "Monk": button = monkButton; mas = monkMas; break;
			}

			if (button != null)
			{
				button.Disabled = !canAfford;
				if (mas != null)
					mas.Visible = canAfford; // si no se puede pagar → Mas se oculta
			}
		}
	}

	// ----------------------------
	// TOOLTIP
	// ----------------------------
	private void ShowTooltip(string type)
	{
		if (tooltipPreview != null && tooltipLabel != null)
		{
			var cost = soldierCosts[type];
			var textParts = new List<string>();
			foreach (string r in new string[] { "wood", "stone", "gold", "villager" })
				if (cost.ContainsKey(r) && cost[r] > 0)
					textParts.Add($"{r.Capitalize()}: {cost[r]}");

			tooltipLabel.Text = string.Join("  ", textParts);

			Vector2 mousePos = GetViewport().GetMousePosition();
			Vector2 labelSize = tooltipLabel.GetMinimumSize() + new Vector2(tooltipPadding * 2, tooltipPadding * 2);
			tooltipPreview.Size = labelSize;

			Vector2 screenSize = GetViewport().GetVisibleRect().Size;
			Vector2 tooltipPos = mousePos + new Vector2(16, 16);
			if (tooltipPos.X + labelSize.X > screenSize.X)
				tooltipPos.X = screenSize.X - labelSize.X - 8;
			if (tooltipPos.Y + labelSize.Y > screenSize.Y)
				tooltipPos.Y = screenSize.Y - labelSize.Y - 8;

			tooltipPreview.Position = tooltipPos;
			tooltipPreview.Visible = true;
		}
	}

	public override void _Process(double delta)
	{
		if (tooltipPreview != null && tooltipPreview.Visible)
		{
			Vector2 mousePos = GetViewport().GetMousePosition();
			Vector2 labelSize = tooltipLabel.GetMinimumSize() + new Vector2(tooltipPadding * 2, tooltipPadding * 2);
			tooltipPreview.Size = labelSize;
			tooltipPreview.Position = mousePos + new Vector2(8, 8);
		}
	}

	private void HideTooltip()
	{
		if (tooltipPreview != null)
			tooltipPreview.Visible = false;
	}

	// ----------------------------
	// ACTUALIZAR LABELS
	// ----------------------------
	public void UpdateAllLabels()
	{
		foreach (var kv in soldierCounts)
			if (labels.ContainsKey(kv.Key))
				labels[kv.Key].Text = kv.Value.ToString();
	}

	// ----------------------------
	// OCULTAR MENU
	// ----------------------------
	private void HideMenu()
	{
		Visible = false;
		GD.Print("MenuSoldados oculto");
	}
}
