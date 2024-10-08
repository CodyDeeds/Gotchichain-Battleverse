using Godot;
using Godot.Collections;
using Mattoha.Core.Utils;
using System;
using System.Linq;

namespace Mattoha.Nodes;
public partial class MattohaSystem : Node
{

	/// <summary>
	/// Emmited on server when a server rpc recived.
	/// </summary>
	/// <param name="methodName">method name to call.</param>
	/// <param name="payload">payload as godot dictionaty.</param>
	/// <param name="sender">peer id who send the rpc.</param>
	[Signal] public delegate void ServerRpcRecievedEventHandler(string methodName, Dictionary<string, Variant> payload, long sender);

	/// <summary>
	/// Emmited on client when a client rpc recived.
	/// </summary>
	/// <param name="methodName">method name to call.</param>
	/// <param name="payload">payload as godot dictionaty.</param>
	/// <param name="sender">peer id who send the rpc.</param>
	[Signal] public delegate void ClientRpcRecievedEventHandler(string methodName, Dictionary<string, Variant> payload, long sender);

	[Export] public bool IsServerBuild { get; set; } = false;
	[ExportGroup("Server Configuration"), Export] public string Address { get; set; } = "127.0.0.1";
	[ExportGroup("Server Configuration"), Export] public int Port { get; set; } = 7001;
	[ExportGroup("Server Configuration"), Export] public int MaxChannels { get; set; } = 5;
	[ExportGroup("Server Configuration"), Export] public int MaxPlayers { get; set; } = 4000;
	[ExportGroup("Server Configuration"), Export] public int MaxLobbiesCount { get; set; } = 100;
	[ExportGroup("Server Configuration"), Export] public int MaxPlayersPerLobby { get; set; } = 10;

	/// <summary>
	/// When lobby data changed or game started, auto load available lobbies for all online players.
	/// </summary>
	[ExportGroup("Server Configuration"), Export] public bool AutoLoadAvailableLobbies { get; set; } = true;


	[ExportGroup("System Nodes"), Export] public MattohaServer Server { get; private set; }
	[ExportGroup("System Nodes"), Export] public MattohaClient Client { get; private set; }


	/// <summary>
	/// Server split lobbies along x axis, specify lobby size will prevent overlapping available lobbies.
	/// </summary>
	[ExportGroup("Lobby Configuration"), Export] public long LobbySize { get; set; } = 5000;


	public static MattohaSystem Instance { get; set; }

	// used to generate random names
	private Array<string> _usedNames = new();


	public override void _Ready()
	{
		Instance = this;
		Client.SpawnNodeRequested += OnSpawnNodeRequested;
		Client.DespawnNodeRequested += OnDespawnNodeRequested;
		base._Ready();
	}

	public Node GetLobbyNodeFor(Node node)
	{
		var lobbyId = ExtractLobbyId(node.GetPath());
		return GetTree().Root.HasNode($"/root/GameHolder/Lobby{lobbyId}") ? GetNode($"/root/GameHolder/Lobby{lobbyId}") : null;
	}


	/// <summary>
	/// Extract Lobby ID from node path, all lobby games has "LobbyNN" when NN is the lobby ID.
	/// </summary>
	/// <param name="nodePath">node path to extract lobby id from.</param>
	/// <returns>extracted lobby id.</returns>
	public static int ExtractLobbyId(string nodePath)
	{
		string lobbyName = nodePath.Split("/")[3];
		string lobbyId = lobbyName.Split("Lobby")[1];
		return int.Parse(lobbyId);
	}


	/// <summary>
	/// Start Server that clients wil connect to.
	/// </summary>
	public void StartServer()
	{
		var peer = new ENetMultiplayerPeer();
		peer.CreateServer(Port, MaxPlayers, MaxChannels);
		Multiplayer.MultiplayerPeer = peer;
	}


	/// <summary>
	/// Establish a connection to server.
	/// </summary>
	public void StartClient()
	{
		var peer = new ENetMultiplayerPeer();
		peer.CreateClient(Address, Port);
		Multiplayer.MultiplayerPeer = peer;
	}

	private string GenerateUniqueName(Node node)
	{
		string name = node.Name.ToString().Replace("@", "_");
		name += $"_{Multiplayer.GetUniqueId()}_{Time.GetTicksMsec()}_{GD.Randi() % 1000}";
		if (_usedNames.Contains(name))
		{
			return GenerateUniqueName(node);
		}

		return name;
	}

	/// <summary>
	/// Used to create an instance from scene, use this method to initialize instance if the instance 
	/// will be spawned for all players or has MattohaSpawner node.
	/// </summary>
	/// <param name="sceneFile">Scene file to initialize from.</param>
	/// <returns>Created node instance.</returns>
	public Node CreateInstance(string sceneFile)
	{
		return CreateInstance(GD.Load<PackedScene>(sceneFile));
	}

	/// <summary>
	/// Used to create an instance from scene, use this method to initialize instance if the instance 
	/// will be spawned for all players or has MattohaSpawner node.
	/// </summary>
	/// <param name="scene">PackedScene to initialize from.</param>
	/// <returns>Created node instance.</returns>
	public Node CreateInstance(PackedScene scene)
	{
		var owner = Multiplayer.GetUniqueId();
		var instance = scene.Instantiate();
		instance.Name = GenerateUniqueName(instance);
		instance.SetMultiplayerAuthority(owner);
		return instance;
	}



	/// <summary>
	/// spawn a node by a payload generated by "GenerateNodePayloadData()", this method is used under the hood to spawn nodes.
	/// </summary>
	/// <param name="payload">spawn node payload</param>
	public void SpawnNodeFromPayload(Dictionary<string, Variant> payload)
	{
		var sceneFile = payload[MattohaSpawnKeys.SceneFile].ToString();
		var node = GD.Load<PackedScene>(sceneFile).Instantiate();
		node.Name = payload[MattohaSpawnKeys.NodeName].ToString();
		node.SetMultiplayerAuthority(payload[MattohaSpawnKeys.Owner].AsInt32());
		var parentPath = payload[MattohaSpawnKeys.ParentPath].ToString();
		if (node is Node2D)
		{
			(node as Node2D).Position = payload[MattohaSpawnKeys.Position].AsVector2();
			(node as Node2D).Rotation = payload[MattohaSpawnKeys.Rotation].As<float>();
		}
		if (node is Node3D)
		{
			(node as Node3D).Position = payload[MattohaSpawnKeys.Position].AsVector3();
			(node as Node3D).Rotation = payload[MattohaSpawnKeys.Rotation].As<Vector3>();
		}
		if (GetTree().Root.HasNode(parentPath))
		{
			var parent = GetNode(parentPath);
			if (!parent.HasNode(node.Name.ToString()))
			{
				parent.AddChild(node);
			}
		}
	}


	/// <summary>
	/// despawn a node by a payload generated by "GenerateNodePayloadData()", this method is used under the hood to despawn nodes.
	/// </summary>
	/// <param name="payload">spawn node payload</param>
	public void DespawnNodeFromPayload(Dictionary<string, Variant> payload)
	{
		if (GetTree().Root.HasNode(payload[MattohaSpawnKeys.ParentPath].ToString()))
		{
			var parent = GetNode(payload[MattohaSpawnKeys.ParentPath].ToString());
			if (parent.HasNode(payload[MattohaSpawnKeys.NodeName].ToString()))
			{
				parent.GetNode(payload[MattohaSpawnKeys.NodeName].ToString()).QueueFree();
			}
		}
	}

	private void OnSpawnNodeRequested(Dictionary<string, Variant> lobbyData)
	{
		SpawnNodeFromPayload(lobbyData);
	}


	private void OnDespawnNodeRequested(Dictionary<string, Variant> nodeData)
	{
		DespawnNodeFromPayload(nodeData);
	}


	/// <summary>
	/// Generate a spawning payload form a given node, this method is used under the hood to generate payloads
	/// for spawning nodes across players.
	/// </summary>
	/// <param name="node">Node object (should be in game tree) </param>
	/// <returns>Dictionary that has node data to spawn</returns>
	public Dictionary<string, Variant> GenerateNodePayloadData(Node node)
	{
		var payload = new Dictionary<string, Variant>()
		{
			{ MattohaSpawnKeys.Owner, node.GetMultiplayerAuthority() },
			{ MattohaSpawnKeys.SceneFile, node.SceneFilePath },
			{ MattohaSpawnKeys.NodeName, node.Name },
			{ MattohaSpawnKeys.ParentPath, node.GetParent().GetPath().ToString() },
		};
		if (node is Node2D)
		{
			payload[MattohaSpawnKeys.Position] = (node as Node2D).Position;
			payload[MattohaSpawnKeys.Rotation] = (node as Node2D).Rotation;
		}

		if (node is Node3D)
		{
			payload[MattohaSpawnKeys.Position] = (node as Node3D).Position;
			payload[MattohaSpawnKeys.Rotation] = (node as Node3D).Rotation;
		}
		return payload;

	}


	/// <summary>
	/// Send reliable server RPC to server, this will emmit "ServerRpcRecieved" on server node.
	/// </summary>
	/// <param name="methodName">method name you want to handle.</param>
	/// <param name="payload"></param>
	public void SendReliableServerRpc(string methodName, Dictionary<string, Variant> payload)
	{
		RpcId(1, nameof(ServerReliableRpc), methodName, payload);
	}


	/// <summary>
	/// Send reliable client RPC to peer, this will emmit "ClientRpcRecieved" on client node.
	/// </summary>
	/// <param name="peer">peer id that will recive the event, 0 for all</param>
	/// <param name="methodName">method name you want to handle.</param>
	/// <param name="payload"></param>
	public void SendReliableClientRpc(long peer, string methodName, Dictionary<string, Variant> payload)
	{
		if (peer == 0)
		{
			Rpc(nameof(ClientReliableRpc), methodName, payload);
		}
		else
		{
			if (Multiplayer.GetPeers().ToList().Contains((int)peer))
			{
				RpcId(peer, nameof(ClientReliableRpc), methodName, payload);
			}
		}
	}

	public bool IsNodeOwner(Node node)
	{
		if (Multiplayer.IsServer())
			return false;
		return node.GetMultiplayerAuthority() == Multiplayer.GetUniqueId();
	}


	public bool IsLobbyOwner()
	{
		if (Multiplayer.IsServer())
			return false;
		return Multiplayer.GetUniqueId() == Client.CurrentLobby[MattohaLobbyKeys.OwnerId].AsInt64();
	}


	[Rpc(MultiplayerApi.RpcMode.AnyPeer, TransferMode = MultiplayerPeer.TransferModeEnum.Reliable, TransferChannel = 2)]
	private void ServerReliableRpc(string methodName, Dictionary<string, Variant> payload)
	{
#if MATTOHA_SERVER
		EmitSignal(SignalName.ServerRpcRecieved, methodName, payload, Multiplayer.GetRemoteSenderId());
#endif
	}


	[Rpc(MultiplayerApi.RpcMode.AnyPeer, TransferMode = MultiplayerPeer.TransferModeEnum.Reliable, TransferChannel = 2)]
	private void ClientReliableRpc(string methodName, Dictionary<string, Variant> payload)
	{
#if MATTOHA_CLIENT
		EmitSignal(SignalName.ClientRpcRecieved, methodName, payload, Multiplayer.GetRemoteSenderId());
#endif
	}

}
