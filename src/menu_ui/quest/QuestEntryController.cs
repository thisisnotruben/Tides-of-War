using Godot;
namespace Game.Ui
{
	public class QuestEntryController : Control
	{
		// TODO
		// private Quest _quest;
		// public Quest quest
		// {
		// 	get
		// 	{
		// 		return _quest;
		// 	}
		// 	set
		// 	{
		// 		_quest = value;
		// 		GetNode<Label>("label").Text = quest.questName;
		// 		Name = quest.questName;
		// 	}
		// }
		public void AddToQuestLog(Node questLog)
		{
			questLog.GetNode("s/v/s/v").AddChild(this);
			questLog.GetNode("s/v/s/v").MoveChild(this, 0);
		}
		public void _OnQuestSlotPressed()
		{
			// Globals.player.menu.ShowQuestText(quest);
		}
	}
}