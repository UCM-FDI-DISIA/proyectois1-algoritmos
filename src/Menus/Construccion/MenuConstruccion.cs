using Godot;
using System;

public partial class MenuConstruccion : CanvasLayer
{
	// --- Nodos de UI ---
	private TextureButton btnMenu;
	private PanelContainer panelBarra;
	private HBoxContainer hboxBotones;
	private TextureButton btnCasa;
	private Sprite2D marcadorCasa;

	// --- Construcción ---
	private bool enConstruccion = false;
	private Node2D casaPreview;
	private ResourceManager resourceManager;

	// --- Configuración cuadrícula ---
	private const int GRID_SIZE = 64;

	public override void _Ready()
	{
		// Buscar ResourceManager en la escena principal
		resourceManager = GetTree().Root.GetNode<ResourceManager>("ResourceManager");

		// Obtener nodos de UI
		btnMenu = GetNode<TextureButton>("ControlRaiz/BtnMenu");
		panelBarra = GetNode<PanelContainer>("ControlRaiz/PanelBarra");
		hboxBotones = GetNode<HBoxContainer>("ControlRaiz/PanelBarra/HBoxBotones");
		btnCasa = GetNode<TextureButton>("ControlRaiz/PanelBarra/HBoxBotones/BtnCasa");
		marcadorCasa = GetNode<Sprite2D>("ControlRaiz/PanelBarra/HBoxBotones/BtnCasa/Marcador");

		// Ajustar MouseFilter para asegurar que reciben input
		panelBarra.MouseFilter = Control.MouseFilterEnum.Stop;
		btnCasa.MouseFilter = Control.MouseFilterEnum.Stop;

		// Ocultar panel al inicio
		panelBarra.Visible = false;
		marcadorCasa.Visible = false;

		// Conectar eventos
		btnMenu.Connect("pressed", new Callable(this, nameof(OnMenuPressed)));
		btnCasa.Connect("pressed", new Callable(this, nameof(OnCasaPressed)));
	}

	private void OnMenuPressed()
	{
		panelBarra.Visible = !panelBarra.Visible;

		// Si se oculta el panel, reiniciar todo
		if (!panelBarra.Visible)
			CancelarConstruccion();

		// Ajustar MouseFilter según visibilidad
		panelBarra.MouseFilter = panelBarra.Visible
			? Control.MouseFilterEnum.Stop
			: Control.MouseFilterEnum.Ignore;
	}

	private void OnCasaPressed()
{
	marcadorCasa.Visible = !marcadorCasa.Visible;

	// Evitar iniciar otro preview si ya estamos en construcción
	if (enConstruccion)
		return;

	enConstruccion = true;

	// Instanciar preview semi-transparente
	casaPreview = (Node2D)resourceManager.casaScene.Instantiate();


	// ⚠️ Marcar que este objeto es un preview temporal
	if (casaPreview is CasaAnimada casaScript)
		casaScript.EsPreview = true;

	// Aplicar transparencia solo a los nodos visuales
	foreach (Node child in casaPreview.GetChildren())
	{
		if (child is CanvasItem visual)
			visual.Modulate = new Color(1, 1, 1, 0.5f);
	}

	resourceManager.contenedorCasas.AddChild(casaPreview);
}

	public override void _Process(double delta)
	{
		if (!enConstruccion || casaPreview == null)
			return;

		// Seguir el ratón y ajustar a cuadrícula
		Vector2 mousePos = GetViewport().GetMousePosition();
		float x = Mathf.Floor(mousePos.X / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2;
		float y = Mathf.Floor(mousePos.Y / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2;
		casaPreview.Position = new Vector2(x, y);

		// Cancelar con clic derecho o tecla Esc
		if (Input.IsMouseButtonPressed(MouseButton.Right) || Input.IsKeyPressed(Key.Escape))
		{
			CancelarConstruccion();
			return;
		}

		// Colocar casa con clic izquierdo
		if (Input.IsMouseButtonPressed(MouseButton.Left))
		{
			// Verificar si hay recursos suficientes
			if (resourceManager.PuedoComprarCasa())
			{
				resourceManager.PagarCasa();
				resourceManager.AddHouse();

				// Convertir preview en casa definitiva
				casaPreview.Modulate = new Color(1, 1, 1, 1);
				casaPreview = null;
				enConstruccion = false;
				marcadorCasa.Visible = false;
			}
			else
			{
				GD.Print("❌ No tienes materiales suficientes para construir una casa.");
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
	}
}
