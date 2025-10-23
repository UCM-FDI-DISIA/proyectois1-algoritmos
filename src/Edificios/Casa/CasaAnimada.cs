using Godot;
using System;

public partial class CasaAnimada : Node2D
{
	public static int numCasas = 0;
	
	// Esto se ejecuta una sóla vez.
	public override void _Ready(){
		numCasas++;
		
		// Para comprobar que todo funciona bien, se 
		GD.Print("Hay " + numCasas + " casas.");
	}
}
