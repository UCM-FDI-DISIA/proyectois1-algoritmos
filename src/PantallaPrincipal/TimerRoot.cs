using Godot;
using System;

public partial class TimerRoot : Control
{
	private Label timerLabel;
	private Label warningLabel; 
	private float remainingTime = 60; // 3 minutos en segundos
	
	private int SEGUNDO_TIEMPO = 30;
	private int ULTIMOS_SEGUNDOS = 20;
	private const String WARNING_1 = "No puedes atacar.";
	private const String WARNING_2 = "¡Llega la última batalla!";
	 
	
	// La declaración de la señal está perfecta.
	[Signal]
	public delegate void TiempoEspecificoAlcanzadoEventHandler();
	
	private bool senalYaEnviada = false; // El flag para emitir solo una vez.

	public override void _Ready()
	{
		var timer = GetNode<Timer>("CountdownTimer");
		timerLabel = GetNode<Label>("TimerLabel");
		warningLabel = GetNode<Label>("WarningLabel");
		
		// Conectamos la señal del Timer y lo iniciamos
		timer.Timeout += OnTimerTimeout;
		timer.Start();
		UpdateLabel();
	}

	private void OnTimerTimeout()
	{
		if (remainingTime <= 0)
		{
			// Si el tiempo ya es cero, no hacemos nada más.
			return;
		}

		remainingTime -= 1; // Decrementa el tiempo en 1 segundo

		if (remainingTime < 0)
		{
			remainingTime = 0;
			GetNode<Timer>("CountdownTimer").Stop();
		}
		
		UpdateLabel();
		
		// --- AQUÍ VA LA LÓGICA CORRECTA ---
		// Comprobamos la condición CADA SEGUNDO.
		if (!senalYaEnviada && remainingTime <= SEGUNDO_TIEMPO)
		{
			GD.Print($"TimerRoot: El tiempo ha llegado a {SEGUNDO_TIEMPO}. ¡Emitiendo señal!");
			EmitSignal(SignalName.TiempoEspecificoAlcanzado);
			senalYaEnviada = true; // Marcamos que la señal ya se ha enviado para no repetirla.
		}
	}

	private void UpdateLabel()
	{
		// Convierte segundos a MM:SS
		int minutes = Mathf.FloorToInt(remainingTime) / 60;
		int seconds = Mathf.FloorToInt(remainingTime) % 60;
		timerLabel.Text = $"{minutes:00}:{seconds:00}";
		
		// Cambia color basado en el tiempo
		if (remainingTime > SEGUNDO_TIEMPO)
			timerLabel.Modulate = Colors.White;
		else if (remainingTime < ULTIMOS_SEGUNDOS)
		{
			warningLabel.Modulate = Colors.Red;
			timerLabel.Modulate = Colors.Red;
		}
		else
			timerLabel.Modulate = Colors.Green;
		
		// Controla la visibilidad de la etiqueta de advertencia
		warningLabel.Visible = remainingTime > SEGUNDO_TIEMPO || remainingTime < ULTIMOS_SEGUNDOS;
		warningLabel.Text = remainingTime < ULTIMOS_SEGUNDOS ? WARNING_2 : WARNING_1;
	}
}
