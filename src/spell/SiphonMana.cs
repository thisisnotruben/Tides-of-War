using Game.Actor;
namespace Game.Ability
{
	public class SiphonMana : SpellProto
	{
		public SiphonMana(Character character, string worldName) : base(character, worldName) { }

		public override void Start()
		{
			base.Start();

			int siphonedAmount = (int)(character.target.mana * 0.25f);

			character.target.mana -= siphonedAmount;
			character.mana += siphonedAmount;
		}
	}
}