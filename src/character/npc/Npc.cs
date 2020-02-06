using System.Collections.Generic;
using Game.Ability;
using Game.Database;
using Game.Misc.Loot;
using Game.Misc.Other;
using Game.Ui;
using Game.Utils;
using Godot;
namespace Game.Actor
{
    public class Npc : Character
    {
        private string text;
        private Dictionary<string, List<Vector2>> cachedPatrolPath = new Dictionary<string, List<Vector2>>()
        { { "cachedPath", new List<Vector2>() }, { "pathPoints", new List<Vector2>() }, { "patrolPath", new List<Vector2>() }
        };
        [Signal]
        public delegate void DropLoot(Npc npc, Vector2 worldPosition, int idk);
        public override void _Ready()
        {
            base._Ready();
            SetProcess(false);
        }
        public override void _Process(float delta)
        {
            if (engaging && target != null)
            {
                if (origin.DistanceTo(target.GetCenterPos()) > Stats.FLEE_DISTANCE || target.dead)
                {
                    SetState(States.RETURNING);
                    if (cachedPatrolPath["cachedPath"].Count > 0)
                    {
                        // if (GlobalPosition != cachedPatrolPath["cachedPath"][patrolPath.Count - 1]) TODO
                        // {
                        // FollowPatrolPath();
                        // return;
                        // }
                    }
                    else if (GlobalPosition != origin)
                    {
                        MoveTo(origin, path);
                        return;
                    }
                    SetState(States.IDLE);
                }
                else if (!GetNode<AnimationPlayer>("anim").HasAnimation("attacking"))
                {
                    // flee code here
                }
                else if (GetCenterPos().DistanceTo(target.GetCenterPos()) > weaponRange)
                {
                    SetState(States.MOVING);
                    MoveTo(target.GlobalPosition, path);
                }
                else
                {
                    SetState(States.ATTACKING);
                }
            }
            else if (cachedPatrolPath["cachedPath"].Count > 0)
            {
                SetState(States.MOVING);
                FollowPatrolPath();
            }
            else
            {
                SetState(States.IDLE);
            }
        }
        public void _OnSightAreaEntered(Area2D area2D)
        {
            Character character = area2D.Owner as Character;
            if (character != null && !dead && (target == null || character.dead) && character != this)
            {
                if (!enemy && character is Player)
                {
                    // friendly npcs' don't attack player
                    return;
                }
                else if (!engaging && enemy != character.enemy)
                {
                    engaging = true;
                    target = character;
                    SetProcess(true);
                }
            }
        }
        public void _OnSightAreaExited(Area2D area2D)
        {
            if (!engaging)
            {
                target = null;
            }
        }
        public void _OnAreaMouseEntered()
        {
            Globals.player.SetProcessUnhandledInput(false);
        }
        public void _OnAreaMouseExited()
        {
            Globals.player.SetProcessUnhandledInput(true);
        }
        public override void _OnSelectPressed()
        {
            Player player = Globals.player;
            InGameMenu menu = player.GetMenu();
            if (player.target == this)
            {
                player.target = null;
            }
            else if (!player.dead)
            {
                player.target = this;
                Sprite img = GetNode<Sprite>("img");
                Tween tween = GetNode<Tween>("tween");
                tween.InterpolateProperty(img, ":scale", img.Scale, new Vector2(1.03f, 1.03f),
                    0.5f, Tween.TransitionType.Elastic, Tween.EaseType.Out);
                tween.Start();
                if (!enemy && !engaging && GetNode<Area2D>("sight").OverlapsArea(Globals.player.GetNode<Area2D>("area")))
                {
                    switch (worldType)
                    {
                        case WorldTypes.MERCHANT:
                        case WorldTypes.TRAINER:
                            string sndName = "merchant_open";
                            string nodeName = "inventory";
                            if (worldType == WorldTypes.MERCHANT)
                            {
                                menu.merchant.GetNode<Control>("s/v2/inventory").Show();
                            }
                            else
                            {
                                menu.merchant.GetNode<Control>("s/v2/inventory").Hide();
                                sndName = "turn_page";
                                nodeName = "spells";
                            }
                            foreach (Pickable pickable in GetNode(nodeName).GetChildren())
                            {
                                pickable.SetUpShop(false);
                            }
                            Globals.PlaySound(sndName, this, new Speaker());
                            tween.PauseMode = PauseModeEnum.Process;
                            menu.itemInfo.GetNode<TextureButton>("s/v/c/v/bg").Disabled = true;
                            menu.merchant.GetNode<Label>("s/v/label").Text = worldName;
                            menu.merchant.GetNode<Label>("s/v/label2").Text = $"Gold: {player.gold.ToString("N0")}";
                            menu.menu.Hide();
                            menu.merchant.Show();
                            menu.GetNode<Control>("c/game_menu").Show();
                            break;
                        default:
                            EmitSignal(nameof(Talked));
                            if (!text.Empty())
                            {
                                Globals.PlaySound("turn_page", this, new Speaker());
                                menu.menu.Hide();
                                if (worldType == WorldTypes.HEALER)
                                {
                                    menu.dialogue.GetNode<Control>("s/s/v/heal").Show();
                                }
                                else
                                {
                                    menu.dialogue.GetNode<Label>("s/s/label2").Text = text;
                                }
                                menu.dialogue.GetNode<Label>("s/label").Text = worldName;
                                menu.dialogue.Show();
                                menu.GetNode<Control>("c/game_menu").Show();
                            }
                            break;
                    }
                }
                else
                {
                    Globals.PlaySound("click4", this, new Speaker());
                }
            }
        }
        private void FollowPatrolPath()
        {
            if (cachedPatrolPath["patrolPath"].Count == 0)
            {
                cachedPatrolPath["pathPoints"].RemoveAt(0);
                if (cachedPatrolPath["pathPoints"].Count == 0)
                {
                    cachedPatrolPath["cachedPath"].Reverse();
                    cachedPatrolPath["pathPoints"] = cachedPatrolPath["cachedPath"].GetRange(0, cachedPatrolPath["cachedPath"].Count);
                }
                cachedPatrolPath["patrolPath"] = Globals.map.getAPath(GlobalPosition, cachedPatrolPath["pathPoints"][0]);
            }
            MoveTo(cachedPatrolPath["patrolPath"][0], cachedPatrolPath["patrolPath"]);
        }
        public override void MoveTo(Vector2 worldPosition, List<Vector2> route)
        {
            if (route == path && (route.Count == 0 || route[route.Count - 1].DistanceTo(worldPosition) > weaponRange))
            {
                path = Globals.map.getAPath(GlobalPosition, worldPosition);
            }
            else
            {
                Vector2 direction = GetDirection(GlobalPosition, route[0]);
                if (!direction.Equals(new Vector2()))
                {
                    worldPosition = Globals.map.RequestMove(GlobalPosition, direction);
                    if (!worldPosition.Equals(new Vector2()))
                    {
                        Move(worldPosition, Stats.MapAnimMoveSpeed(animSpeed));
                        route.RemoveAt(0);
                        SetProcess(false);
                    }
                    else
                    {
                        route.Clear();
                    }
                }
                else
                {
                    route.RemoveAt(0);
                }
            }
        }
        public override void TakeDamage(short damage, bool ignoreArmor, WorldObject worldObject, CombatText.TextType textType)
        {
            if (target == null && worldObject is Character)
            {
                target = (Character)worldObject;
            }
            base.TakeDamage(damage, ignoreArmor, worldObject, textType);
            if (dead && targetList.Count > 0)
            {
                List<short> damageList = new List<short>();
                foreach (short dam in targetList.Values)
                {
                    damageList.Add(dam);
                }
                if (damageList.Count > 0)
                {
                    short mostDamage = damageList[0];
                    foreach (short dam in damageList)
                    {
                        if (dam > mostDamage)
                        {
                            mostDamage = dam;
                        }
                    }
                    foreach (Character character in targetList.Keys)
                    {
                        if (targetList[character] == mostDamage && character is Player)
                        {
                            short xp = Stats.GetXpFromUnitDeath((double)level,
                                Stats.GetMultiplier(true, GetNode<Sprite>("img").Texture.ResourcePath), (double)character.level);
                            if (xp > 0)
                            {
                                ((Player)character).SetXP(xp);
                            }
                        }
                    }
                }
            }
        }
        public override async void SetDead(bool dead)
        {
            if (this.dead == dead)
            {
                return;
            }
            base.SetDead(dead);
            await ToSignal(GetNode<AnimationPlayer>("anim"), "animation_finished");
            GetNode<CollisionShape2D>("sight/distance").Disabled = true;
            if (dead)
            {
                EmitSignal(nameof(DropLoot), this, GlobalPosition, 0);
                Hide();
                SetProcess(false);
                GD.Randomize();
                SetTime((float)GD.RandRange(60.0, 240.0), true);
                if (!IsInGroup(Globals.SAVE_GROUP))
                {
                    AddToGroup(Globals.SAVE_GROUP);
                }
                GlobalPosition = origin;
            }
            else
            {
                hp = hpMax;
                mana = manaMax;
                SetProcess(true);
                if (IsInGroup(Globals.SAVE_GROUP))
                {
                    RemoveFromGroup(Globals.SAVE_GROUP);
                }
                Show();
                Sprite img = GetNode<Sprite>("img");
                Tween tween = GetNode<Tween>("tween");
                tween.InterpolateProperty(img, ":scale", img.Scale, new Vector2(1.03f, 1.03f),
                    0.5f, Tween.TransitionType.Elastic, Tween.EaseType.Out);
                tween.Start();
            }
        }
        public void CheckSight(Area2D area2D)
        {
            _OnSightAreaEntered(area2D);
        }
        public override void SetState(States state, bool overrule = false)
        {
            if (this.state != state || overrule)
            {
                AnimationPlayer anim = GetNode<AnimationPlayer>("anim");
                Sprite img = GetNode<Sprite>("img");
                switch (state)
                {
                    case States.IDLE:
                        SetProcess(false);
                        target = null;
                        SetTime(regenTime);
                        anim.Stop();
                        img.FlipH = false;
                        img.Frame = 0;
                        engaging = false;
                        foreach (Area2D area2D in GetNode<Area2D>("sight").GetOverlappingAreas())
                        {
                            CheckSight(area2D);
                        }
                        break;
                    case States.ATTACKING:
                        SetTime(weaponSpeed / 2.0f, true);
                        break;
                    case States.MOVING:
                        img.FlipH = false;
                        anim.Play("moving", -1, animSpeed);
                        anim.Seek(0.3f, true);
                        break;
                    case States.RETURNING:
                        SetState(States.MOVING);
                        SetTime(regenTime);
                        break;
                    case States.DEAD:
                        if (target != null && target is Player)
                        {
                            target.target = null;
                        }
                        SetState(States.IDLE);
                        SetDead(true);
                        break;
                }
                base.SetState(state);
            }
        }
        public void SetText(string text)
        {
            // TODO: possible bug here with "{0}"
            // probably get around this with Regex
            if (text.Contains("{0}") && worldType == WorldTypes.HEALER)
            {
                this.text = string.Format(text, Stats.HealerCost(Globals.player.level));
            }
            else
            {
                this.text = text;
            }
        }
        public void SetUpShop(InGameMenu inGameMenu, bool setUp)
        {
            Node bag = (worldType == WorldTypes.TRAINER) ? GetNode("spells") : GetNode("inventory");
            foreach (Pickable pickable in bag.GetChildren())
            {
                if (setUp)
                {
                    pickable.Connect(nameof(Pickable.SetInMenu), inGameMenu, nameof(InGameMenu._OnSetPickableInMenu));
                    pickable.Connect(nameof(Pickable.DescribePickable), inGameMenu, nameof(InGameMenu._OnDescribePickable));
                }
                else
                {
                    pickable.Disconnect(nameof(Pickable.SetInMenu), inGameMenu, nameof(InGameMenu._OnSetPickableInMenu));
                    pickable.Disconnect(nameof(Pickable.DescribePickable), inGameMenu, nameof(InGameMenu._OnDescribePickable));
                }
            }
        }
        public void SetData(Dictionary<string, string> data)
        {
            foreach (string key in data.Keys)
            {
                switch (key)
                {
                    case "spawnPos":
                        string[] spawnPos = data[key].Split(",");
                        origin = (new Vector2(float.Parse(spawnPos[0]), float.Parse(spawnPos[1])));
                        break;
                    case "path":
                        foreach (string point in data[key].Split("_"))
                        {
                            string[] xy = point.Split(",");
                            cachedPatrolPath["cachedPath"].Add(new Vector2(float.Parse(xy[0]), float.Parse(xy[1])));
                        }
                        cachedPatrolPath["pathPoints"] = cachedPatrolPath["cachedPath"].GetRange(0, cachedPatrolPath["cachedPath"].Count);
                        SetProcess(true);
                        break;
                    case "img":
                        SetImg(data[key]);
                        break;
                    case "name":
                        worldName = data[key];
                        break;
                    case "enemy":
                        enemy = bool.Parse(data[key]);
                        break;
                    case "level":
                        level = byte.Parse(data[key]);
                        break;
                    case "actorType":
                        worldType = (WorldTypes)System.Enum.Parse(typeof(WorldTypes), data[key].ToUpper());
                        break;
                    default:
                        if (key.Contains("spell"))
                        {
                            if (SpellDB.HasSpell(data[key]))
                            {
                                Spell spell = PickableFactory.GetMakeSpell(data[key]);
                                spell.GetPickable(this, false);
                            }
                            else
                            {
                                GD.Print($"({worldName}) has invalid spell name: ({data[key]})");
                            }
                        }
                        else if (key.Contains("item"))
                        {
                            if (ItemDB.HasItem(data[key]))
                            {
                                Item item = PickableFactory.GetMakeItem(data[key]);
                                item.GetPickable(this, false);
                            }
                            else
                            {
                                GD.Print($"({worldName}) has invalid item name: ({data[key]})");
                            }
                        }
                        else
                        {
                            GD.Print($"Unknown attribute value: {key} for unit.");
                        }
                        break;
                }
            }
        }
    }
}