using Godot;
using System;

public partial class CasaAnimada : Node2D
{
	public static int numCasas = 0;
	private const int PERSONAS = 2;
	
	
	// Esto se ejecuta una sóla vez.
	public override void _Ready()
	{
		numCasas++;
		
		// Al generar una instancia de Casa, actualizo la pendiente de crecimiento de la población.
		var manager = GetNode<ResourceManager>("/root/Main/ResourceManager");
		manager.ActualizarAldeanos(PERSONAS * numCasas);
		manager.AddResource("villager", PERSONAS * numCasas);
		GD.Print("Crecimiento población: +" + PERSONAS * numCasas);
		
		// Para comprobar que todo funciona bien, se muestra por pantalla.
		GD.Print("Hay " + numCasas + " casas.");
	}
}
