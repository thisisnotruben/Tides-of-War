using Godot;
using System.Collections.Generic;
using Game.Misc.Other;

namespace Game.Actor
{
    public class TargetDummy : Npc
    {
        public override void _Ready()
        {
            SetProcess(false);
        }
        public override void _Process(float delta)
        {
        }
        public override void MoveTo(Vector2 WorldPosition)
        {
        }
        public override void Attack(bool ignoreArmor, Dictionary<string, Dictionary<string, ushort>> attackTable = null)
        {
        }
        public override void TakeDamage(short damage, bool ignoreArmor, WorldObject worldObject, CombatText.TextType textType)
        {
            base.TakeDamage(damage, ignoreArmor, worldObject, textType);
            hp = hpMax;
            mana = manaMax;
        }
        public override void SetDead(bool dead)
        {
        }
        public override void _OnSelectPressed()
        {
            if (Globals.player.GetTarget() == this)
            {
                Globals.player.SetTarget(null);
                SetTarget(null);
            }
            else
            {
                Globals.PlaySound("click4", this, new AudioStreamPlayer());
                Sprite img = GetNode<Sprite>("img");
                Tween tween = GetNode<Tween>("tween");
                tween.InterpolateProperty(img, ":scale", img.GetScale(), new Vector2(1.03f, 1.03f),
                    0.5f, Tween.TransitionType.Elastic, Tween.EaseType.Out);
                tween.Start();
                SetTarget(Globals.player);
                Globals.player.SetTarget(this);
            }
        }
    }
}