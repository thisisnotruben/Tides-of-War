using Game.Database;
using Godot;
using System.Collections.Generic;
using Game.Ui;
namespace Game.Quest
{
	public class WorldQuest : ISerializable
	{
		public readonly QuestDB.QuestData quest;
		private readonly Dictionary<string, int> objectives = new Dictionary<string, int>();
		private readonly List<NodePath> charactersTalkedTo = new List<NodePath>();

		public WorldQuest(QuestDB.QuestData quest)
		{
			this.quest = quest;
			foreach (string objectiveName in quest.objectives.Keys)
			{
				objectives[objectiveName] = quest.objectives[objectiveName].amount;
			}
		}
		public bool UpdateQuest(string objectiveName, QuestDB.QuestType questType, bool countTowardsObjective)
		{
			if (!objectives.ContainsKey(objectiveName)
			|| quest.objectives[objectiveName].questType != questType
			|| (!countTowardsObjective && quest.objectives[objectiveName].amount == objectives[objectiveName]))
			{
				return false;
			}
			objectives[objectiveName] += countTowardsObjective ? -1 : 1;
			return true;
		}
		public bool UpdateQuest(NodePath characterPath, string objectiveName, QuestDB.QuestType questType, bool countTowardsObjective)
		{
			if (charactersTalkedTo.Contains(characterPath))
			{
				return false;
			}
			else if (UpdateQuest(objectiveName, questType, countTowardsObjective))
			{
				charactersTalkedTo.Add(characterPath);
				return true;
			}
			return false;
		}
		public bool IsCompleted()
		{
			foreach (int objectiveAmount in objectives.Values)
			{
				if (objectiveAmount > 0)
				{
					return false;
				}
			}
			return true;
		}
		public void TurnInItems(InventoryModel playerInventory)
		{
			if (!IsCompleted())
			{
				return;
			}

			foreach (string objectiveName in quest.objectives.Keys)
			{
				if (!quest.objectives[objectiveName].keepWorldItems)
				{
					playerInventory.RemoveCommodity(objectiveName);
				}
			}
		}
		public bool HasCharacterPath(NodePath characterPath) { return charactersTalkedTo.Contains(characterPath); }
		public Godot.Collections.Dictionary Serialize()
		{
			Godot.Collections.Dictionary payload = new Godot.Collections.Dictionary();
			Godot.Collections.Array charactersPaths = new Godot.Collections.Array();

			foreach (string objectiveName in objectives.Keys)
			{
				payload.Add(objectiveName, objectives[objectiveName]);
			}

			charactersTalkedTo.ForEach(p => charactersPaths.Add(p.ToString()));
			payload.Add("talkedTo", charactersPaths);

			return payload;
		}
		public void Deserialize(Godot.Collections.Dictionary payload)
		{
			foreach (string objectiveName in payload.Keys)
			{
				objectives[objectiveName] = (int)payload[objectiveName];
			}

			foreach (string characterPath in (Godot.Collections.Array)payload["talkedTo"])
			{
				charactersTalkedTo.Add(new NodePath(characterPath));
			}
		}
	}
}