def tick(args)
  args.state.game_started ||= false
  args.state.game_completed ||= false
  args.state.game_completed_tick ||= nil
  args.state.timer ||= 0
  args.state.egg_spawn_time ||= 1.0.seconds
  args.state.egg_fall_speed ||= 0.1
  args.state.last_click_tick ||= 0
  args.state.splat_score ||= 0
  args.state.catch_score ||= 0
  args.state.upgrade_tier ||= 1
  args.state.upgrades_purchased ||= 0
  args.state.combo ||= 1
  args.state.combo_egg ||= nil
  args.state.eggs ||= []
  args.state.splats ||= []
  args.state.baskets ||= []
  args.state.buttons ||= []

  # initialize buttons
  if Kernel.tick_count == 0
    args.audio[:music] = {
      input: "sounds/bossa_nova.mp3",
      gain: 0.15,
      looping: true,
    }

    args.state.buttons << buy_button(
      args,
      x: 32,
      y: args.grid.h - 128 - 32,
      text: "Buy Automated Basket",
      splat_price: 10,
      catch_price: 0,
      upgrade_id: 0
    )
  end

  calc(args)
  render(args)
end

def calc(args)
  calc_buttons(args)
  calc_eggs(args)
  calc_splats(args)
  calc_baskets(args)
  calc_upgrade_tiers(args)
  calc_clicks(args)
end

def calc_clicks(args)
  GTK.reset_next_tick if args.state.game_completed_tick && args.inputs.mouse.click && args.state.game_completed_tick.elapsed_time >= 1.seconds

  args.state.eggs.each do |e|
    if args.inputs.mouse.click && e.intersect_rect?(args.inputs.mouse)
      # start new combo
      if !args.state.combo_egg || args.state.combo_egg != e
        args.state.combo_egg = e
        args.state.combo = 1
      # continue combo
      elsif args.state.combo_egg && args.state.combo_egg == e
        args.state.combo += 1
      end

      args.audio["sfx_egg_click"] = { 
        input: "sounds/ui/switch7.wav", 
        gain: 0.75,
        pitch: 1.0 + (args.state.combo * 0.25)
      }

      args.state.game_started = true if !args.state.game_started
      e[:clicked] = true
      if args.inputs.mouse.x - (e[:x] + 40) >= 0
        e[:dx] = Numeric.rand(-5..0)
      else
        e[:dx] = Numeric.rand(0..5)
      end
      
      e[:dy] = 10
    end
  end
end

def calc_buttons(args)
  args.state.buttons.each do |b|
    is_hovering = args.inputs.mouse.intersect_rect?(b)
    if is_hovering != b[:hovered]
      
      if !b[:purchased_tick]
        args.audio[:sfx_button_hover] = {
          input: "sounds/ui/rollover2.wav",
          gain: 20.0
        }
      end
      b[:hovered] = is_hovering
    end

    if args.inputs.mouse.click && args.inputs.mouse.intersect_rect?(b) && args.state.last_click_tick.elapsed_time >= 0.1.seconds
      if !b[:purchased] && args.state.splat_score >= b[:splat_price] &&
           args.state.catch_score >= b[:catch_price]

        args.state.last_click_tick = Kernel.tick_count
        args.state.splat_score -= b[:splat_price]
        args.state.catch_score -= b[:catch_price]

        b[:purchased] = true
        args.audio[:sfx_button_purchased] = {
          input: "sounds/ui/switch30.wav",
          gain: 0.2
        }
        args.state.upgrades_purchased += 1
        calc_upgrade(args, b[:upgrade_id])
      end
    end

    b[:a] -= 30 if b[:purchased]
  end

  args.state.buttons.reject! do |b|
    b[:purchased_tick] && b[:purchased_tick].elapsed_time >= 1.0.seconds &&
      b[:a] <= 0
  end
end

def calc_upgrade(args, id)
  case id
  when 0
    args.state.baskets << basket(x: 32, y: 64)
  when 1
    args.state.baskets.each { |b| b[:speed] += 4 }
  when 2
    args.state.baskets.each { |b| b[:targeting_delay] -= 0.5.seconds if b[:targeting_delay] >= 0.5.seconds }
  when 3
    args.state.baskets << basket(x: 32, y: 64)
  when 4
    args.state.baskets.each { |b| b[:speed] += 4 }
  when 5
    args.state.baskets.each { |b| b[:targeting_delay] -= 0.5.seconds if b[:targeting_delay] >= 0.5.seconds }
  when 6
    args.state.baskets << basket(x: 32, y: 64)
  when 7
    args.state.egg_spawn_time -= 0.5.seconds
  when 8
    args.state.baskets.each { |b| b[:targeting_delay] -= 0.5.seconds if b[:targeting_delay] >= 0.5.seconds }
  when 9
    args.state.baskets.each { |b| b[:speed] += 4 }
  when 10
    args.state.egg_spawn_time = 0.1.seconds
    args.state.egg_fall_speed = 4.0
  when 11
    args.state.baskets.each { |b| b[:speed] = 32 }
    args.state.baskets.each { |b| b[:targeting_delay] = 0 }
  end
end

def calc_upgrade_tiers(args)
  case args.state.upgrades_purchased
  when 1
    unlock_upgrade_tier(args, 2) if args.state.upgrade_tier != 2
  when 3
    unlock_upgrade_tier(args, 3) if args.state.upgrade_tier != 3
  when 6
    unlock_upgrade_tier(args, 4) if args.state.upgrade_tier != 4
  when 10
    unlock_upgrade_tier(args, 5) if args.state.upgrade_tier != 5
  when 12
    args.state.game_completed = true if !args.state.game_completed
    args.state.game_completed_tick = Kernel.tick_count if !args.state.game_completed_tick
  end
end

def unlock_upgrade_tier(args, tier)
  case tier
  when 2
    args.state.upgrade_tier = 2
    args.state.buttons << buy_button(
        args,
        x: 32,
        y: args.grid.h - 128 - 32,
        text: "Upgrade Baskets Hover Speed",
        splat_price: 10,
        catch_price: 5,
        upgrade_id: 1
      )
    args.state.buttons << buy_button(
      args,
      x: 32,
      y: args.grid.h - ((128 * 2) + 16) - 32,
      text: "Upgrade Baskets Target Speed",
      splat_price: 10,
      catch_price: 10,
      upgrade_id: 2
    )
  when 3
    args.state.upgrade_tier = 3
    args.state.buttons << buy_button(
        args,
        x: 32,
        y: args.grid.h - 128 - 32,
        text: "Buy Second Automated Basket",
        splat_price: 5,
        catch_price: 15,
        upgrade_id: 3
      )
    args.state.buttons << buy_button(
      args,
      x: 32,
      y: args.grid.h - ((128 * 2) + 16) - 32,
      text: "Upgrade Baskets Hover Speed",
      splat_price: 5,
      catch_price: 20,
      upgrade_id: 4
    )
    args.state.buttons << buy_button(
      args,
      x: 32,
      y: args.grid.h - ((128 * 3) + 32) - 32,
      text: "Upgrade Baskets Target Speed",
      splat_price: 10,
      catch_price: 30,
      upgrade_id: 5
    )
  when 4
    args.state.upgrade_tier = 4
    args.state.buttons << buy_button(
        args,
        x: 32,
        y: args.grid.h - 128 - 32,
        text: "Buy Third Automated Basket",
        splat_price: 5,
        catch_price: 40,
        upgrade_id: 6
      )
    args.state.buttons << buy_button(
      args,
      x: 32,
      y: args.grid.h - ((128 * 2) + 16) - 32,
      text: "Upgrade Egg Spawn Speed",
      splat_price: 5,
      catch_price: 45,
      upgrade_id: 7
    )
    args.state.buttons << buy_button(
      args,
      x: 32,
      y: args.grid.h - ((128 * 3) + 32) - 32,
      text: "Upgrade Baskets Target Speed",
      splat_price: 5,
      catch_price: 45,
      upgrade_id: 8
    )
    args.state.buttons << buy_button(
      args,
      x: 32,
      y: args.grid.h - ((128 * 4) + 48) - 32,
      text: "Upgrade Baskets Hover Speed",
      splat_price: 5,
      catch_price: 50,
      upgrade_id: 9
    )
  when 5
    args.state.upgrade_tier = 5
    args.state.buttons << buy_button(
        args,
        x: 32,
        y: args.grid.h - 128 - 32,
        text: "EGG-STORM",
        splat_price: 5,
        catch_price: 75,
        upgrade_id: 10
      )
    args.state.buttons << buy_button(
      args,
      x: 32,
      y: args.grid.h - ((128 * 2) + 16) - 32,
      text: "SUPER-BOTS",
      splat_price: 125,
      catch_price: 125,
      upgrade_id: 11
    )
  end
end

def calc_eggs(args)
  if args.state.timer.elapsed_time >= args.state.egg_spawn_time
    args.state.eggs << egg
    args.state.timer = Kernel.tick_count
  end
  args.state.eggs.each do |egg|
    if egg[:clicked]
      egg.dy -= args.state.egg_fall_speed * 10
    else
      egg.dy -= args.state.egg_fall_speed
    end

    egg[:x] += egg[:dx]
    egg[:y] += egg[:dy]

    if egg.y <= egg[:h] + 4
      smash_egg(args, egg)
    end
    args.state.eggs.reject! { |egg| egg.smashed || egg.caught }
  end
end

def smash_egg(args, egg)
  args.audio["sfx_splat_#{args.state.splats.length}"] = { 
    input: "sounds/splat.wav", 
    gain: 0.5,
    pitch: Numeric.rand(0.9..1.2)
  }
  egg.smashed = true
  args.state.splats << splat(x: egg[:x] - 40, y: egg[:y])
  if args.state.game_started
    if args.state.combo_egg == egg
      args.state.splat_score += 1 * args.state.combo 
      args.state.combo = 1
    else
      args.state.splat_score += 1
    end
  end
end

def calc_splats(args)
  args.state.splats.each do |splat|
    splat[:a] -= 15 if splat.created_tick.elapsed_time >= 2.0.seconds
  end

  args.state.splats.reject! do |splat|
    splat.created_tick.elapsed_time >= 1.0.seconds && splat[:a] <= 0
  end
end

def calc_baskets(args)
  args.state.baskets.each do |b|

    b[:catch_rect] = {
      x: b[:x] + 80,
      y: (b[:y] + 32),
      w: 80,
      h: 32
    }


    closest_egg_distance = 2000.0
    args.state.eggs.each do |e|
      # selecting a new target
      distance_to_egg = args.geometry.distance(b,e)
      if !b[:target_egg] && b[:targeting_delay_tick].elapsed_time >= b[:targeting_delay]
        if distance_to_egg <= closest_egg_distance
          closest_egg_distance = distance_to_egg
          if !e[:targeted]
            b[:target_egg] = e
            e[:targeted] = true
          end

          
        elsif args.state.eggs.length <= 0
          reset_basket_target(args, b)
        end
      end

      if e.intersect_rect?(b[:catch_rect])
        args.audio["sfx_catch_#{Numeric.rand(0..5000)}"] = {
          input: "sounds/catch.wav",
          gain: 0.1,
          pitch: Numeric.rand(1.8..2.2)
        }
        e[:caught] = true
        reset_basket_target(args, b)

        if args.state.combo_egg == e
          args.state.catch_score += 1 * args.state.combo 
          args.state.combo = 1
        else
          args.state.catch_score += 1
        end
      end
    end

    if b[:target_egg]
      adj_egg_rect = {
        x: b[:target_egg][:x] - 40,
        y: b[:target_egg][:y] - 64,
        w: b[:target_egg][:w],
        h: b[:target_egg][:h],
      }
      target_direction = args.geometry.vec2_normalize(
        args.geometry.vec2_subtract(adj_egg_rect, b)
        )
      b[:dx] = target_direction[:x] * b[:speed]
      b[:dy] = target_direction[:y] * b[:speed]
      b[:dy] = oscillation(args, 0.1) if b[:y] >= 450

      reset_basket_target(args, b) if b[:target_egg][:smashed] || b[:target_egg][:caught]
    else
      b[:dx] = 0
      b[:dy] = oscillation(args, 0.1)
      b[:dy] -= 2 if b[:y] >= 200
    end

    b[:x] += b[:dx]
    b[:y] += b[:dy]
  end
end

def reset_basket_target(args, basket)
  basket[:target_egg] = nil
  basket[:targeting_delay_tick] = Kernel.tick_count
end

def oscillation(args, speed = 0.05)
  2 * Math.sin(args.state.tick_count * speed)
end



def egg
  {
    dx: 0,
    dy: 0,
    x: Numeric.rand(80..(GTK.args.grid.w - 160)),
    y: 720,
    w: 80,
    h: 80,
    path: "sprites/egg.png",
    angle: Numeric.rand(0..360),
    smashed: false,
    caught: false,
    targeted: false,
    clicked: false,
  }
end

def splat(x:, y:)
  {
    x: x,
    y: y,
    w: 160,
    h: 80,
    path: "sprites/splat.png",
    tile_x: 0,
    tile_y: 0,
    tile_w: 160,
    tile_h: 80,
    a: 255,
    created_tick: Kernel.tick_count
  }
end

def basket(x:, y:)
  {
    x: x,
    y: y,
    w: 160,
    h: 80,
    path: "sprites/basket.png",
    tile_x: 0,
    tile_y: 0,
    tile_w: 160,
    tile_h: 80,
    angle: 0,
    created_tick: Kernel.tick_count,
    target_egg: nil,
    dx: 0,
    dy: 0,
    speed: 4,
    catch_rect: {
      x: x,
      y: (y + 16),
      w: 160,
      h: 80
    },
    targeting_delay_tick: Kernel.tick_count,
    targeting_delay: 1.5.seconds,
  }
end

def buy_button(args, x:, y:, text:, splat_price:, catch_price:, upgrade_id:)
  args.outputs["buy_button_#{args.state.buttons.length}"].w = 256
  args.outputs["buy_button_#{args.state.buttons.length}"].h = 128

  args.outputs["buy_button_#{args.state.buttons.length}"].solids << {
    x: 0,
    y: 0,
    w: 256,
    h: 128,
    r: 80,
    g: 80,
    b: 80,
    a: 30
  }

  args.outputs["buy_button_#{args.state.buttons.length}"].labels << {
    x: 128,
    y: 128 - 32,
    alignment_enum: 1,
    anchor_y: 0.5,
    size_px: 20,
    text: "#{text}",
    r: 220,
    g: 220,
    b: 50,
    font: "fonts/hennypenny.ttf"
  }
  args.outputs["buy_button_#{args.state.buttons.length}"].labels << {
    x: 128,
    y: 128 - 64,
    alignment_enum: 1,
    anchor_y: 0.5,
    size_px: 16,
    text: "#{splat_price} SPLATS",
    r: 220,
    g: 220,
    b: 50,
    font: "fonts/hennypenny.ttf"
  }
  args.outputs["buy_button_#{args.state.buttons.length}"].labels << {
    x: 128,
    y: 128 - 96,
    alignment_enum: 1,
    anchor_y: 0.5,
    size_px: 16,
    text: "#{catch_price} CATCHES",
    r: 220,
    g: 220,
    b: 50,
    font: "fonts/hennypenny.ttf"
  }

  {
    x: x,
    y: y,
    w: 256,
    h: 128,
    path: "buy_button_#{args.state.buttons.length}",
    purchased: false,
    upgrade_id: upgrade_id,
    splat_price: splat_price,
    catch_price: catch_price,
    purchased_tick: nil,
    hovered: false,
    a: 255,
    r: 255,
  }
end

def can_purchase?(args, button)
  button[:splat_price] <= args.state.splat_score && button[:catch_price] <= args.state.catch_score
end

def render(args)
  args.outputs.solids << { x: 0, y: 0, w: 1280, h: 720, r: 100, g: 100, b: 180 }

  args.state.baskets.each do |b|
    frame =
      Numeric.frame_index(
        start_at: b[:created_tick],
        count: 6,
        hold_for: 5,
        repeat: true
      )
    if frame
      anim =
        b.merge({ tile_x: frame * 160, tile_y: 0, tile_w: 160, tile_h: 80 })
    else
      anim = b.merge({ tile_x: 2 * 160, tile_y: 0, tile_w: 160, tile_h: 80 })
    end
    args.outputs.sprites << anim
  end

  args.state.eggs.each do |egg|
    args.outputs.sprites << egg
    egg.angle += 1
  end

  args.state.splats.each do |s|
    frame =
      Numeric.frame_index(
        start_at: s[:created_tick],
        count: 3,
        hold_for: 10,
        repeat: false
      )
    if frame
      anim =
        s.merge({ tile_x: frame * 160, tile_y: 0, tile_w: 160, tile_h: 80 })
    else
      anim = s.merge({ tile_x: 2 * 160, tile_y: 0, tile_w: 160, tile_h: 80 })
    end
    args.outputs.sprites << anim
  end

  if args.state.game_started
    args.state.buttons.each do |b|
      b[:r] = can_purchase?(args, b) ? 100 : 255
      args.outputs.sprites << b
    end

    args.outputs.labels << {
      x: args.grid.w / 2 - 64,
      y: args.grid.h - 32,
      size_px: 26,
      alignment_enum: 1,
      r: 220,
      g: 220,
      b: 50,
      text: "SPLATS",
      font: "fonts/hennypenny.ttf"
    }
    args.outputs.labels << {
      x: args.grid.w / 2 - 64,
      y: args.grid.h - 64,
      size_px: 26,
      alignment_enum: 1,
      r: 220,
      g: 220,
      b: 50,
      text: "#{args.state.splat_score}",
      font: "fonts/hennypenny.ttf"
    }

    args.outputs.labels << {
      x: args.grid.w / 2 + 64,
      y: args.grid.h - 32,
      size_px: 26,
      alignment_enum: 1,
      r: 220,
      g: 220,
      b: 50,
      text: "CATCHES",
      font: "fonts/hennypenny.ttf"
    }
    args.outputs.labels << {
      x: args.grid.w / 2 + 64,
      y: args.grid.h - 64,
      size_px: 26,
      alignment_enum: 1,
      r: 220,
      g: 220,
      b: 50,
      text: "#{args.state.catch_score}",
      font: "fonts/hennypenny.ttf"
    }

    if args.state.combo > 1
      args.outputs.labels << {
        x: args.state.combo_egg[:x] + 40,
        y: args.state.combo_egg[:y] - 8,
        size_px: alpha_osc / 2,
        alignment_enum: 1,
        r: 255,
        g: 255,
        b: 0,
        a: 255,
        text: "#{args.state.combo}X!",
        font: "fonts/hennypenny.ttf"
      }
    end

  else
    args.outputs.labels << {
      x: args.grid.w / 2,
      y: args.grid.h / 2,
      size_px: 32,
      alignment_enum: 1,
      r: 220,
      g: 220,
      b: 50,
      a: alpha_osc,
      text: "CLICK AN EGG TO PLAY",
      font: "fonts/hennypenny.ttf"
    }
  end

  if args.state.game_completed
    args.outputs.labels << {
      x: args.grid.w / 2,
      y: args.grid.h / 2,
      size_px: 32,
      alignment_enum: 1,
      r: 220,
      g: 220,
      b: 50,
      a: alpha_osc,
      text: "CONGRATULATIONS! YOU WIN!",
      font: "fonts/hennypenny.ttf"
    }

    if args.state.game_completed_tick.elapsed_time >= 3.seconds
      args.outputs.labels << {
        x: args.grid.w / 2,
        y: args.grid.h / 2 - 32,
        size_px: 32,
        alignment_enum: 1,
        r: 220,
        g: 220,
        b: 50,
        a: alpha_osc,
        text: "CLICK TO RESTART",
        font: "fonts/hennypenny.ttf"
      }
    end
  end
end

def alpha_osc
  (100 * Math.sin(Kernel.tick_count * 0.08)) + 155
end
