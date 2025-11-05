using Godot;
using System;

public partial class RockBattleArea : Area2D
{
	// ----------------------------
	// VARIABLES Y NODOS
	// ----------------------------
	private TextureButton battleButton;
	private Sprite2D battleIcon; 
	private CharacterBody2D player;

	private bool playerInArea = false;

	// ----------------------------
	// INICIALIZACIÓN
	// ----------------------------
	public override void _Ready()
	{
		GD.Print("🧠 [RockBattleArea] Script cargado correctamente (modo mundo)");
		
		player = GetTree().GetFirstNodeInGroup("jugador") as CharacterBody2D;
		if (player != null)
			GD.Print($"✅ Jugador encontrado: {player.Name}");
		else
			GD.PrintErr("❌ No se encontró jugador en el grupo 'jugador'");

		battleButton = GetNodeOrNull<TextureButton>("UI/BattleButton");
		battleIcon = GetNodeOrNull<Sprite2D>("UI/BattleButton/BattleIcon");

		if (battleIcon != null)
			battleIcon.Visible = false;
		else
			GD.PrintErr("❌ No se encontró BattleIcon");

		if (battleButton == null)
		{
			GD.PrintErr("❌ No se encontró 'UI/BattleButton'");
		}
		else
		{
			battleButton.Visible = false;
			battleButton.Disabled = true;
			battleButton.TooltipText = "Aún no puedes atacar";
			
			// Eventos
			battleButton.MouseEntered += OnButtonHover;
			battleButton.MouseExited += OnButtonExit;
			battleButton.Pressed += OnBattleButtonPressed; // 🔥 Añadido
			
			GD.Print($"✅ Botón inicializado en posición mundial {battleButton.GlobalPosition}");
		}

		// Configurar colisión
		var collision = GetNode<CollisionShape2D>("UI/BattleButton/StaticBody2D/CollisionShape2D");
		Vector2 textureSize = battleButton.TextureNormal.GetSize();

		var shape = new RectangleShape2D();
		shape.Size = textureSize * 2;
		collision.Shape = shape;
		collision.Position = battleButton.Position + textureSize / 2;

		// Conectar señales del área
		BodyEntered += OnBodyEntered;
		BodyExited += OnBodyExited;

		// Conectar con el temporizador
		var timerNode = GetNode<TimerRoot>("../../Timer/Panel/TimerRoot");
		if (timerNode == null)
		{
			GD.PrintErr("❌ No se pudo encontrar el nodo TimerRoot en la ruta especificada.");
			return;
		}
		timerNode.TiempoEspecificoAlcanzado += OnTiempoEspecificoAlcanzado;
	}

	// ----------------------------
	// EVENTOS PERSONALIZADOS
	// ----------------------------
	public void OnTiempoEspecificoAlcanzado()
	{
		GD.Print("✅ Señal recibida — ¡Botón habilitado!");
		battleButton.Disabled = false;
		battleIcon.Visible = true;
		battleButton.TooltipText = "Entrar al combate ⚔️";
	}

	// ----------------------------
	// EVENTOS DE ÁREA
	// ----------------------------
	private void OnBodyEntered(Node body)
	{
		if (body == player)
		{
			playerInArea = true;
			battleButton.Visible = true;
			if (!battleButton.Disabled)
				battleIcon.Visible = true;

			GD.Print($"⚔️ Jugador '{player.Name}' entró al área -> botón visible");
		}
	}

	private void OnBodyExited(Node body)
	{
		if (body == player)
		{
			playerInArea = false;
			battleButton.Visible = false;
			battleIcon.Visible = false;
			GD.Print($"🏃 Jugador '{player.Name}' salió del área -> botón oculto");
		}
	}

	// ----------------------------
	// EVENTOS DE INTERFAZ
	// ----------------------------
	private void OnButtonHover()
	{
		if (battleButton.Disabled)
			battleButton.TooltipText = "Aún no puedes atacar ⚔️";
		else
			battleButton.TooltipText = "Entrar al combate ⚔️";
	}

	private void OnButtonExit()
	{
		battleButton.TooltipText = "";
	}

	private void OnBattleButtonPressed()
	{
		if (battleButton.Disabled)
		{
			GD.Print("🚫 Botón presionado pero aún deshabilitado.");
			return;
		}

		GD.Print("✅ Botón presionado — cambiando a escena 'campoBatalla.tscn'...");
		
		// Cargar y cambiar de escena
		GetTree().ChangeSceneToFile("res://src/PantallaAtaque/campoBatalla.tscn");
	}
}
