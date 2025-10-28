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
	private const float HIDE_TIME = 10f; // 10 segundos

	public override void _Ready()
	{
		CallDeferred(nameof(InitializeMenu));
	}

	// ----------------------------
	// INICIALIZACIÓN
	// ----------------------------
	private void InitializeMenu()
	{
		// --- Labels ---
		labels["Warrior"] = GetNodeOrNull<Label>("Soldados/Warrior/WarriorLabel");
		labels["Archer"]  = GetNodeOrNull<Label>("Soldados/Archer/ArcherLabel");
		labels["Lancer"]  = GetNodeOrNull<Label>("Soldados/Lancer/LancerLabel");
		labels["Monk"]    = GetNodeOrNull<Label>("Soldados/Monk/MonkLabel");

		foreach (var kv in labels)
			if (kv.Value == null)
				GD.PrintErr($"[MenuSoldados] Label '{kv.Key}' no encontrado");

		// --- ResourceManager ---
		resourceManager = GetNode<ResourceManager>("../ResourceManager");
		if (resourceManager == null)
			GD.PrintErr("[MenuSoldados] ResourceManager no encontrado");

		// --- Botón externo ---
		botonS = GetNodeOrNull<TextureButton>("../Objetos/BotonS");
		if (botonS != null)
			botonS.Pressed += OnBotonSPressed;

		// --- Botones de reclutamiento ---
		warriorButton = GetNodeOrNull<TextureButton>("Soldados/Warrior/ButtonW/ButtonWarrior");
		archerButton  = GetNodeOrNull<TextureButton>("Soldados/Archer/ButtonA/ButtonArcher");
		lancerButton  = GetNodeOrNull<TextureButton>("Soldados/Lancer/ButtonL/ButtonLancer");
		monkButton    = GetNodeOrNull<TextureButton>("Soldados/Monk/ButtonM/ButtonMonk");

		ConnectButtonEvents(warriorButton, "Warrior");
		ConnectButtonEvents(archerButton,  "Archer");
		ConnectButtonEvents(lancerButton,  "Lancer");
		ConnectButtonEvents(monkButton,    "Monk");

		// --- Tooltip ---
		tooltipPreview = new Panel();
		tooltipPreview.Modulate = new Color(0,0,0,0.7f);
		tooltipPreview.Visible = false;
		AddChild(tooltipPreview);

		tooltipLabel = new Label();
		tooltipLabel.AddThemeColorOverride("font_color", Colors.White);
		tooltipPreview.AddChild(tooltipLabel);

		// --- Timer ---
		hideTimer = new Timer();
		hideTimer.WaitTime = HIDE_TIME;
		hideTimer.OneShot = true;
		hideTimer.Timeout += HideMenu;
		AddChild(hideTimer);

		UpdateAllLabels();
		Visible = false; // menu empieza oculto
	}

	// ----------------------------
	// CONEXIÓN DE BOTONES
	// ----------------------------
	private void ConnectButtonEvents(TextureButton button, string type)
	{
		if (button == null) return;
		button.Pressed += () => OnRecruitPressed(type);
		button.MouseEntered += () => ShowTooltip(type);
		button.MouseExited  += HideTooltip;
	}

	// ----------------------------
	// PROCESO
	// ----------------------------
	public override void _Process(double delta)
	{
		// Tooltip sigue al ratón
		if (tooltipPreview.Visible)
		{
			Vector2 mousePos = GetViewport().GetMousePosition();
			Vector2 size = tooltipLabel.GetMinimumSize() + new Vector2(tooltipPadding*2, tooltipPadding*2);
			tooltipPreview.Size = size;
			tooltipPreview.Position = mousePos + new Vector2(12, -size.Y - 12);
		}
	}

	// ----------------------------
	// BOTON S PRESSED
	// ----------------------------
	private void OnBotonSPressed()
	{
		Visible = true;
		hideTimer.Start(); // inicia temporizador de 10s
	}

	// ----------------------------
	// RECLUTAMIENTO
	// ----------------------------
	private void OnRecruitPressed(string type)
{
	if (resourceManager == null) return;
	if (!soldierCounts.ContainsKey(type)) return;

	// Reiniciar temporizador aunque no tengas recursos
	hideTimer.Start();

	// Costes del soldado
	var costs = soldierCosts[type];

	// Comprobar si hay suficientes recursos
	bool canBuy = true;
	foreach (var res in costs)
		if (resourceManager.GetResource(res.Key) < res.Value)
			canBuy = false;

	if (!canBuy)
	{
		GD.Print($"No hay suficientes recursos para reclutar {type}");
		return;
	}

	// Restar recursos
	foreach (var res in costs)
		resourceManager.RemoveResource(res.Key, res.Value);

	// Sumar soldado
	soldierCounts[type]++;
	if (labels.ContainsKey(type) && labels[type] != null)
		labels[type].Text = soldierCounts[type].ToString();

	GD.Print($"Reclutado 1 {type}. Total = {soldierCounts[type]}");
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
			tooltipPreview.Visible = true;
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
			if (labels.ContainsKey(kv.Key) && labels[kv.Key] != null)
				labels[kv.Key].Text = kv.Value.ToString();
	}

	// ----------------------------
	// OCULTAR MENU
	// ----------------------------
	private void HideMenu()
	{
		Visible = false;
		GD.Print("MenuSoldados oculto tras temporizador");
	}
}
