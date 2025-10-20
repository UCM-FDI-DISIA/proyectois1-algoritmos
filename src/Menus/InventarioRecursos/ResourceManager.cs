using Godot;
using System;

public partial class ResourceManager : Node
{
	[Signal]
	public delegate void ResourceUpdatedEventHandler(string resourceName, int newValue);

	private Godot.Collections.Dictionary<string, int> resources = new Godot.Collections.Dictionary<string, int>
	{
		{ "wood", 0 },
		{ "stone", 0 },
		{ "iron", 0 },
		{ "gold", 0 }
	};

	public void AddResource(string resourceName, int amount = 1)
	{
		if (resources.ContainsKey(resourceName))
		{
			resources[resourceName] += amount;
			EmitSignal(nameof(ResourceUpdated), resourceName, resources[resourceName]);
		}
	}
}
