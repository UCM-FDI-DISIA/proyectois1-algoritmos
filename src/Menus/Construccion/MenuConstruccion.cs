using Godot;
using System;

public partial class MenuConstruccion : CanvasLayer
{
	private TextureButton btnMenu;
	private PanelContainer panelBarra;
	private HBoxContainer hboxBotones;
	private TextureButton btnCasa;
	private Sprite2D marcadorCasa;

	private bool enConstruccion = false;
	private Node2D casaPreview;

	private ResourceManager resourceManager;

	private const int GRID_SIZE = 64;

	public override void _Ready()
	{
		// Buscar ResourceManager
		resourceManager = GetTree().Root.GetNode<ResourceManager>("Main/ResourceManager");
		if (resourceManager == null)
			GD.PrintErr("❌ ResourceManager no encontrado");
		else
			GD.Print("✅ ResourceManager encontrado");

		btnMenu = GetNode<TextureButton>("ControlRaiz/BtnMenu");
		panelBarra = GetNode<PanelContainer>("ControlRaiz/PanelBarra");
		hboxBotones = GetNode<HBoxContainer>("ControlRaiz/PanelBarra/HBoxBotones");
		btnCasa = GetNode<TextureButton>("ControlRaiz/PanelBarra/HBoxBotones/BtnCasa");
		marcadorCasa = GetNode<Sprite2D>("ControlRaiz/PanelBarra/HBoxBotones/BtnCasa/Marcador");

		panelBarra.MouseFilter = Control.MouseFilterEnum.Stop;
		btnCasa.MouseFilter = Control.MouseFilterEnum.Stop;

		panelBarra.Visible = false;
		marcadorCasa.Visible = false;

		// Conectar señales usando evento (más limpio en C#)
		btnMenu.Pressed += OnMenuPressed;
		btnCasa.Pressed += OnCasaPressed;
	}

	private void OnMenuPressed()
	{
		panelBarra.Visible = !panelBarra.Visible;
		if (!panelBarra.Visible)
			CancelarConstruccion();

		panelBarra.MouseFilter = panelBarra.Visible ? Control.MouseFilterEnum.Stop : Control.MouseFilterEnum.Ignore;
		GD.Print($"🖱️ Panel de construcción {(panelBarra.Visible ? "visible" : "oculto")}");
	}

	private void OnCasaPressed()
	{
		marcadorCasa.Visible = !marcadorCasa.Visible;

		if (enConstruccion)
		{
			GD.Print("⚠️ Ya estás en construcción");
			return;
		}

		if (resourceManager == null || resourceManager.casaScene == null || resourceManager.contenedorCasas == null)
		{
			GD.PrintErr("❌ Faltan asignaciones en ResourceManager (casaScene o contenedorCasas)");
			return;
		}

		enConstruccion = true;

		casaPreview = (Node2D)resourceManager.casaScene.Instantiate();

		// Hacer semi-transparente
		foreach (Node child in casaPreview.GetChildren())
		{
			if (child is CanvasItem visual)
				visual.Modulate = new Color(1, 1, 1, 0.5f);
		}

		resourceManager.contenedorCasas.AddChild(casaPreview);
		GD.Print("🏠 Preview de casa instanciado y agregado al contenedor");
	}

	public override void _Process(double delta)
	{
		if (!enConstruccion || casaPreview == null)
			return;

		Vector2 mousePos = GetViewport().GetMousePosition();
		float x = Mathf.Floor(mousePos.X / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2;
		float y = Mathf.Floor(mousePos.Y / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2;
		casaPreview.Position = new Vector2(x, y);

		if (Input.IsMouseButtonPressed(MouseButton.Right) || Input.IsKeyPressed(Key.Escape))
		{
			CancelarConstruccion();
			return;
		}

		if (Input.IsMouseButtonPressed(MouseButton.Left))
		{
			if (resourceManager.PuedoComprarCasa())
			{
				resourceManager.PagarCasa();
				resourceManager.AddHouse();

				casaPreview.Modulate = new Color(1, 1, 1, 1);
				casaPreview = null;
				enConstruccion = false;
				marcadorCasa.Visible = false;

				GD.Print("✅ Casa construida");
			}
			else
			{
				GD.Print("❌ No tienes materiales suficientes");
				CancelarConstruccion();
			}
		}
	}

	private void CancelarConstruccion()
	{
		if (casaPreview != null)
		{
			casaPreview.QueueFree();
			casaPreview = null;
		}

		enConstruccion = false;
		marcadorCasa.Visible = false;
		btnCasa.ButtonPressed = false;

		GD.Print("❌ Construcción cancelada");
	}
}
