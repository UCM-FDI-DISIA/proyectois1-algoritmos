using Godot;
using System;

public partial class RockBattleArea : Area2D
{
	private TextureButton battleButton;
	private CharacterBody2D player;

	private float collectionTime = 0f;
	private const float REQUIRED_TIME = 40f;
	private bool playerInArea = false;

	public override void _Ready()
	{
		GD.Print("🧠 [RockBattleArea] Script cargado correctamente (modo mundo)");

		// 1️⃣ Buscar jugador
		player = GetTree().GetFirstNodeInGroup("jugador") as CharacterBody2D;
		if (player != null)
			GD.Print($"✅ Jugador encontrado: {player.Name}");
		else
			GD.PrintErr("❌ No se encontró jugador en el grupo 'jugador'");

		// 2️⃣ Buscar el botón en la jerarquía local
		battleButton = GetNodeOrNull<TextureButton>("UI/BattleButton");
		if (battleButton == null)
		{
			GD.PrintErr("❌ No se encontró 'UI/BattleButton'");
		}
		else
		{
			battleButton.Visible = false;
			battleButton.Disabled = true;
			GD.Print($"✅ Botón inicializado en posición mundial {battleButton.GlobalPosition}");
		}

		// 3️⃣ Conectar señales del área
		BodyEntered += OnBodyEntered;
		BodyExited += OnBodyExited;
	}

	public override void _Process(double delta)
	{
		collectionTime += (float)delta;

		if (battleButton == null)
			return;

		// Mostrar el botón después de 20 segundos
		if (collectionTime >= REQUIRED_TIME)
		{
			/*if (!battleButton.Visible)
			{
				battleButton.Visible = true;
				GD.Print("👁️ Botón visible tras 20 segundos");
			}
			*/

			battleButton.Disabled = false;
		}
	}

	private void OnBodyEntered(Node body)
	{
		if (body == player)
		{
			playerInArea = true;
			if (battleButton != null)
				battleButton.Visible = true;

			GD.Print($"⚔️ Jugador '{player.Name}' entró al área -> botón habilitado");
		}
	}

	private void OnBodyExited(Node body)
	{
		if (body == player)
		{
			playerInArea = false;
			if (battleButton != null)
				battleButton.Visible = false;

			GD.Print($"🏃 Jugador '{player.Name}' salió del área -> botón deshabilitado");
		}
	}
}
