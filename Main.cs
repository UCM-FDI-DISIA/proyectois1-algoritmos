using Godot;
using System;

public partial class Main : Node2D
{
	[Export] public PackedScene ArbolEscena;
	private TileMap tileMap;

	public override void _Ready()
	{
		tileMap = GetNode<TileMap>("TileMap");

		// Ejemplo: instanciar árboles en ciertas celdas
		Vector2I[] posicionesCeldas = {
			new Vector2I(3, 5),
			new Vector2I(6, 7),
			new Vector2I(8, 4)
		};

		foreach (var celda in posicionesCeldas)
		{
			ColocarArbolEnCelda(celda);
		}
	}

	private void ColocarArbolEnCelda(Vector2I celda)
	{
		if (ArbolEscena == null)
		{
			GD.PrintErr("No se asignó la escena del árbol en el inspector.");
			return;
		}

		var arbol = ArbolEscena.Instantiate<Arbol>();

		// Convertir coordenadas de celda a posición global
		Vector2 posGlobal = tileMap.MapToLocal(celda);
		arbol.Position = posGlobal;
		arbol.ZIndex = (int)posGlobal.Y;

		GetNode<Node2D>("Objetos").AddChild(arbol);
	}
}
