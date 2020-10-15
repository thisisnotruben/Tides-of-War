using Game.Database;
using Game.Ability;
using Game.Actor;
using Godot;
namespace Game.Projectile
{
	public class MissileSpell : Missile
	{
		public new static PackedScene scene = (PackedScene)GD.Load("res://src/projectile/MissileSpell.tscn");

		private Timer timer;
		protected string spellWorldName = string.Empty;

		public override void _Ready()
		{
			base._Ready();
			timer = GetNode<Timer>("timer");

			// can't add in Init due to this section needing nodes
			if (!spellWorldName.Equals(string.Empty) && SpellDB.HasSpellMissile(spellWorldName))
			{
				SpellDB.SpellMissileNode spellMissileNode = SpellDB.GetSpellMissileData(spellWorldName);
				img.Texture = spellMissileNode.img;
				hitboxBody.Shape = spellMissileNode.hitBox;
			}
		}
		public void Init(Character character, Character target, string spellWorldName)
		{
			this.spellWorldName = spellWorldName ?? string.Empty;

			Init(character, target);

			if (SpellDB.HasSpellMissile(spellWorldName))
			{
				SpellDB.SpellMissileNode spellMissileNode = SpellDB.GetSpellMissileData(spellWorldName);

				if (spellMissileNode.instantSpawn)
				{
					spawnPos = GlobalPosition = target.pos;
				}

				moveBehavior = () =>
				{
					if (spellMissileNode.rotate && !hit)
					{
						LookAt(target.pos);
					}

					if (spellMissileNode.reverse)
					{
						MoveMissile(target.pos, GlobalPosition);
					}
					else
					{
						MoveMissile(GlobalPosition, target.pos);
					}
				};
			}

			// instance spell effect visuals
			if (SpellDB.HasSpellEffect(spellWorldName))
			{
				SpellEffect spellEffect = SpellDB.GetSpellEffect(
					SpellDB.GetSpellData(spellWorldName).spellEffect);

				spellEffect.Init(target, spellWorldName, this);
				Connect(nameof(OnHit), spellEffect, nameof(SpellEffect.OnHit));
			}
		}
		public override void OnMissileFadeFinished(string animName) { timer.Start(); }
	}
}