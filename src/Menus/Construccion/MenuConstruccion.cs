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

	private Area2D areaPreview; // 🔹 para detectar colisiones del preview
	private bool puedeConstruir = true; // 🔹 evita construir sobre el jugador

	private ResourceManager resourceManager;

	private const int GRID_SIZE = 64;

	public override void _Ready()
	{
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

		if (resourceManager != null)
		{
			btnCasa.TooltipText = $"Costo: Madera {resourceManager.GetCasaWoodCost()} | Piedra {resourceManager.GetCasaStoneCost()} | Oro {resourceManager.GetCasaGoldCost()}";
		}

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
	{
		casaAnim.EsPreview = true;

		// 🚫 Desactivar el CollisionShape2D del preview para evitar vibraciones
		var collisionShape = casaAnim.GetNodeOrNull<CollisionShape2D>("CollisionShape2D");
		if (collisionShape != null)
			collisionShape.Disabled = true;

		// Opcional: si el padre tiene CollisionObject2D (StaticBody2D o Area2D)
		var collisionParent = casaAnim.GetNodeOrNull<CollisionObject2D>("CollisionObject2D");
		if (collisionParent != null)
		{
			collisionParent.CollisionLayer = 0;
			collisionParent.CollisionMask = 0;
		}
	}

	// 🔹 Hacer semi-transparente visualmente
	TintPreview(new Color(1, 1, 1, 0.5f));

	resourceManager.contenedorCasas.AddChild(casaPreview);
	GD.Print("🏠 Preview de casa instanciado y agregado al contenedor");

	// 🔹 Crear el Area2D para detectar si está sobre el jugador (sin vibración)
	CrearAreaPreview();
}


	private void CrearAreaPreview()
	{
		if (casaPreview == null) return;

		areaPreview = new Area2D();
		casaPreview.AddChild(areaPreview);

		// Copiar el CollisionShape2D del prefab
		var shapeOriginal = casaPreview.GetNode<CollisionShape2D>("CollisionShape2D");
		if (shapeOriginal != null && shapeOriginal.Shape != null)
		{
			var nuevaForma = shapeOriginal.Shape.Duplicate() as Shape2D;
			var shapeClone = new CollisionShape2D { Shape = nuevaForma };
			areaPreview.AddChild(shapeClone);
		}

		areaPreview.Monitoring = true;
		areaPreview.Monitorable = true;

		// Capa y máscara (ajusta si usas otras capas)
		areaPreview.CollisionLayer = 0;
		areaPreview.CollisionMask = 1; // Asume que el jugador está en capa 1

		areaPreview.BodyEntered += OnAreaPreviewBodyEntered;
		areaPreview.BodyExited += OnAreaPreviewBodyExited;
	}

	private void OnAreaPreviewBodyEntered(Node body)
	{
		if (body.IsInGroup("jugador"))
		{
			puedeConstruir = false;
			TintPreview(new Color(1, 0, 0, 0.4f)); // rojo = no se puede construir
		}
	}

	private void OnAreaPreviewBodyExited(Node body)
	{
		if (body.IsInGroup("jugador"))
		{
			puedeConstruir = true;
			TintPreview(new Color(1, 1, 1, 0.5f)); // blanco = sí se puede construir
		}
	}

	private void TintPreview(Color color)
	{
		if (casaPreview == null) return;

		foreach (Node child in casaPreview.GetChildren())
		{
			if (child is CanvasItem visual)
				visual.Modulate = color;
		}
	}

	public override void _Process(double delta)
	{
		if (!enConstruccion || casaPreview == null)
			return;

		var camera = GetViewport().GetCamera2D();
		Vector2 mousePos = camera.GetGlobalMousePosition();

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
			if (!puedeConstruir)
			{
				GD.Print("🚫 No puedes construir encima del personaje");
				return;
			}

			if (resourceManager.PuedoComprarCasa())
			{
				resourceManager.PagarCasa();

				var casaReal = (CasaAnimada)resourceManager.casaScene.Instantiate();
				casaReal.EsPreview = false;
				casaReal.Position = casaPreview.Position;
				resourceManager.contenedorCasas.AddChild(casaReal);

				casaPreview.QueueFree();
				casaPreview = null;
				enConstruccion = false;
				marcadorCasa.Visible = false;
				btnCasa.ButtonPressed = false;

				GD.Print("Casa construida correctamente");
			}
			else
			{
				GD.Print("No tienes materiales suficientes para construir");
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

		areaPreview = null;
		enConstruccion = false;
		marcadorCasa.Visible = false;
		btnCasa.ButtonPressed = false;

		GD.Print("Construcción cancelada");
	}
}
