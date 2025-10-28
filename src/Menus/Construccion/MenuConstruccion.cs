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
			GD.PrintErr("ResourceManager no encontrado");
		else
			GD.Print("ResourceManager encontrado");

		btnMenu = GetNode<TextureButton>("ControlRaiz/BtnMenu");
		panelBarra = GetNode<PanelContainer>("ControlRaiz/PanelBarra");
		hboxBotones = GetNode<HBoxContainer>("ControlRaiz/PanelBarra/HBoxBotones");
		btnCasa = GetNode<TextureButton>("ControlRaiz/PanelBarra/HBoxBotones/BtnCasa");
		marcadorCasa = GetNode<Sprite2D>("ControlRaiz/PanelBarra/HBoxBotones/BtnCasa/Marcador");

		panelBarra.MouseFilter = Control.MouseFilterEnum.Stop;
		btnCasa.MouseFilter = Control.MouseFilterEnum.Stop;

		panelBarra.Visible = false;
		marcadorCasa.Visible = false;

		// Conectar señales usando evento
		btnMenu.Pressed += OnMenuPressed;
		btnCasa.Pressed += OnCasaPressed;
	}

	private void OnMenuPressed()
	{
		panelBarra.Visible = !panelBarra.Visible;

		if (!panelBarra.Visible)
			CancelarConstruccion();

		panelBarra.MouseFilter = panelBarra.Visible
			? Control.MouseFilterEnum.Stop
			: Control.MouseFilterEnum.Ignore;

		GD.Print($"🖱️ Panel de construcción {(panelBarra.Visible ? "visible" : "oculto")}");
	}

	private void OnCasaPressed()
	{
		marcadorCasa.Visible = !marcadorCasa.Visible;

		if (enConstruccion)
		{
			GD.Print("Ya estás en modo construcción");
			return;
		}

		if (resourceManager == null || resourceManager.casaScene == null || resourceManager.contenedorCasas == null)
		{
			GD.PrintErr("Faltan asignaciones en ResourceManager (casaScene o contenedorCasas)");
			return;
		}

		enConstruccion = true;

		casaPreview = (Node2D)resourceManager.casaScene.Instantiate();

		// ⚙️ Marcar como preview
		if (casaPreview is CasaAnimada casaAnim)
			casaAnim.EsPreview = true;

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

		// Snap a la cuadrícula
		Vector2 mousePos = GetViewport().GetMousePosition();
		float x = Mathf.Floor(mousePos.X / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2;
		float y = Mathf.Floor(mousePos.Y / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2;
		casaPreview.Position = new Vector2(x, y);

		// Cancelar con clic derecho o ESC
		if (Input.IsMouseButtonPressed(MouseButton.Right) || Input.IsKeyPressed(Key.Escape))
		{
			CancelarConstruccion();
			return;
		}

		// Confirmar con clic izquierdo
		if (Input.IsMouseButtonPressed(MouseButton.Left))
		{
			if (resourceManager.PuedoComprarCasa())
			{
				resourceManager.PagarCasa();

				// Crear la casa real
				var casaReal = (CasaAnimada)resourceManager.casaScene.Instantiate();
				casaReal.EsPreview = false;
				casaReal.Position = casaPreview.Position;
				resourceManager.contenedorCasas.AddChild(casaReal);

				// Liberar preview
				casaPreview.QueueFree();
				casaPreview = null;
				enConstruccion = false;
				marcadorCasa.Visible = false;
				btnCasa.ButtonPressed = false;

				GD.Print("Casa construida correctamente");
			}
			else
			{
				GD.Print(" No tienes materiales suficientes para construir");
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

		GD.Print("Construcción cancelada");
	}
}
