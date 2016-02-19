pico-8 cartridge // http://www.pico-8.com
version 5
__lua__

-- simple simon: by @doubtfulbros
-- what an ordeal!
-- GitHub: @tjacobdesign

t = 0
dead_time = 0
game_end = false
music_on = true
message = "hello world"
player_start = {x=32,y=80} -- x=1832,y=40
flags = {
  collision = 0,
  deadly = 1,
  bouncy = 2,
  gravity = 4,
  trigger = 5,
  save = 6,
  no_collision = 7
}
lvl = {
  animations = {},

  init = function(playerx, playery)
    player = entity(player_type, playerx, playery)
    player.checkpoint = {x=player.x, y=player.y}
    player.weapon = 'pumpkin'
    lvl.current_lvl.boss_played = false
    add(entities, player)

    bugs = {
      {40, 10},
      {52, 10},
      {84, 10},
      {97, 4},
      {119, 1},
      {20, 11},
      {33, 10},
      {25, 6},
      {125, 4}
    }

    flyers = {
      {150, 4},
      {84, 5},
      {106, 4}
    }

    if (music_on) music(1, 0, 1+2+4)

    for bug in all(bugs) do
      add(entities, entity(bug_type, bug[1] * 8, bug[2] * 8 + 3))
    end

    for fly in all(flyers) do
      local b = entity(bug_type, fly[1] * 8, fly[2] * 8 + 3)
      b.flying = true
      b.health = 2
      b.walk_anim = {125,126}
      b.walk_speed = 0.8
      b.air_spr = {125,125}
      add(entities, b)
    end

    boss = entity(boss_type, 1950, 8*11)
    add(entities, boss)
  end,

  update = function(_)
    if game_end then return end
    -- update time
    t += 1

    update_controls()

    for e in all(entities) do
      if e.type.update != nil then
        e.type.update(e)
      else
        update_entity(e)
      end
    end
  end,

  draw = function(_)
    if (player.x < 1880 and not _.current_lvl.boss_played) then
      camera(clamp(player.x - 64, 0, 1884), -10)
    else
      _.current_lvl.play_boss(_)
    end
    _.current_lvl.draw()
    _.draw_animations(_)

    for e in all(entities) do
      if e.type.draw then
        e.type.draw(e)
      else
        draw_entity(e)
      end
    end
    camera()
    -- drawing hearts
    for n = 1,3 do
      s = 6
      if n > player.health then
        s = 7
      end
      spr(s, n * 8, 0)
    end
  end,
  draw_animations = function(_)
    for an in all(_.animations) do
      an.step(an)
    end
  end,

  start = {
    init = function()
      music(1)
    end,

    draw = function()
      map(32,49,0,0,16,16)
    end,

    update = function()
      if btnp(5) then
        scr.current_init = lvl.init
        scr.current_update = lvl.update
        scr.current_draw = lvl.draw
      end
    end
  },

  one = {
    enemies = {},
    boss_played = false,
    -- world should be in reverse order
    world = {
      {0,16,1024,0,160,16},
      {0,0,0,0,160,16}
    },
    triggers = {
      {
        id = 't2128',
        end_sprite = 43,
        tiles = {
          {20,23},
          {20,22},
          {21,22},
          {22,22},
          {21,21},
          {22,21}
        },
        easter = 7
      },
      {
        id = 't11322',
        end_sprite = 43,
        incrementally = true,
        tiles = {
          {115,17},
          {115,18},
          {115,19}
        }
      }
    },

    play_boss = function(_)
      if (not _.current_lvl.boss_played) then
        music(-1)
        sfx(16)
        _.current_lvl.boss_start = t
      end
      _.current_lvl.boss_t = t - _.current_lvl.boss_start
      _.current_lvl.boss_played = true
      local boss_t = _.current_lvl.boss_t
      
      if boss_t < 50 then
        local change = 1864 - (player.x - 64)
        local linear = change * boss_t / 50 + (player.x - 64)
        camera(linear, -10)
        _.current_lvl.controls_disabled = true
      else
        camera(1864, -10)
        _.current_lvl.controls_disabled = nil
        if (not _.current_lvl.music_on) then
          music(9, 0, 1+2+4)
          _.current_lvl.music_on = true
        end
      end

      if not _.fire_going then
        local fire = {
          x = 1968,
          y = 88,
          type = {
            height = 8, width = 8
          }
        }
        local f = create_anim(fire, {156,157}, 4)
        play_anim(f, true)
        _.fire_going = true
      end
    end,

    draw = function()
      map(0,0,0,0,160,16)
      map(0,16,1024,0,160,16)
    end
  },

  fin = {
    cam = {
      x = 8*16,
      y = 0
    },
    init = function(_)
      boss = entity(boss_type, 24*8, 13*8)
      add(entities, boss)
      boss.visible = true
      boss.type.stand_spr = 130
      _pf = nil

      music(12)

      apple_dude = {
        x = 72, y = 112,
        type = {
          width = 8, height = 8
        }
      }
      smoke1 = {
        x = 64, y = 112,
        type = {
          width = 8, height = 8
        }
      }
      smoke2 = {
        x = 80, y = 112,
        type = {
          width = 8, height = 8
        }
      }
      dude_smoke = create_anim(apple_dude, {185,177,185,177,185,177})
      dude = create_anim(apple_dude, {178,179,180,181,176})
      smoke1_anim = create_anim(smoke1, {158,174,190}, 9)
      smoke2_anim = create_anim(smoke2, {159,175,191}, 9)
    end,

    update = function(_)
      t += 1
      local lt = t - lvl.fin.t

      if lt > 20 and lt < 30 and boss.visible then
        play_anim(boss.animations.roll_dough)
        boss.type.stand_spr = 73
      end

      if lt > 125 and lt < 130 then
        boss.type.stand_spr = 101
      end

      if lt > 150 and lt < 300 then
        local nt = lt - 150
        local change = 0 - _.fin.cam.x
        local linear = change * nt / 200 + _.fin.cam.x
        _.fin.cam.x = linear
      end
    end,

    draw = function(_)
      local lt = t - lvl.fin.t

      camera(lvl.fin.cam.x, lvl.fin.cam.y)
      map(0,48,0,0,500,16)

      if (boss.visible) draw_entity(boss)

      _.draw_animations(_)

      if (lt > 230 and lt < 240) then
        mset(9, 62, 0)
        spr(184, 72, 112)
        music(-1)
        sfx(16)
      end
      if (lt > 240 and lt < 315) spr(185, 72, 112)

      if (lt > 310 and not _.boss_music) then
        music(9, 0, 1+2+4)
        _.boss_music = true
      end

      if (lt > 330 and lt < 385) spr(177,apple_dude.x,apple_dude.y)

      if (lt > 310 and lt < 320) then
        play_anim(dude_smoke)
        play_anim(smoke1_anim)
        play_anim(smoke2_anim)
      end

      -- walk away
      if (lt > 380 and lt < 390) then
        spr(0, 72, 112)
        play_anim(dude, true)
      end

      if (lt > 400) then
        apple_dude.x += 1.5
      end

      if (apple_dude.x > 128 and apple_dude.x < 135) then
        fade(0,-100,12)
      end

      if (apple_dude.x > 135 and _pf == 1) then
        scr.current_draw = lvl.goodbye.draw
        scr.current_update = lvl.goodbye.update
        lvl.goodbye.init(lvl)
      end

      camera()
    end
  },

  goodbye = {
    init = function(_)
      _.start_t = t
      fade(-100,0,12)
    end,
    update = function(_)
      t += 1
      local lt = t - _.start_t

      if (lt > 55) _.firstmess = true
      if (lt > 75) _.secondmess = true
    end,
    draw = function(_)
      pal()
      print('enjoy the pie', 38, 45, 7)

      if (_.firstmess) print('you monster', 41, 60, 9)
      if (_.secondmess) print('merry christmas!', 33, 75, 7)
    end
  }
}


scr = {
  current_init = lvl.start.init,
  current_update = lvl.start.update,
  current_draw = lvl.start.draw
}

player_type = {
  height = 8, width = 5,
  anim_frame_delay = 3,
  air_spr={67,68},
  walk_anim = {66,67,68,69,64},
  stand_spr = 65,
  walk_speed = 2, walk_accel = 0.3,

  init = function(_)
    _.last_shot = 0
    _.dir_y = 0
    _.health = 3
    _.last_hurt = 0
    _.invincible = false
    _.weapon = 'pumpkin'
  end,

  shoot = function(_)
    if t - _.last_shot > 10 then
      _.last_shot = t

      local incr = 5
      if (_.dir < 0) incr = -2
      local a = entity(bullet_type, _.x - incr, _.y)

      if _.dir > 0 then
        a.x += 3
      end

      if _.dir_y == 0 then 
        a.dir = _.dir
        a.y += 3
      else
        a.dir = 0
        a.y += 1
      end
      a.b_type = 'pumpkin'
      a.dir_y = _.dir_y
      add(entities, a)
      sfx(0)
    end
  end,

  draw = function(_)
    if not _.invincible or t % 2 == 0 then
      draw_entity(_)
    end
  end,

  update = function(_)
    update_entity(_)
    if (t - _.last_hurt > 19) _.invincible = false
    if check_map_collision(_, flags.save) then
      if player.x + 100 > player.checkpoint.x and player.x - 100 < player.checkpoint.x then

      else
        sfx(3)
        player.checkpoint = {x=player.x, y=player.y}
        player.health = 3
      end
    end

    if check_map_collision(_, flags.deadly) then
      player.type.wound()
    end

    if check_map_collision(_, flags.bouncy) then
      if player.vy > 1 then
        player.vy = -24
        player.is_grounded = false
        -- pie sprite: 109

        local pie = {
          x=flr(player.x / 8) * 8,
          y=flr(player.y / 8) * 8 + 8,
          type = {
            height=8, width=8
          }
        }
        local pie_check = wget(pie.x, pie.y)
        if (pie_check != 109) pie.x += 8

        wset(pie.x, pie.y, 110)
        local pie_anim = create_anim(pie, {110,109,111}, 2)
        pie_anim.callback = function()
          wset(pie.x, pie.y, 109)
        end
        play_anim(pie_anim)
        sfx(8)
      end
    end

    if player.y > 150 then
      player.type.death()
    end
  end,

  wound = function()
    if not player.invincible then
      player.health -= 1
      player.last_hurt = t
      player.invincible = true
      if player.health <= 0 then
        player.type.death()
        return
      else
        sfx(4) -- hurt sound
      end
    end
  end,

  death = function()
    -- restart at last checkpoint
    if (music_on) music(-1)

    local an = create_anim(player, {80,81,82,81,80}, 6)

    play_anim(an)
    sfx(2)

    an.callback = function()
      entities = {}
      lvl.init(player.checkpoint.x, player.checkpoint.y)
      lvl.current_lvl.boss_played = false
      lvl.current_lvl.music_on = false
    end
  end
}

function play_anim(anim, rep)
  anim.start_t = t
  anim.rep = rep or false
  add(lvl.animations, anim)
end

function create_anim(ent, frames, delay)
  delay = delay or 3
  local an_type = {
    start_t = t,
    start_frame = 1,
    frames = frames
  }
  an_type.step = function(an)
    local t2 = t - an.start_t
    local frame = flr(t2 / delay) + 1
    ent.visible = false
    ent.animating = true

    if (frame < #frames + 1) then
      spr(frames[frame],ent.x,ent.y,ent.type.width / 8, ent.type.height / 8)
      if (an.callback_frame and an.callback_frame == frame and not an.calledback) then
        an.callback(ent)
        an.calledback = true
      end
    else
      if (an.rep) then
        an.start_t = t
        return
      end
      del(lvl.animations, an)
      ent.visible = true
      ent.animating = false
      if (an.callback and not an.calledback) an.callback(ent)
      if (an.animating) an.animating = false
    end
  end
  return an_type
end

bug_type = {
  width = 8, height = 5,
  anim_frame_delay = 3,
  stand_spr=8,
  walk_accel = 0.2,

  init = function(_, walk_anim, walk_speed)
    _.last_swap = 0
    _.dir = -1
    _.dir_y = -1
    _.health = 3
    _.walk_speed = 1
    _.walk_anim = {8,9}
    _.air_spr = {8,8}
    _.last_hurt = 0
    _.invincible = false
  end,

  wound = function(_)
    if not _.invincible then
      _.health -= 1
      _.last_hurt = t
      _.invincible = true
      if _.health <= 0 then
        del(entities, _)
        sfx(5) -- deadbug
        return
      else
        sfx(4) -- hurt sound
      end
    end
  end,

  update = function(_)
    if (t - _.last_hurt > 10) _.invincible = false
    if is_entity_collision(_, player) then
      player.type.wound(_)
    end
    if (_.moving) then
      update_entity(_)
      _.vx = _.walk_speed * _.dir
      if _.flying then _.vy = _.walk_speed * _.dir_y end
      if t - _.last_swap > 10 then 
        _.last_swap = t
        if _.x > player.x then
          _.dir = -1
        else
          _.dir = 1
        end

        if _.flying and _.y > player.y then
          _.dir_y = -1
        else
          _.dir_y = 1
        end
      end
    end
    if abs(_.x - player.x) < 36 then _.moving = true end
  end,

  draw = function(_)
    if not _.invincible or t % 2 == 0 then
      draw_entity(_)
    end
  end
}

boss_type = {
  width = 16, height = 16,
  anim_frame_delay = 3,
  stand_spr = 73,
  speed = 1,
  no_rotate = true,
  pie_box_sprites = {32,17,1,16},
  init = function(_)
    _.pie_time = 200
    _.last_shot = t
    _.pie_stock = 1
    _.dir = -1
    _.dir_y = -1
    _.animations = {
      throw_pie = create_anim(_, {101,103,105,107,107,107}, 9),
      roll_dough = create_anim(_, {97,99,97,99,97,99,97,99}, 9),
      throw_spoon = create_anim(_, {73,75,77,77}, 9),
      check_apple = create_anim(_, {128,130,130,132,130,132,130}, 9),
      check_pump = create_anim(_, {128,172}, 9)
    }
    _.awake = false
  end,

  update = function(_)
    if _.awake then
      update_entity(_)
      local roll_time = _.last_shot + _.pie_time / 2

      if not _.animating then
        if _.pie_stock > 1 and _.last_shot + _.pie_time < t then
          _.type.throw_pie(_)
        end
        if _.pie_stock > 1 and roll_time < t and roll_time + 10 > t then
          play_anim(_.animations.roll_dough)
        end
        if _.pie_stock <= 1 and roll_time < t then
          _.last_shot = t
          _.type.throw_spoon(_)
        end
      end
    else
      if (not lvl.current_lvl.boss_beat) then
        if (lvl.current_lvl.boss_t and lvl.current_lvl.boss_t > 50) _.awake = true
      end
    end
  end,

  throw_pie = function(_)
    if _.pie_stock > 1 then
      _.last_shot = t
      play_anim(_.animations.throw_pie)
      _.animations.throw_pie.calledback = false
      _.animations.throw_pie.callback_frame = 4
      _.animations.throw_pie.callback = _.type.shoot_pie
    end
  end,

  throw_spoon = function(_)
    play_anim(_.animations.throw_spoon)
    _.animations.throw_spoon.calledback = false
    _.animations.throw_spoon.callback_frame = 3
    _.animations.throw_spoon.callback = _.type.shoot_spoon
  end,

  add_pumpkin = function(_)
    if (_.pie_stock <= 3) _.pie_stock += 1
  end,

  shoot_pie = function(_)
    _.pie_stock -= 1
    _.pie_time -= 50

    local b = entity(bullet_type, _.x, _.y)
    b.gravity = true
    b.walk_anim = {109,111}

    b.b_type = 'pie'
    b.height = 8
    b.width = 8
    b.speed = 1.5
    b.hostile = true
    b.x -= 3
    b.y -= 3
    b.dir = -1
    b.dir_y = -1
    add(entities, b)
    _.type.throw_spoon(_)

    sfx(0)
  end,

  shoot_spoon = function(_)
    local b = entity(bullet_type, _.x, _.y)
    b.gravity = true
    b.walk_anim = {4,5,20,21}

    b.b_type = 'spoon'
    b.height = 4 b.width = 4
    b.speed = 2
    b.hostile = true
    b.x -= 3
    b.y -= 9
    b.dir = -1
    b.dir_y = -1
    add(entities, b)

    sfx(0)
  end,

  draw = function(_)
    local pie_box = _.type.pie_box_sprites[_.pie_stock]

    spr(pie_box, _.x - 12, _.y + 8)

    draw_entity(_)
  end,

  death = function(_)
    for e in all(entities) do
      if e.type == bullet_type then
        del(entities, e)
      end
    end

    _.type.update = function()
      if (t - _.deadtime > 150 and t - _.deadtime < 160) then
        lvl.animations = {}
        play_anim(_.animations.check_apple)
        _.animations.check_apple.callback = function()
          _.apple_showing = true
        end
      end
    end

    _.type.draw = function()
      if not _.apple_showing then
        draw_entity(_)
      else
        spr(130, _.x, _.y, _.type.width / 8, _.type.height / 8)
        mset(_.x-16, _.y, 182)
        if not lvl.current_lvl.fade then
          fade(0,-100,12)
          lvl.current_lvl.fade = true
        end
        if _pf == 1 then
          --fade is done
          entities = {}
          lvl.animations = {}
          lvl.fin.init()
          scr.current_draw = lvl.fin.draw
          scr.current_update = lvl.fin.update
          lvl.fin.t = t
          fade(-100,0,12)
        end
      end
    end
  end
}

bullet_type = {
  anim_frame_delay = 3,
  init = function(_)
    _.width = 5
    _.height = 5
    _.lifetime = 160
    _.last_swap = 0
    _.speed = 2.2
    _.bounce = 0
    _.always_moving = true
    _.gravity = true
    _.walk_anim = {80,81,82}
    _.hostile = false
  end,

  update = function(_)
    _.x += _.dir * _.speed
    _.y += _.dir_y * _.speed
    _.lifetime -= 1

    local collision = check_map_collision(_)
    if (not _.no_collision) _.no_collision = check_map_collision(_, flags.no_collision)

    if _.lifetime <= 0 then
      del(entities, _)
      return
    end

    if _.hostile == false then
      -- don't hurt plater, hurt enemies
      for e in all(entities) do
        if e.type == bug_type and is_entity_collision(_, e) then
          del(entities, _)
          e.type.wound(e)
          return
        end
      end
    else
      if is_entity_collision(_, player) then
        if _.b_type != 'pie' or player.vy < 1 then
          player.type.wound(_)
          del(entities, _)
        else
          player.vy = -24
        end
      end
    end

    if not _.hostile and is_entity_collision(_, boss) then
      boss.type.add_pumpkin(boss)
      del(entities, _)
    end

    if e.b_type == 'pumpkin' and check_map_collision(_, flags.trigger) then
      local c = wget(_.x, _.y, true)
      local id = 't'..c.x..c.y

      for tr in all(lvl.current_lvl.triggers) do
        if tr.id == id then
          sfx(15) --only do this once

          if tr.incrementally then
            if (not tr.i) tr.i = 1

            if (tr.tiles[tr.i]) handle_apple(tr, tr.tiles[tr.i])
            tr.i += 1

            if (tr.i > 3) then
              boss.awake = nil
              lvl.current_lvl.boss_beat = true
              boss.type.death(boss)
              boss.deadtime = t
              mset(tr.x,tr.y)
              music(-1)
            end
          else
            for ti in all(tr.tiles) do
              handle_apple(tr, ti)
            end
          end

          if (tr.count) then
            tr.count += 1
          else
            tr.count = 1
          end

          if tr.easter and tr.easter <= tr.count then
            mset(c.x, c.y - 1, 141)

            face = {
              playing = false,
              start_t = t,
              step = function(f_)
                if (not f_.rnd_seed) then
                  f_.rnd_seed = rnd(10) + 20
                end
                
                local ent = {
                  x = flr(_.x / 8) * 8,
                  y = flr(_.y / 8) * 8 - 8,
                  type = {
                    width=8,height=8
                  }
                }

                if (not f_.playing and f_.rnd_seed + f_.start_t < t) then
                  f_.playing = true
                elseif (f_.playing and f_.rnd_seed + f_.start_t < t - f_.rnd_seed) then
                  f_playing = false
                  f_.rnd_seed = nil
                  f_.start_t = t
                end
              end
            }
            play_anim(face)
          end

          del(entities, _)
        end
      end
    end

    if check_map_collision(_, flags.deadly) then
      del(entities, _)
    end

    if _.gravity == true then
      if collision and not _.no_collision then
        if _.bounce < 3 then
          _.dir *= -1
          _.bounce += 1
          _.x += _.dir * _.speed

          -- hack fix for a crash
          if _.is_grounded then
            _.y += _.dir_y * _.speed
          else
            _.y += _.dir_y * _.speed * -1
          end
        else
          del(entities, _)
          return
        end
      end

      update_entity(_)
    elseif collision and not _.no_collision then
      del(entities, _)
    end
  end,

  draw = function(_)
    if _.gravity == true then
      draw_entity(_)
    else
      -- generic energy shot frame
      bspr = 24
      if (abs(_.dir) < abs(_.dir_y)) bspr = 23
      spr(bspr, _.x, _.y)
    end
  end
}

function handle_apple(tr, ti)
  mset(ti[1],ti[2],tr.end_sprite)

  local spr = mget(ti[1],ti[2] - 1)

  if (spr == 25) then -- hack
    if (not lvl.current_lvl.apples) then lvl.current_lvl.apples = 0
    else lvl.current_lvl.apples += 1 end
    mset(ti[1],ti[2] - 1, tr.end_sprite)
    
    local apple = {
      spr = 25,
      x = ti[1],
      y = ti[2],
      step = function(_)
        local time = t - _.start_t
        local s = flr(time / 10)

        if (not _.s or _.s != s) then
          _.s = s
          local y = _.y + s
          
          if (_.below_tile) _.above_tile = _.below_tile
          _.below_tile = mget(_.x, y + 1)

          mset(_.x, y, _.spr)
          if (s > 0) mset(_.x, y - 1, _.above_tile)

          if (fget(_.below_tile) != flags.collision) then
            del(lvl.animations, _)
          end
        end
      end
    }

    play_anim(apple)
  end
end

entities = {}

function entity(type, x, y)
  e = {
    type = type,
    x = x, y = y,
    vx = 0, vy = 0,
    moving = false,
    dir = 1,
    frame = 1,
    is_grounded = false,
  }
  if type.init != nil then type.init(e) end
  return e
end

function _init()
  lvl.current_lvl = lvl.one
  lvl.init(player_start.x, player_start.y)
end

function _update()
  scr.current_update(lvl)

  if(_pf>0) then --pal fade
    if(_pf==1) then _pi=_pe
    else _pi+=((_pe-_pi)/_pf) end
    _pf-=1
  end
end

function _draw()
  cls() camera()
  
  scr.current_draw(lvl)

  local pix=6+flr(_pi/20+0.5)
  if(pix!=6) then
      for x=0,15 do
          pal(x,_shex[sub(_pl[x],pix,pix)],1)
      end
  else pal() end
end

function update_controls()
  -- handle input
  if not lvl.current_lvl.controls_disabled then
    if btn(0) then
      player.dir = -1
      player.moving = true
      if not player.moving then
        player.frame = 0
      end
    elseif btn(1) then
      player.dir = 1
      player.moving = true
      if not player.moving then
        player.frame = 0
      end
    else
      player.moving = false
    end

    if btn(2) then player.dir_y = -1
    elseif btn(3) and not player.is_grounded then player.dir_y = 1
    else player.dir_y = 0 
    end

    if btn(4) and player.is_grounded then
      player.vy = -4
      player.is_grounded = false
    end

    if btn(5) then
      -- not entirely happy with this solution, but works for now
      if not btn(3) then
        player.type.shoot(player)
      end
    end
  else
  -- controls disabled
    player.dir = 0
    player.moving = false
  end
end

function update_entity(e)
  local walk_speed = e.walk_speed or e.type.walk_speed
  if e.moving then
    e.vx = clamp(e.vx + e.type.walk_accel * e.dir, -walk_speed, walk_speed)
  else
    e.vx *= 0.8
    if abs(e.vx) < 1 then e.vx = 0 end
  end

  e.x += e.vx
  if check_map_collision(e) and not e.no_collision then
    repeat
      e.x -= sign(e.vx)
    until not check_map_collision(e)
    e.vx = 0
  end

  e.y += e.vy
  if check_map_collision(e) then
    if e.b_type != 'pumpkin' or not check_map_collision(e, flags.no_collision) then
      repeat
        e.y -= sign(e.vy)
      until not check_map_collision(e)
      e.is_grounded = e.vy > 0
      e.vy = 0
    end
  end

  if not e.flying then 
    e.vy = clamp(e.vy + 0.3, -4, 5)
  else
    e.vx = clamp(e.vy + e.type.walk_accel * e.dir_y, -walk_speed, walk_speed)
  end

  local walk_anim = e.walk_anim or e.type.walk_anim
  if t % e.type.anim_frame_delay == 0 and (e.moving or e.always_moving) then
    e.frame = (e.frame + 1) % #walk_anim 
  end
end

function draw_entity(e)
  local ldir = e.dir
  local walk_anim = e.walk_anim or e.type.walk_anim
  local air = e.air_spr or e.type.air_spr
  local width = e.width or e.type.width
  local height = e.height or e.type.height
  if e.type.no_rotate then ldir = 0 end
  
  if e.visible != false then
    if not e.is_grounded and air then
      local air_spr
      if e.vy < 0 then
        air_spr = air[1]
      else
        air_spr = air[2] 
      end
      spr(air_spr, e.x, e.y, width / 8, height / 8, ldir < 0)
    elseif e.moving or not e.type.stand_spr then
      spr(walk_anim[e.frame + 1], e.x, e.y, width / 8, height / 8, ldir < 0)
    else
      spr(e.type.stand_spr, e.x, e.y, width / 8, height / 8, ldir < 0)
    end
  end
end

function check_map_collision(e, f)
  f = f or flags.collision
  local is_solid = false
  local width = e.width or e.type.width
  local height = e.height or e.type.height
  is_solid = solid(e.x / 8, e.y / 8, f)
  is_solid = (is_solid or solid(e.x / 8, (e.y + height - 1) / 8, f))
  is_solid = (is_solid or solid((e.x + width - 1) / 8, (e.y + height - 1) / 8, f))
  is_solid = (is_solid or solid((e.x + width - 1) / 8, e.y / 8, f))
  return is_solid
end

function solid(x, y, f)
  local s = wget(x * 8, y * 8)
  local is_solid = fget(s, f)
  return is_solid
end

function wget(x, y, coords)
  -- checking the coordinates of the constructed world, rather than the image itself
  -- {0,16,1024,0,160,16}
  -- {0,0,0,0,160,16},

  for a in all(lvl.current_lvl.world) do
    if x >= a[3] - a[1] then
      ax = x + (a[1] * 8) - a[3]
      ay = y + (a[2] * 8) - a[4]

      if coords then return {x=flr(ax / 8), y=flr(ay / 8)} end
      return mget(ax / 8, ay / 8)
    end
  end
  return mget(x,y)
end

function wset(x, y, tile)
  -- checking the coordinates of the constructed world, rather than the image itself

  for a in all(lvl.current_lvl.world) do
    if x >= a[3] - a[1] then
      ax = x + (a[1] * 8) - a[3]
      ay = y + (a[2] * 8) - a[4]

      mset(ax / 8, ay / 8, tile)
    end
  end
  mset(x,y, tile)
end

function is_entity_collision(e1, e2)
  local width = e2.width or e2.type.width
  local height = e2.height or e2.type.height
  local x_overlap = range(e1.x, e2.x, e2.x + width) or
                    range(e2.x, e1.x, e1.x + width);

  local y_overlap = range(e1.y, e2.y, e2.y + height) or
                    range(e2.y, e1.y, e1.y + height);

  return x_overlap and y_overlap;
end

-- utility functions
function clamp(n, min, max)
  if n < min then return min end
  if n > max then return max end
  return n
end

function sign(n)
  if     n > 0 then return 1
  elseif n < 0 then return -1
  else   return 0
  end
end

function range(n, min, max)
  return (n <= max and n >= min)
end

  _shex={["0"]=0,["1"]=1,
["2"]=2,["3"]=3,["4"]=4,["5"]=5,
["6"]=6,["7"]=7,["8"]=8,["9"]=9,
["a"]=10,["b"]=11,["c"]=12,
["d"]=13,["e"]=14,["f"]=15}
_pl={[0]="00000015d67",
     [1]="0000015d677",
     [2]="0000024ef77",
     [3]="000013b7777",
     [4]="0000249a777",
     [5]="000015d6777",
     [6]="0015d677777",
     [7]="015d6777777",
     [8]="000028ef777",
     [9]="000249a7777",
    [10]="00249a77777",
    [11]="00013b77777",
    [12]="00013c77777",
    [13]="00015d67777",
    [14]="00024ef7777",
    [15]="0024ef77777"}
_pi=0-- -100=>100, remaps spal
_pe=0-- end pi val of pal fade
_pf=0-- frames of fade left
function fade(from,to,f)
    _pi=from _pe=to _pf=f
end

__gfx__
00000000000000000000777777770000002400004000000000000000000000000f2000000f200000bbbbbbbbbabbbbbb55555555005d50006d0d000016d10000
00000000000000000006666666666000004400000400000000000300000000002ff480482ff4804833333333a3aa33335d55555500056500d06d06d11d110d11
000000000ba90430000065777756000004000000004200000000b00000000000f44448202f44482044444444a9a99444555555550006d50006d00d105d550d10
00000000a999944400000f5ff540000040000000004400000009940000000100f0f844400f8f4440454445449999454455555555005d500000006d0005d65100
00000000dddd111100000fcffc40000000000000000000000099994000001000f0f80f800f8f08f0444444449a94494455555555005d5000606d00d0156d55d0
0000000005511110000008ffff800000000000000000000000999490009442000000000000000000545454549959545455555d55005d60000dd00d10015dd655
0000000005151110000000477400000000000000000000000094949009424200000000000000000045454545a9959545555555550006d500dd00d10dd1056ddd
00000000055111100000d6d55d6d0024000000000000000000049400444222200000000000000000555555559a5a5555555555550005d500100000d1100055d5
0004300000000000000d50777705d04400040000440000005555559508000800080000803b000bbb0bbbbbbb999655d555555555d1010000d1010000dd6ddd6d
0044220000000000000f006776000f0000400000240000005d55555a0800080008000080083e3200b3333333996555555555555500d10d1110d10d1156555655
0ba924300ba9000000000066660040002400000000400000555955a90800080008000080877f88203444444499965555555555550d100d100d100d100d100d10
a9999444a9999000ffffffffffffffff440000000004000055555a9a8220822002000820f7f888204544454499965555515551550000d1000000d1000000d100
dddd1111dddd1111444444444444444400000000000000005595999911221122822082008f88881044444444996555555555555500d100d0105105d010d100d1
05511110055111100450066666600540000000000000000095599999223322332222222088e888104545454599655d551515151500000d1005d55d500d100d10
05151110051511100450676722440540000000000000000055999a9933b333b333b32222228882105454545499965555515151510000010d55d5d5d5d100110d
05511110055111100451111642940540000000000000000059999999bb2bbb2bbb2bbbb201221100455555559996555511111111000000d15ddddd55100000d1
0000000000000000aaaaaaaa999999990099b200999779993bb3bb313b333333bbb3bbb003bbbbbbbbbbbbb0d101000000000006d10100000000000055dddd55
0000000000000000aaaaaaaa999999990943492099777799bbbbb3bbb3333331bbbbbb3003bb1b3b3333333b10d10d110000061110d10d11000000005d1101d5
0000000000000000a9a9a9a99999999997a9922099577ff93b3bbbbbb3333333bb1bbbb003bbbbbb444444430d100d1000060d100d10011000000000d5101065
00000000000000009a9a9a9a99999999aaa492209777fff91bbbbbb3b33333333bbbbb300bbbbbbb445444540000d1000000d1000000d10000000000d101010d
dddd11110000000099999999999999999a94922099ff5f99bbbbbbbb13333b33bbb3bb1003bbbbbb4444444410d100d0006100d010d1000000000000d110000d
05511110000000009a999a999999999994929220999999793bbbb3bb3b333333bbbbb300001bbb3b545454540d100d1006100d100d100000000000005100000d
051511100a9a9aa09999999999999999949242209777777fbb3bbbb1b3333333bbb330000003bbbb45454545d100110d0100110dd10000006160610050100005
05511110a9a9a99a999a9999999999990492420099f99999bbbbbbb3b33333b1331300000000331355555554100000d10d0000d110000000d01d10dd5d0100d5
000000009a9a9a999a9a9aaaaaa9a9a90000000000000000a9999a99900000000000000a3b33b3b35d55d5d555dddd550005d500d1010010d000000028000882
0000000099a9a99999a9a9aaaa9a9a99000000000000000099a9999a99000000000000a9a39393ba454545d45d5dd5d50000565010110d1110d00000032b8300
00000000999999a99999a9a99a9a99990000000000000000a9999a999a90000000000a999999993944444454d5ddd56555565d600d1000000d100000b77abb30
00000000a99a9a99a99a9a9aa9a9a999000000000000000099999999999900000000a9a99a9a999945444544d55dd5ddd66ddd50000000000000d000a7abbb30
000000009999999999999999999999990000000000700000999a999999a99000000a99999999999944444444d5dd6ddd655555000000000010d10000babbbb10
0000000099999a9999999a999a9999a900000b0007a70000a9999999a999a90000a9a9999a999a99545454545d65dddd00000000000000000d100d00ababbb10
00000000999999999999999999999999000000b000700000999999a9999999900a999999999999994545454555d5dd650000000000000000d100110033b3b310
00000000999a9999999a9999999a999900b000b000b00000999a99999a999a99a9a9a99a999a9999555555555d55ddd50000000000000000100000d001331100
00000000000000000000000003000000030000000000000000000000000000000000000000007777777700000000077777777000000077777777000008000800
0300000003000000030000000a9400000a9400000300000000000000000000000000000000066666666660000000666666666600000666666666600008000800
0a9400000a9400000a940000a9191000a91910000a94000000000000000000000000000000006577775600000000057775566000000057775566000008000080
a9191000a9191000a91910004949200049492000a9191000000300000000000000000b0000000f5ff54000000000005f5ff40000000005f5ff40000002200080
4949200049492000494920000422000004220000494920000a94000000030000000b300000000fcffc400000000000cfcff4000000000cfcff40f00002220822
0422000004220000042200000bb310003bb3000004220000494920b000a94000000330b0000008ffff8000000000008ff8440000000008ff8440c00000222222
0bb300000bb300000bb3000030000000000010003bb300004949300b0a4940b00bb0000b0000004774000000000000077740000000000077740c000002233333
003100003001000030001000000000000000000000010000394323b03b49930bb00300300000c6cccc6c002400000c7ccc6c0000000006cccc6100002bbb22bb
039900000000000000000000bbbbbbbb7ccc7cc37ccc7cccb42b23bbb42b23bb344424bb000c10777701c044000f10777701c0000000c1777700000055dddd55
a994a0002aa90000094400003333333acdcdcdcbcdcdcdcd333333333333333333244333000f006776000f00000000677600f4420000f067760000005d5dd5d5
4949200094939000a4992000444944a91c1c1c141c1c1c1c444444444444444444444444000000666600400000000066660000440000006666000000d5ddd565
04220000494920003999200045444a9a1111114411111111454445444544454445444544ffffffffffffffffffffffffffffffffffffffffffffffffd1015ddd
00000000042200000422000044949999c111c444c111c111444444444444444444444444444444444444444444444444444444444444444444444444d110005d
0000000000000000000000005449999911c1545411c111c15454545454545454545454540450066666600540045006666660054004500666666005405100000d
00000000000000000000000045999a99111545451111111145454545454545454545454504506767224405400450676722440540045067672244054050100005
0000000000000000000000005999999955555555555555555555555555555555555555550451111642940540045111164294054004511116429405405d0100d5
011501b0000077777777000000000000000000000000777777770000000077777777000000000077777777000077777777000000000000000000000000000000
15505535000666666666600000007777777700000006666666666000000666666666600000000666666666600666666666600000000000000000000000000000
105b5994000065777756000000066666666660000000657777560000000065777756000000000057775566000057775566000000000000000000000000000000
4b53991400000f5ff5400000000065777756000000000f5ff540000000000f5ff540000000000005f5ff40000005f5ff400000000000000000000000009f9f00
535110b500000fcffc40000000000f5ff540000000070fcffc40000000700fcffc4000000007000cfcff4000000cfcff400000000f9f9f90ff0000940f999990
0591943d000008ffff80000000000fcffc400000007008ffff800000000708ffff80000000700008ff8440000008ff8440000000999444449994444499944444
19b4431d0000004774000000000008ffff8000000007004774000000007000477400000000070000777400000000777400000000d5d55551d5d55551d5d55551
113111d10000007cc700000000000047740000000000c6cccc6c00000000c6cccc6c00000000000c6c6c0000000c6c6c60000000055555100555551005555510
0000000000000c7777c000000000016cc6100000009990777701c000009990777701c000009990fcf6c10000f0cf07c1600000000f100000000cc000d1010000
000000000000f167761f00000000cc7777cc00000994446776000f000994446776000f00099444f1fc100000fc0fcc17660000001ffcc02e0fc00c0010d10d11
000000000000242424240000000ff167761ff000d5d5555666000000d5d5555666000000d5d55556666000000000006777600000f2c22c101ff2e02e0d100d10
00000000fffffffffffffffffff4242424242ffff55555fffffffffff55555fffffffffff55555ffffffffffffffffffffffffff002e2220f2222e100000d100
000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440f0d0010002e222010810081
00000000045006666660054004500666666005400450066666600540045006666660054004500666666005400450066666600540f00000000f0d001001800d80
0000000004506767224405400450676722440540045067672244054004506767224405400450676722440540045067672244054000000000f0000000d180118d
00000000045111164294054004511116429405400451111642940540045111164294054004511116429405400451111642940540000000000000000003381820
0077777777000000000000777777770000000077777777001a7a7a7a7a1a1a1a0881181888188810500777777770030055dddd5555dddd5555dddd5555dddd55
066666666660000000000666656666600000066665666660a66666666611111108181818211221100066666666660a905d5dd5d5515dd5d1515dd5d1515dd5d1
005777556600000000000055775566000000005577556600165777756113111a0881181811111810000657777560a949d5ddd565d51dd515d51dd515d51dd515
0005f5ff400000000000000fffff40000000000fffff4000a1f5ff54111a941108111818881888100000f5ff54004949d55dd5ddd061d106d761d176d111d111
000cfcff400000000000000cfcff40000000000fffff400011fcffc411a9492a00000110011000005000fcffc4000422d5dd6dddd76d6d76d70d6d06d11d6d11
0008ff844000000000f00008ff84400000f00008ff844000a18ffff811494921000005100510000050008ffff80000ff5d65dddd5665dd665665dd665115dd11
000077740000000008f400007774000008f4000077740000111477411114221a0000051005100000f0000477400000c055100d5555d5dd6555d5dd6555d5dd65
000c6c6c6000000008ff400c6c6c000008ff400c6c6c0000a88118188818881800000510051000000c00cccccc000cd05d0100d55d55ddd55d55ddd55d55ddd5
00c00777c0000000008820c0777c0000008820c0777c000018181818211221180000051005100000000000070b30000011111111111111110000000000000000
fc0007777c000000000fcc00777c0000000fcc00777c0000a88118181111181100000510051080000000007500788800551555d5551555d50000000000000000
000000677c60000000000006777c000000000006777c000018111818881888180ff8f8888888880000000065078822205d1a55555d1a55550007700000077000
ffffffffffffffffffffffffffffffffffffffffffffffffa1a1a1a1a1a1a1a108888888888888800000000602822220d500a055d5a400550007777766666600
4444444444444444444444444444444444444444444444440000510000510000088888888888884000000000dddd1111100a40a1100a40010007660000666700
04500666666005400450006666660540045000666666054000005100005100000888888888888400000000000551111050940045500490a50000600000067000
045067672244054004500767224405400450076722440540000051000051000000000510051040000000000005151110590924a5520924950000000000000000
045111164294054004501116429405400450111642940540000051000051000000000510051000000000000005511110502aaa0550aaaa050000000000000000
ffffffffffffffff5555555500666600ffffffff0055555555500000006666000000000000000000ffffffff7770030000000077777777000077600000006600
444444444444444488588848116c771144f444241158884888511111110177111101111111011101444444446666078000000666666666600777760000667660
0450000000000540845888881167771142f444441158888884511111110111111101111111011111022400006560788200000057775566000776760007666667
0450000000000540485888881167771124f444441154888848511111110111111101111101010101224000005400282100000005f5ff40007777777766667666
04500000000005405555555500666600ffffffff555555555555550000000000000000000000000024000000c40002100030000cfcff40006777660000666666
0450000000000540848885881177761142444f44848885888488851111111011111110110001000140000000f80000ff00a99008ff8440000676600000666660
0450000000000540888845881177c61144442f44888845888888451111111011111110110000000000000000400000c00a994200777400000006600000066600
045000000000054088848588117c761144424f44888485888884851111111011111110110000000000000000cc000cd00949420c6c6c00000000000000000000
0000000000000000000000000b3000000b3000000000000000000000111111110000000000000000ffffffff00003000004240c0777c00000070600000000600
0b3000000b3000000b30000000758500007585000b30000000000000551555d5000000000b3000004444444400000000000fcc00777c00000077000000000060
007585000075850000758500078151000781510000758500000000005d1555550b300000007bb000000000000000000000000006777c00000700000000000067
07815100078151000781510002822200028222000781510000b30000d5155555007bb00007b131000000000000000000ffffffffffffffff7770000000000000
0282220002822200028222000026760000267600028222000007bb001111111107bb330003b33300000000000000000044444444444444440707000000000606
00267600002676000026760000dd510005dd500000267600007bb3305d55515503b1310000333000000000000000000004500066666605400600000000060000
00dd500000dd500000dd5000050000000000010005dd5000003b33305555d1550033300000dd5000000000000000000004500767224405400006600000060600
00051000050010000500010000000000000000000000100000033300555d5155005d110005001000000000000000000004501116429405400000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a9000b0a90a009400a0000440000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a009030a99940a4090a000a000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000a09040a0090a000a000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa000a0a09040a0040a000a400000
000000c2e0e0e3e2000000000000000000000000000000000000000000000000000000000000000000000000000000000000a900909090409042090009000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000940a0a04040a4200a000a000000
0000c2e0e0e0e0b2e3000000000000000000889800a9a8ba00008898000000000000000000000000000000000000000000000040909040209000090009000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a9020909040209000094209420000
00c2e0e0e0e0e091b20000000000000000004a4a4a4a4a4a4a4a4a4a000000000000000000000000000000000000000000004200a0a02020a000004200420000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00e0e0e0e0e0b2b2b2e3000000000000004a4a8a8a8a8a8a8a8a8a4a4a000000000000000000ccdcecfc00000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a9000b0a90a00aa400a00900000
00e0e0e0e0e0b2b2b2b2e30000000000004a8a8a8a8a8a8a8a8a8a8a4a4a0000000000000000cdddedfd0000000000000000a009030a99940a20040a40400000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000a09040a00040a40400000
00e0e0b2b2b2b2b2b2b2b20000000000004a8a9a9a9a9a9a9a9a9a9a8a4a4a00000000000000cedeeefe0000000000000000a9000a0a09040a00040a40400000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000990090909040900040944900000
00d1b291b2b2b2b2b2b2d20000000000004a9a0000000000000000009a9a3a0000000000000000000000000000000000000000940a0a04040a00040a04400000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004090904020900040904400000
0000d1b2b291b2b2d291000000000000003a0000000000000000000000003a00000000000000420000000000000000000000a902090904020940420904400000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004200a0a02020044200a00200000
000000d1b2e1e1d20000000000000000003a0000000000000000000000003a000000000000aaababababaa000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000b3b3000000000000000000003a0000000000000000000000004a00000000000000cfdfefff00000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000b3b3000000000000000000003a91000000000000000000d6d64a000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb00bb00bb0bb0bb00202000000
0000000000b3b3000000000000000000003a9191d6d6d60000000000c97b4a000000000000000000000000000000000000000b0b0b0b0b00b00b000202000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0b0b0b0bb0bb0bb00202000000
0000000000b3b300006b000000000000004a91910aab1a00000000007b7b4a000000000000000000000000000000000000000bb00bb00b000b00b00020000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b000b0b0b000b00b00202000000
a0a0a0a0a0a3a3a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0000000000000000000000000000000000000000b000b0b0bb0bb0bb00202000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000001010100000100000000000001020201010101000081400001010000010001010100000000200001010100000100000101000000000100000000000040404000000000000002000000010202010101000000000000000100000000000000000000000004000001000000000000000000000000000002
0000000000000000000000000000000000000000000000000000000000000000000001010101010000008100000000000000000000000000000081000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
00000000000000000000000000000000000000000000000000170000000000000000000000000000000026000000000000000000000000000000000017000000000000000000000000000000000000000000000000000000000000000000002e000000000000000000000000000000000000002c0e0e0e0e0e0e0e2b2b2b2b2b
000000000000000000000000000000000000000000000000002600000000000000000000000000000000260000000000000000170000000000000000260000000000000000000000000000000000000000000000000000000000000000002c0e0e0e2c3e2e00000000002c3e0000000000002c0e0e0e0e0e2b0e0e2b2b2b2b2b
0000000000000000000000000000000000000026000000000026000000000000000000000000000000002600000000000000002600000000000000002600000000000000000000000000000000000000000000000000000000000000002c0e0e2b2b2b2b2b3e0000002c0e2b3e000000002c0e0e0e0e0e2b2b0e0e2b2b7f2b2b
00000000000000000000000000000000000000270000004f0026000000000000000000000000000000002617260000000000002600000026000000002600000000000000000000000000000000000000000000002e2e2e0000000000000e0e7f7f7f3f2b2b3f0000000e0e2b2b000000003f0e0e0e0e0e2b3f2b0e2b1d3f2b2b
0000000000000000000000000000000000350027000000260026000000000000000000260000000000002626280000009a8a8b26171717260000002628000000000000000000000000000000000000000000002c0e0e0e3e00000000002b3f3f3f3f3f2b2b2d0000303f1e2b2b000000001d0f2b0e0e0e3f2b2b2b2d007f2b2b
0000000000000000000000000000000000260027000000260026000000000000000000260000000000002926000000006d888926262626280000002700000000000000000000000000000000000000002e00003f0e0e2b2b00000000001d2b2b2b2b1e2b2d000000301d3b2b2d00000000003f2b2b2b2d001d2b2b7f6d3f2b2b
00000000000000000000000000000000002626270000002700270000000000000000002617000000000000262626000026262626280000000000002700000000000000000000000000000000000000000e00000e0e2b2b2b009a8a8b00003d3d1d2b3b0d0000000000003b30000000000000003f2b2b2b002e2b2b3f3f7f7f7f
002c3e00000000000000000000000000002926270000003622393700000000000000002926000000000000292626000000002626000000000000002700001700000000000000000000000000000000002b00001d3f1e2b2d0000888900003030003d3b3c0000000000003b3000000000000000003f2b2b2b2b7f2b2b3f3f3f3f
002b2d00000000000000000000000000000029262600003636363600000000000000000027000000000000000027260000002626000000000000002721002600000000000000000000000017000000000d0000003d3b3c00000088890000000000343bb60000000000003b3f00002c0e3e0000003f3f2b2b2b3f7f7f2b2b0e0e
000d000000000000000000000000008687000027280000363636360000002600000000002700000000000000262727262726262600260000004f17273617260000000000000000000000001a2a0000001a2a0000003b0000003498996d0000301a0a0a2a0000000000003b3c00000e7f2b000000001d2b2b2b0f3f3f2b0e0e2b
000d0000464847464800480048350096970000270000383636363617180027000000004f39222217171800002727272727272626002700003832223936332600003447464834464847001a0c0c0000000c0c1800003b00304f1a0a0a0a0a0a0a0c0c0c0c0000000000003b0000001d3f2d30300000001d2b3f2b0f1e2b1e2b2b
55555554560a57560a580a580a5322222237212721383636363636393922392222222239232323393939222239392222223339392222222233232323232339220b0a0a0a0a0a0a0a0a0a0c0c0c1717180c0c0a0a0a3a0a0a0a0c0c0c0c0c0c0c0c0c0c0c3f00000000003b000030300d30302c3e0000303d3d3d1d3b1e3b3c00
0c0c0c0c0c0c0c0c0c0c0c0c162323232323233923232336363636232323232323232323232523232323232323232323232323232325232323232323232323231b0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0d3f000000003b000000000d002c3f2b00003f003000003b3b3b0000
0c0c0c0c0c0c0c0c0c0c0c16232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323231b0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0d0d000000003a000000000d301d1e2d00000d003000003b3b3b0000
3030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303088898889888988898889888988898889888988898889888988898889888988898889888988890000000000000000000000000000000000000000000000000000000000
2b2b2b2b2b0e0e0e2b0e0e0e0e2b2b0000000000302c3e000000000000000000000000000000000000000000000000000000000000000000000000009a8a8ba2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a200a2a2a2a2a2001d0e7f0e0e0e7f0e192b2b2b2ba200000000000000
2b2b2b2b2b0e0e0e1e2b0e0e2b2b2b0000000000303f2b00000000000000303030000000000000000000000000000000000000000000000000000000008889a2a2a8a8a8a8a8a8a4a8a8a8a8000000a3a8a8a8a3a8a8a8a8a8a8a8a9a9a9a4a8a8a8a8a40000a9a8a8a200001d3f0e7f0e3f0e3f2b2b3f2da200000000000000
2b2b2b2b2b2d001d3b3c3d1d2b2b2d0000000000003f2b00000000000000300000000000000000000000000000000000000000000000000000000000008889a300000000a9a9a8a3a8a8a8a9000000a3a8a8a8a3a8a8a8a8a9a9a9000000a4a8a9a9a8a44600a9a8a8a20000002b0e3f0e0e2b3f2b2b2b00a200000000000000
2b2b2b2b2b0000003b0000003d3d000000000030303f2b00000000000030300000000000000000000000000000000000000000000000000000000000008889a3000000000000a8a3a8a8a800000000a3a8a8a9a4a9a9a9a9000000000000a4a90000a9a4aa00a9a8a8a2000000001d2b2b1e2b3f2b2b2d00a200000000000000
2b2b2b2b2b0000003b0000000000000000000030303f2b3e000000000030300000000000003030300000000000000000000000000000000000000000009899a7000000000000a8a3a9a9a900000006a3a8a8000000000000006d176d0000a4006d6d00a4000000a9a8a20000000000001d3b3c3d003d0000a200000000000000
7f2b2b2b2d3030003b00001700000000000000002c3f3f2b3f0000000030303000000000000000000000000000000000000000000000000000000000000000a8000000000000a8a4000000000000a4a4a8a800000000000000aabaaa0000a400aaaa00a400000000a9a2000000000000003b000000000000a200000000000000
3f1f1f2d303000003b00000a3e000000000000003f3f3f2b2b0000003030303030303030303030303000000000000000000000000000000000000000000000a2a2aa0000a8a8a8a8000000000000a3a8a8a9000000006d004f17171718000000000000000000000000a2000000000000002f000000000000a200000000000000
2b2d000000004f183b00000c2b3e0000000000003f3f3f2b2d00000000000030303030303030303030000000000000000000000000000000000000000000aca2a20000a8a8a8a8a900004f180000a3a9a90000000000aa00aabababaaa0000004f180000006d000000a2000000000000003b000000000000a200000000000000
2b00000000001a0a3b00000c2b2b3e303030002c3f3f2b2b0000000000000030303030303030303030000000002e0000000000000000000000464707486d60a2a200a9a8a8a8a9000000a2a20000a4000000006d000000000000000000000000aaaa000000aa000000a2000000000000003b000000000000a200000000000000
2d9a8a8b00000c0c3b4f6d0c1f1f1f1f1f1f1f1f3f1e1e2b00000000000030303030303030b6003030303030300e30303030000000000000471a2a60606060a2a20700a9a9a900000000a2a200000000000000aa0000000000000000000000004f1800000000000000a2000000000000003b000000000000a200000000000000
000098994f6d0c0c3a0a0a0c2d3d3d3d3d3d00001d3b3b2b00000000002b003030003000000d9a8a8b000000000e000000000000000000001a0c0c57575757a2a2aa0000000000000000a2a21800000000000000000000000000000000000000aaaa00000000000000a2000000000000003b000000000000a200000000000000
000088891a0a0c0c0c0c0c0c00000000000000002c3b3b2d00000000002b000000868700000d008889000000002b0000000000000000001a0c0c0c0c0c0c0ca2a2070000000000006d6da2a2a46d00000000000000000000000000000000006d6d6d6d000000000000a2000000000000003b000000009cb7a200000000000000
000798990c0c0c0c0c0c0c0c000000000000002c0e2f3b0000000000000d003500969700000d009899000000000d00340000000035001a0c0c0c0c0c0c0c0ca2a2aa006d4f171718a4a4a2a2a4aa4f6d6d4f17171717171717171717171718a0babaa14f1717171718a2000000000000003b00000000b7b7a200000000000000
001a0a0a0c0c0c0c0c0c0c0c0000000000002c3f3f3b3b000000001a0a3a0a0a0a0a0a0a0a3a0a0a0a0a0a0a0a3a0a0a0a0a0a0a0a0a0c0c0c0c0c0c0c0c0ca2a2a2a2a2a2a4a4a4a4a4a2a2a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a2a2a2a2a20a0a0a0a0a0a0a3a0a0a0a0a0a0a0a00000000000000
0000000000000000303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000377005770077700d6200d6200d600176001a6001c6001f6002060020600176000d600056000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
00010000093700d3700d3700d3700f070003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000c00002f570267702757021770245701e770215701b7701f5701b7701e7701977019770167701577013770107700d7700a77006770017700c00000000000000000000000000000000000000000000000000000
01100000180471c0471f0471c0471f047240472b047240472804724047280402b0403004037000370003700037000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000210701e0701c0701807014070120700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001867032670326701867022670226701867000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001600201b0700000000000000002707000000000001b07019070180000000000000250702500000000190701707017000000002300023070000000000016070140701707011070000000a5700a0000a50016000
001600201b2500b0401b2300b0201b2100f4000000000000192500a040192300a0201921000000000000000017250080401723008020172100000000000000000000000000000000000000000000000000000000
00020000250702c07033070390703f070360702f07027070260702b070310703907037070300702d0702807000000000000000000000000000000000000000000000000000000000000000000000000000000000
01140020150501700019050190500130019050000001c0001c0500000015000150001500002000150001505014050140001c000140001405014000000001c0001c0501c0001c0000000014050140000000000000
011400101563300000000000000015633000000000000000156330000000000000001564300000000001563300000000000000000000000000000000000000000000000000000000000000000000000000000000
011400200935009300093500530009350093000935000000093500930009350093000935209352093520930001350013000135000000013500830001350043000435004300043500000004352043000435000000
011400101917019170191701917019170191701717017170171701717017170171701017210172101721017235100351000000000000000000000000000000000000000000000000000000000000000000000000
0128000019070190701907017070170701707010070100701906019060190601c0611c0601c060190611906019063190000000000000000000000000000000000000000000000000000000000000000000000000
012800002d0742d0712d0722d0722d0752c0742c0722c07528074280722807228075000000000000000000002d0742d0712d0722d0722d0752c0742c0722c0752f0742f0722f0722f07500000000000000000000
011e00001f07020070210702207022070220700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400003d0703c0700a6703b070390700b670370700c670340700c670310700c6702d0702a0700c670250700e670210701e0701b070130700f0700b070070700407001070010700000000000000000000000000
00100020131751317513175131750e1750e1750e1750e1750f1750f1750f1750f17515175151751517515175131751317513175131750e1750e1750e1750e1750f1750f1750f1750f17515175161751617515175
00100020072750527507275052750227500275022750027503275032750327503275092750a275092750527507275072750a2750a27507275072750e2750e2750327503275072750727505275052750727507275
0120000026775267750000000000277752777500000000002b7752b77529705000002a7752a77500000000002b7752b77500000000002d7752d77500000000002e775307752e7752d7752b7752b7752b7752b775
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 09424344
00 094a4844
00 090a4b44
01 090b0a44
00 090c0b4c
00 090a0b44
00 090b0d44
00 090a0e44
02 090b0e44
00 11424344
01 11124344
02 13121144
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

