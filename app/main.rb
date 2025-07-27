def tick(args)
  args.state.timer ||= 0
  args.state.splat_score ||= 0
  args.state.catch_score ||= 0
  args.state.eggs ||= []
  args.state.splats ||= []
  args.state.baskets ||= []
  args.state.buttons ||= []

  # initialize buttons
  if Kernel.tick_count == 0
    args.state.buttons << buy_button(
      args,
      x: 32,
      y: args.grid.h - 128 - 32,
      text: "Buy Automated Basket",
      splat_price: 5,
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
end

def calc_buttons(args)
  args.state.buttons.each do |b|
    if args.inputs.mouse.click && args.inputs.mouse.intersect_rect?(b)
      if !b[:purchased] && args.state.splat_score >= b[:splat_price] &&
           args.state.catch_score >= b[:catch_price]
        args.state.splat_score -= b[:splat_price]
        args.state.catch_score -= b[:catch_price]

        b[:purchased] = true
      end
    end

    b[:a] -= 30 if b[:purchased]
  end

  args.state.buttons.reject! do |b|
    b[:purchased_tick] && b[:purchased_tick].elapsed_time >= 1.0.seconds &&
      b[:a] <= 0
  end
end

def calc_eggs(args)
  if args.state.timer.elapsed_time >= 1.seconds
    args.state.eggs << egg
    args.state.timer = Kernel.tick_count
  end
  args.state.eggs.each do |egg|
    egg.y -= 5
    if egg.y <= egg[:h] + 8
      egg.smashed = true
      args.state.splats << splat(x: egg[:x] - 40, y: egg[:y])
      args.state.splat_score += 1
    end

    args.state.eggs.reject! { |egg| egg.smashed }
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
end

def egg
  {
    vx: 0,
    vy: 0,
    x: Numeric.rand(80..(GTK.args.grid.w - 160)),
    y: 720,
    w: 80,
    h: 80,
    path: "sprites/egg.png",
    angle: Numeric.rand(0..360),
    smashed: false
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
    w: 80,
    h: 80,
    path: "sprites/basket.png",
    angle: 0,
    created_tick: Kernel.tick_count
  }
end

def shop_widget
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
    a: 150
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
    b: 50
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
    b: 50
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
    b: 50
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
    a: 255
  }
end

def render(args)
  args.outputs.solids << { x: 0, y: 0, w: 1280, h: 720, r: 100, g: 100, b: 180 }

  args.state.baskets.each do |basket|
    basket[:angle]
    args.outputs.sprites << basket
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

  args.state.buttons.each { |b| args.outputs.sprites << b }

  args.outputs.labels << {
    x: args.grid.w / 2 - 64,
    y: args.grid.h - 32,
    size_px: 26,
    alignment_enum: 1,
    r: 220,
    g: 220,
    b: 50,
    text: "SPLATS"
  }
  args.outputs.labels << {
    x: args.grid.w / 2 - 64,
    y: args.grid.h - 64,
    size_px: 26,
    alignment_enum: 1,
    r: 220,
    g: 220,
    b: 50,
    text: "#{args.state.splat_score}"
  }

  args.outputs.labels << {
    x: args.grid.w / 2 + 64,
    y: args.grid.h - 32,
    size_px: 26,
    alignment_enum: 1,
    r: 220,
    g: 220,
    b: 50,
    text: "CATCHES"
  }
  args.outputs.labels << {
    x: args.grid.w / 2 + 64,
    y: args.grid.h - 64,
    size_px: 26,
    alignment_enum: 1,
    r: 220,
    g: 220,
    b: 50,
    text: "#{args.state.catch_score}"
  }
end
