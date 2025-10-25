using Godot;
using System;

public partial class MenuConstruccion : CanvasLayer
{
	private TextureButton btnMenu;      // Botón principal (carrito)
	private PanelContainer panelBarra;  // Panel desplegable
	private HBoxContainer hboxBotones;  // Contenedor de los botones
	private TextureButton btnCasa;
	private TextureButton btnGranero;
	private TextureButton btnMolino;

	public override void _Ready()
	{
		btnMenu = GetNode<TextureButton>("ControlRaiz/BtnMenu");
		panelBarra = GetNode<PanelContainer>("ControlRaiz/PanelBarra");
		hboxBotones = GetNode<HBoxContainer>("ControlRaiz/PanelBarra/HBoxBotones");

		btnCasa = GetNode<TextureButton>("ControlRaiz/PanelBarra/HBoxBotones/BtnCasa");
		btnGranero = GetNode<TextureButton>("ControlRaiz/PanelBarra/HBoxBotones/BtnGranero");
		btnMolino = GetNode<TextureButton>("ControlRaiz/PanelBarra/HBoxBotones/BtnMolino");

		// Panel oculto al inicio
		panelBarra.Visible = false;

		// Eventos
		btnMenu.Pressed += OnMenuPressed;
		btnCasa.Pressed += () => OnBuildingPressed("Casa");
		btnGranero.Pressed += () => OnBuildingPressed("Granero");
		btnMolino.Pressed += () => OnBuildingPressed("Molino");
	}

	private void OnMenuPressed()
	{
		panelBarra.Visible = !panelBarra.Visible;
	}

	private void OnBuildingPressed(string tipo)
	{
		GD.Print($"Seleccionado edificio: {tipo}");
		// Aquí luego añadirás la lógica para colocar la casa/granero/etc.
	
	}
}
