using Godot;
using System;

// Define la clase como parcial para coincidir con la convención de Godot
public partial class RockBattleArea : Area2D // Cambiado de Node2D a Area2D para reflejar BodyEntered/Exited
{
	// La ruta exportada se mantiene, pero se usará la ruta absoluta en _Ready
	// NOTA: Si el botón no se hace visible, la ruta ABSOLUTA es el problema.
	[Export] private NodePath battleButtonPath = "/root/Main/Objetos/BotonBatalla/UI/BattleButton"; 
	private TextureButton battleButton;
	private CharacterBody2D player;
	private float collectionTime = 0f;
	private const float REQUIRED_TIME = 60f;
	private bool playerInArea = false;

	// Constante para la ruta absoluta, facilitando la lectura
	private const string ABSOLUTE_BUTTON_PATH = "/root/Main/Objetos/BotonBatalla/RockBattleArea/UI/BattleButton";


	public override void _Ready()
	{
		GD.Print("🔹 RockBattleArea _Ready iniciado");

		// --- 1. REFERENCIA AL JUGADOR ---
		var players = GetTree().GetNodesInGroup("jugador");
		if (players.Count > 0)
		{
			// Se asume que el jugador es el primer nodo en el grupo
			player = (CharacterBody2D)players[0];
			GD.Print("✅ Jugador encontrado vía grupo");
		}
		else
		{
			GD.PrintErr("❌ No se encontró jugador en el grupo 'jugador'");
		}

		// --- 2. REFERENCIA AL BOTÓN DE BATALLA ---
		// NOTA: Se utiliza la ruta absoluta. Si el botón no aparece, VERIFICA esta ruta.
		battleButton = GetNodeOrNull<TextureButton>(ABSOLUTE_BUTTON_PATH); 
		
		if (battleButton == null)
		{
			// Muestra la ruta fallida para facilitar la depuración en el editor de Godot
			GD.PrintErr($"❌ No se encontró el botón TextureButton en la ruta: {ABSOLUTE_BUTTON_PATH}. ¡VERIFICA EL ÁRBOL DE ESCENAS y la ruta!");
		}
		else
		{
			GD.Print("✅ Botón encontrado en la escena");
			// El botón debe estar oculto hasta que el jugador entre
			battleButton.Visible = false; 
			battleButton.Disabled = true;      // Deshabilitado hasta completar timer
			
			// Si necesitas conectar un método de batalla, hazlo aquí:
			// battleButton.Pressed += OnBattleButtonPressed; 
		}

		// Conectar señales de Area2D (asegúrate de que el nodo sea de tipo Area2D)
		// Las señales deben conectarse aquí, en la instancia del script
		BodyEntered += OnBodyEntered;
		BodyExited += OnBodyExited;
	}

	public override void _Process(double delta)
	{
		// Solo procesa y muestra el botón si el jugador está en el área y el botón existe
		if (playerInArea && battleButton != null)
		{
			// Incrementa tiempo de recolección
			collectionTime += (float)delta;
			
			// Mostrar el botón (si aún no está visible)
			if (!battleButton.Visible)
			{
				battleButton.Visible = true;
				// Cuando se hace visible por primera vez, puedes querer centrarlo o posicionarlo.
			}

			// Activar/desactivar según el timer
			battleButton.Disabled = collectionTime < REQUIRED_TIME;

			if (battleButton.Disabled)
				GD.Print($"⏳ Botón visible pero deshabilitado");
			else
				GD.Print("⚔️ Botón habilitado: listo para batallar");
		}
	}

	private void OnBodyEntered(Node body)
	{
		// Verifica si el cuerpo que entró es el jugador
		if (body == player)
		{
			playerInArea = true;
			// ELIMINADO: collectionTime = 0f; -- El temporizador ahora no se reinicia al entrar
			GD.Print("🚶‍♂️ Jugador entró en área de batalla. El tiempo de colección continúa.");
		}
	}

	private void OnBodyExited(Node body)
	{
		// Verifica si el cuerpo que salió es el jugador
		if (body == player)
		{
			playerInArea = false;
			// ELIMINADO: collectionTime = 0f; -- El temporizador ahora no se reinicia al salir
			
			if (battleButton != null)
			{
				battleButton.Visible = false; // Oculta el botón
				battleButton.Disabled = true; // Deshabilita el botón
			}
			GD.Print("🏃 Jugador salió del área de batalla");
		}
	}
}
