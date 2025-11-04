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

	// ----------------------------
	// CONFIGURACIÓN
	// ----------------------------
	private float collectionTime = 0f;
	private const float REQUIRED_TIME = 40f;
	private bool playerInArea = false;

	// ----------------------------
	// INICIALIZACIÓN
	// ----------------------------
	public override void _Ready()
	{
		GD.Print("🧠 [RockBattleArea] Script cargado correctamente (modo mundo)");

		// Buscar jugador
		player = GetTree().GetFirstNodeInGroup("jugador") as CharacterBody2D;
		if (player != null)
			GD.Print($"✅ Jugador encontrado: {player.Name}");
		else
			GD.PrintErr("❌ No se encontró jugador en el grupo 'jugador'");

		// Buscar el botón e ícono del menú de batalla
		battleButton = GetNodeOrNull<TextureButton>("UI/BattleButton");
		battleIcon = GetNodeOrNull<Sprite2D>("UI/BattleButton/BattleIcon");

		if (battleIcon != null)
		{
			battleIcon.ZIndex = 10;
			battleIcon.Visible = false;
		}
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
			battleIcon.Visible = false;
			battleButton.TooltipText = "Aún no puedes atacar";

			// Conectar eventos de hover del ratón
			battleButton.MouseEntered += OnButtonHover;
			battleButton.MouseExited += OnButtonExit;

			GD.Print($"✅ Botón inicializado en posición mundial {battleButton.GlobalPosition}");
		}

		// Configurar colisión para el botón
		var collision = GetNode<CollisionShape2D>("UI/BattleButton/StaticBody2D/CollisionShape2D");
		Vector2 textureSize = battleButton.TextureNormal.GetSize();

		var shape = new RectangleShape2D();
		shape.Size = textureSize * 2;
		collision.Shape = shape;
		collision.Position = battleButton.Position + textureSize / 2;

		// Conectar señales del área
		BodyEntered += OnBodyEntered;
		BodyExited += OnBodyExited;
	}

	// ----------------------------
	// PROCESO PRINCIPAL
	// ----------------------------
	public override void _Process(double delta)
	{
		collectionTime += (float)delta;

		if (battleButton == null)
			return;

		// Habilitar el botón después de cierto tiempo
		if (collectionTime >= REQUIRED_TIME)
		{
			battleButton.Disabled = false;
			battleButton.TooltipText = "";
		}
	}

	// ----------------------------
	// EVENTOS DE COLISIÓN
	// ----------------------------
	private void OnBodyEntered(Node body)
	{
		if (body == player)
		{
			playerInArea = true;

			if (battleButton != null)
			{
				battleButton.Visible = true;
				if (!battleButton.Disabled)
					battleIcon.Visible = true;
			}

			GD.Print($"⚔️ Jugador '{player.Name}' entró al área -> botón habilitado");
		}
	}

	private void OnBodyExited(Node body)
	{
		if (body == player)
		{
			playerInArea = false;

			if (battleButton != null)
			{
				battleButton.Visible = false;
				battleIcon.Visible = false;
			}

			GD.Print($"🏃 Jugador '{player.Name}' salió del área -> botón deshabilitado");
		}
	}

	// ----------------------------
	// EVENTOS DE INTERFAZ (HOVER)
	// ----------------------------
	private void OnButtonHover()
	{
		if (battleButton.Disabled)
		{
			battleButton.TooltipText = "Aún no puedes atacar ⚔️";
			GD.Print("🕐 Hover sobre botón bloqueado");
		}
	}

	private void OnButtonExit()
	{
		battleButton.TooltipText = battleButton.Disabled ? "Aún no puedes atacar ⚔️" : "";
	}
}
