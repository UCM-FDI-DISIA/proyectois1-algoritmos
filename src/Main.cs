using Godot;
using System;

public partial class Main : Node2D
{
	private TileMapLayer capaSuelo;
	private Node2D capaObjetos;

	public override void _Ready()
	{
		// Obtener referencias a los nodos
		capaSuelo = GetNode<TileMapLayer>("Mapa/Suelo_0");
		capaObjetos = GetNode<Node2D>("Mapa/Objetos");
	}
}
