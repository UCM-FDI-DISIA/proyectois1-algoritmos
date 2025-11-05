using Godot;
using System;
using System.Collections.Generic;

public partial class TimerRoot : Control
{
	private Label timerLabel;
	private Label warningLabel; 
	private Timer mainTimer;
	private Timer postTimer;

	private float remainingTime = 60; // 1 minuto
	private const int SEGUNDO_TIEMPO = 30;
	private const int ULTIMOS_SEGUNDOS = 20;
	private const string WARNING_1 = "No puedes atacar.";
	private const string WARNING_2 = "¡Llega la última batalla!";
	 
	[Signal]
	public delegate void TiempoEspecificoAlcanzadoEventHandler();
	
	private bool senalYaEnviada = false; // Flag para emitir la señal solo una vez.
	private bool tiempoTerminado = false; // Para no repetir la transición.

	public override void _Ready()
	{
		mainTimer = GetNode<Timer>("CountdownTimer");
		timerLabel = GetNode<Label>("TimerLabel");
		warningLabel = GetNode<Label>("WarningLabel");

		mainTimer.Timeout += OnTimerTimeout;
		mainTimer.Start();
		UpdateLabel();

		// Creamos el segundo temporizador (no está en escena)
		postTimer = new Timer();
		AddChild(postTimer);
		postTimer.OneShot = true;
		postTimer.WaitTime = 5; // 5 segundos
		postTimer.Timeout += OnPostTimerTimeout;
	}

	private void OnTimerTimeout()
	{
		if (tiempoTerminado)
			return;

		remainingTime -= 1;

		if (remainingTime <= 0)
		{
			remainingTime = 0;
			mainTimer.Stop();
			UpdateLabel();

			GD.Print("⏰ Tiempo terminado. Comienza cuenta atrás de 5 segundos antes de batalla.");
			tiempoTerminado = true;
			postTimer.Start();
			return;
		}

		UpdateLabel();

		if (!senalYaEnviada && remainingTime <= SEGUNDO_TIEMPO)
		{
			GD.Print($"TimerRoot: El tiempo ha llegado a {SEGUNDO_TIEMPO}. ¡Emitiendo señal!");
			EmitSignal(SignalName.TiempoEspecificoAlcanzado);
			senalYaEnviada = true;
		}
	}

	private void OnPostTimerTimeout()
	{
		GD.Print("⚔️ Pasaron los 5 segundos extra. Iniciando batalla automáticamente...");
		IrACampoDeBatalla();
	}

	private void IrACampoDeBatalla()
	{
		// Guardar estado de tropas actuales
		GameState gameState = GameState.GetInstance();
		gameState.SaveCurrentTroopsFromMenu();

		// Cambiar de escena
		GetTree().ChangeSceneToFile("res://src/PantallaAtaque/campoBatalla.tscn");
	}

	private void UpdateLabel()
	{
		int minutes = Mathf.FloorToInt(remainingTime) / 60;
		int seconds = Mathf.FloorToInt(remainingTime) % 60;
		timerLabel.Text = $"{minutes:00}:{seconds:00}";
		
		if (remainingTime > SEGUNDO_TIEMPO)
			timerLabel.Modulate = Colors.White;
		else if (remainingTime < ULTIMOS_SEGUNDOS)
		{
			warningLabel.Modulate = Colors.Red;
			timerLabel.Modulate = Colors.Red;
		}
		else
			timerLabel.Modulate = Colors.Green;

		warningLabel.Visible = remainingTime > SEGUNDO_TIEMPO || remainingTime < ULTIMOS_SEGUNDOS;
		warningLabel.Text = remainingTime < ULTIMOS_SEGUNDOS ? WARNING_2 : WARNING_1;
	}
}
