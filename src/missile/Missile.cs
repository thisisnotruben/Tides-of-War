using Game.Actor;
using Godot;
namespace Game.Projectile
{
	public class Missile : Node2D
	{
		protected Tween tween;
		protected AnimationPlayer anim;
		protected Sprite img;
		protected Area2D hitbox, targetHitBox;
		protected CollisionShape2D hitboxBody;

		protected Character character;
		protected Vector2 spawnPos;
		protected bool hit;

		[Signal] public delegate void OnHit();
		protected delegate void MoveBehavior(float delta);
		protected MoveBehavior moveBehavior;
		protected MoveBehavior moveMissile;

		public override void _Ready()
		{
			tween = GetNode<Tween>("tween");
			anim = GetNode<AnimationPlayer>("anim");
			img = GetNode<Sprite>("img");
			hitbox = GetNode<Area2D>("hitbox");
			hitboxBody = hitbox.GetNode<CollisionShape2D>("body");
		}
		public virtual void Init(Character character, Character target)
		{
			this.character = character;
			targetHitBox = target.hitBox;

			spawnPos = GlobalPosition = character.missileSpawnPos.GlobalPosition;

			moveBehavior = (float delta) =>
		   {
			   if (!hit)
			   {
				   LookAt(target.pos);
			   }
			   MoveMissile(GlobalPosition, target.pos);
		   };
		}
		public override void _PhysicsProcess(float delta) { moveBehavior?.Invoke(delta); }
		protected virtual void MoveMissile(Vector2 startPos, Vector2 targetPos)
		{
			tween.StopAll();
			tween.InterpolateProperty(this, ":global_position", startPos, targetPos,
				spawnPos.DistanceTo(targetPos) / character.stats.weaponRange.value,
				Tween.TransitionType.Circ, Tween.EaseType.Out);
			tween.Start();
		}
		public void OnHitBoxEntered(Area2D area2D)
		{
			if (!hit && area2D == targetHitBox)
			{
				hit = true;
				ZIndex = 1;

				EmitSignal(nameof(OnHit));

				anim.Play("missileFade");
			}
		}
		public virtual void OnMissileFadeFinished(string animName) { Delete(); }
		protected void Delete()
		{
			SetProcess(false);
			tween.RemoveAll();
			QueueFree();
		}
	}
}