using Godot;
using System;

public partial class TimerRoot : Control
{
	private Label timerLabel;
	private Label warningLabel; 
	private float remainingTime = 180; // 3 minutos en segundos
	private int SEGUNDO_TIEMPO = 120;

	public override void _Ready()
	{
		var timer = GetNode<Timer>("CountdownTimer");
		timerLabel = GetNode<Label>("TimerLabel");
		warningLabel = GetNode<Label>("WarningLabel");
		
		timer.Timeout += OnTimerTimeout;
		timer.Start();
		UpdateLabel();
	}

	private void OnTimerTimeout()
	{
		remainingTime -= 1; // Decrementa el tiempo
		
		if (remainingTime < 0)
		{
			remainingTime = 0;
			GetNode<Timer>("CountdownTimer").Stop();
		}
		
		UpdateLabel();
	}

	private void UpdateLabel()
	{
		// Convierte segundos a MM:SS
		int minutes = Mathf.FloorToInt(remainingTime) / 60;
		int seconds = Mathf.FloorToInt(remainingTime) % 60;
		timerLabel.Text = $"{minutes:00}:{seconds:00}";
		
		// Cambia color basado en el tiempo
		if (remainingTime > SEGUNDO_TIEMPO) // Arriba de 2 minutos
		{
			timerLabel.Modulate = Colors.Green;
		}
		else // 120 segundos o menos
		{
			timerLabel.Modulate = Colors.Red;
		}
		
		// Controla la visibilidad de la etiqueta de advertencia
		if (remainingTime > SEGUNDO_TIEMPO) // Mientras quede más de 2 minutos
		{
			warningLabel.Visible = true;
		}
		else // Cuando llega a 2 minutos o menos
		{
			warningLabel.Visible = false;
		}
	}
}
