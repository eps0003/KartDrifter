def draw_track_select_preview
  track_dim = self.height * 0.6
  padding = 40
  w = track_dim + padding
  x = self.width - self.width / 4
  y = self.height / 2
  translate_x = x - @track.pixel_w / 2
  translate_y = y - @track.pixel_h / 2

  # Scale track preview
  scale = [
    track_dim / @track.pixel_w.to_f,
    track_dim / @track.pixel_h.to_f,
  ].min
  scale_levels = [0.025, 0.05, 0.075, 0.1, 0.15, 0.2, 0.25, 0.5, 0.75, 1.0]
  scale = find_nearest_scale(scale_levels, scale)

  # Draw transparent background
  draw_rect(x - w / 2.0, y - w / 2.0, w, w, Gosu::Color.new(255 / 10, 0, 0, 0))

  # Draw track preview
  Gosu.translate(translate_x, translate_y) do
    Gosu.scale(scale, scale, @track.pixel_w / 2, @track.pixel_h / 2) do
      draw_track()
    end
  end
end

def draw_game
  Gosu.translate(-@view_x, -@view_y) do
    draw_background()
    draw_track()
    draw_car(@ghost, true) if (@ghost)
    draw_car(@car)
  end
end

def draw_gui
  # Draw transparent background
  if (in_menu? && @game_state != GameState::Editor)
    draw_rect(0, 0, self.width, self.height, 0x99_000000)
  end

  # Draw gui elements
  case @game_state
  when GameState::MainMenu
    draw_gui_elements(@gui[Menus::MainMenu])
  when GameState::TrackSelect
    draw_gui_elements(@gui[Menus::TrackSelect])
    if (@tracks.size == 0)
      draw_aligned_text("No Tracks", @body_font, self.width / 4, self.height / 2)
    end
  when GameState::Editor
    draw_editor_gui_elements(@gui[Menus::Editor])
    draw_editor_minimap()
  when GameState::Controls
    draw_gui_elements(@gui[Menus::Controls])
    draw_controls(@header_font, @body_font)
  when GameState::ScorePage
    draw_gui_elements(@gui[Menus::ScorePage])
    draw_race_summary(@body_font)
  end

  draw_gui_elements(@gui[Menus::Paused]) if (@game_paused)

  # Draw other gui things
  draw_menu_titles(@title_font, @header_font)
  draw_game_hud(@car)
end

def draw_controls(header_font, body_font)
  gameplay_controls = [
    ["W / Up", "Accelerate"],
    ["S / Down", "Reverse"],
    ["A / Left", "Turn left"],
    ["D / Right", "Turn right"],
    ["Shift / Space", "Hop / Drift"],
    ["Escape", "Pause / Resume"],
  ]

  editor_controls = [
    ["Left mouse", "Place tile"],
    ["Right mouse", "Remove tile"],
    ["Alt + Left mouse", "Overwrite tile"],
    ["Space", "Rotate tile"],
    ["Ctrl + Drag", "Pan view"],
    ["Ctrl + Scroll", "Zoom in/out"],
    ["Ctrl + Z", "Undo action"],
    ["Ctrl + Y", "Redo action"],
    ["Ctrl + S", "Save track"],
    ["Ctrl + O", "Load track"],
    ["Ctrl + N", "New track"],
    ["Ctrl + G", "Toggle grid"],
    ["Arrow keys", "Position track"],
  ]

  color = Gosu::Color::WHITE
  h = body_font.height
  y = self.height * 0.3

  # Draw gameplay controls
  x = self.width * 0.25
  draw_aligned_text("Gameplay", header_font, x, y - 20, 0, color, 0.5, 1)

  i = 0
  while (i < gameplay_controls.size)
    key = gameplay_controls[i][0]
    action = gameplay_controls[i][1]

    draw_aligned_text(key, body_font, x - 10, y + i * h, 0, color, 1, 0)
    draw_aligned_text(action, body_font, x + 10, y + i * h, 0, color, 0, 0)

    i += 1
  end

  # Draw editor controls
  x = self.width * 0.75
  draw_aligned_text("Editor", header_font, x, y - 20, 0, color, 0.5, 1)

  i = 0
  while (i < editor_controls.size)
    key = editor_controls[i][0]
    action = editor_controls[i][1]

    draw_aligned_text(key, body_font, x - 10, y + i * h, 0, color, 1, 0)
    draw_aligned_text(action, body_font, x + 10, y + i * h, 0, color, 0, 0)

    i += 1
  end
end

def draw_menu_titles(title_font, header_font)
  x = self.width / 2
  y = self.height / 10
  y2 = self.height / 4

  case @game_state
  when GameState::MainMenu
    draw_aligned_text("Kart Drifter", title_font, x, y2)
  when GameState::TrackSelect
    draw_aligned_text("Select a Track", header_font, x, y)
  when GameState::Controls
    draw_aligned_text("Controls", header_font, x, y)
  when GameState::ScorePage
    draw_aligned_text("Race Complete", title_font, x, y2)
  end

  if (@game_paused)
    draw_aligned_text("Paused", title_font, x, y2)
  end
end

def draw_race_summary(font)
  time = @car.replay.data.size
  cumulative_time = @car.replay.duration

  # Check whether time was record time
  record_text = nil
  time_improvement = ""
  best_time = cumulative_time
  if (@ghost)
    ghost_time = @ghost.replay.duration
    if (ghost_time < best_time)
      best_time = ghost_time
    elsif (ghost_time == best_time)
      record_text = "TIED RECORD"
    else
      record_text = "NEW RECORD"
      time_improvement = " (-#{format_time(ghost_time - best_time)})"
    end
  end

  # Draw race summary
  draw_aligned_text("Time", font, self.width / 1.5 - 10, self.height / 1.7 - 60, 0, Gosu::Color::WHITE, 1, 0.5)
  draw_aligned_text("Penalties", font, self.width / 1.5 - 10, self.height / 1.7 - 20, 0, Gosu::Color::WHITE, 1, 0.5)
  draw_aligned_text("Cumulative Time", font, self.width / 1.5 - 10, self.height / 1.7 + 20, 0, Gosu::Color::WHITE, 1, 0.5)
  draw_aligned_text("Record Time", font, self.width / 1.5 - 10, self.height / 1.7 + 60, 0, Gosu::Color::WHITE, 1, 0.5)

  draw_aligned_text(format_time(time), font, self.width / 1.5 + 10, self.height / 1.7 - 60, 0, Gosu::Color::WHITE, 0, 0.5)
  draw_aligned_text("#{@car.missed_checkpoints} x #{format_time(MISSED_CHECKPOINT_PENALTY * 60)}", font, self.width / 1.5 + 10, self.height / 1.7 - 20, 0, Gosu::Color::WHITE, 0, 0.5)
  draw_aligned_text(format_time(cumulative_time), font, self.width / 1.5 + 10, self.height / 1.7 + 20, 0, Gosu::Color::WHITE, 0, 0.5)
  draw_aligned_text(format_time(best_time) + time_improvement, font, self.width / 1.5 + 10, self.height / 1.7 + 60, 0, Gosu::Color::WHITE, 0, 0.5)

  # Draw record text
  if (record_text)
    draw_aligned_text(record_text, @header_font, self.width / 1.5, self.height / 1.7 - 120, 0, Gosu::Color::WHITE, 0.5, 0.5, Math.sin(Gosu.milliseconds / 100.0) * 3)
  end
end

def draw_game_hud(car)
  ease_duration = 60

  # Check if hud is visible
  if (!@game_paused)
    if (in_game?)
      ease = 1
      t = (Gosu.milliseconds - @gui_ease_time) / 1000.0 * 60

      # Calclate ease time
      case @game_state
      when GameState::PreGame
        @gui_ease_time = Gosu.milliseconds if (!@gui_ease_time)
        ease = (t / ease_duration.to_f).clamp(0, 1)
      when GameState::PostGame
        @gui_ease_time = Gosu.milliseconds if (!@gui_ease_time)
        ease = 1 - (t / ease_duration.to_f).clamp(0, 1)
      else
        @gui_ease_time = Gosu.milliseconds
      end

      # Draw game hud
      draw_countdown(@title_font)
      draw_laps(car, @header_font, ease)
      draw_race_time(car, @header_font, ease)
    else
      @gui_ease_time = Gosu.milliseconds
    end
  end
end

def draw_countdown(font)
  go_visible_duration = 45
  ease_out_duration = 30

  # Check if countdown is visible
  pre_game = @game_state == GameState::PreGame
  mid_game = @game_state == GameState::MidGame && @game_time < go_visible_duration + ease_out_duration
  if (pre_game || mid_game)
    # Setup variables
    text = "Go!"
    ease = 1
    padding = 10
    w = font.text_width(text) + padding * 2
    h = font.height + padding * 2
    x = self.width / 2
    y = 0

    if (pre_game)
      # Show countdown
      countdown = COUNTDOWN_TIME - @game_time / 60
      text = (countdown > 0) ? countdown : "Go!"

      # Prepare go_time for when countdown needs to scale out
      @go_time = nil
    elsif (@game_time >= go_visible_duration)
      # Save milliseconds when scale out begins
      @go_time = Gosu.milliseconds if (!@go_time)

      # Convert milliseconds since go_time to ticks
      t = (Gosu.milliseconds - @go_time) / 1000.0 * 60

      # Easing out
      ease = t / ease_out_duration.to_f
      ease = Math.cos(ease * Math::PI / 2)

      y -= (1 - ease) * 200
    end

    # Color easing
    back_color = Gosu::Color.new(255 / 3 * ease, 0, 0, 0)
    text_color = Gosu::Color.new(255 * ease, 255, 255, 255)

    # Draw countdown
    draw_quad(
      x - w, y, back_color,
      x + w, y, back_color,
      x + w / 2, y + h, back_color,
      x - w / 2, y + h, back_color
    )
    draw_aligned_text(text, font, x, y + padding, 0, text_color, 0.5, 0)
  end
end

def draw_laps(car, font, ease)
  text = "Lap #{car.lap + 1}/#{LAPS}"
  margin = 40
  padding = 10
  x = self.width - margin
  y = margin
  w = font.text_width("Lap 0/0") + padding * 2
  h = font.height + padding * 2

  # Color easing
  back_color = Gosu::Color.new(255 / 3 * ease, 0, 0, 0)
  text_color = Gosu::Color.new(255 * ease, 255, 255, 255)

  # Easing in/out
  start_offset = 200
  x += start_offset - Math.sin(ease * Math::PI / 2) * start_offset

  # Draw laps
  draw_rect(x - w, y, w, h, back_color)
  draw_aligned_text(text, font, x - w / 2, y + padding, 0, text_color, 0.5, 0)
end

def draw_race_time(car, font, ease)
  margin = 40
  padding = 10
  x = margin
  y = margin
  w = font.text_width("00:00:00") + padding * 2
  h = font.height + padding * 2

  # Color easing
  back_color = Gosu::Color.new(255 / 3 * ease, 0, 0, 0)
  text_color = Gosu::Color.new(255 * ease, 255, 255, 255)

  # Figure out time to display
  text = format_time(0)
  case @game_state
  when GameState::MidGame
    text = format_time(@game_time)
  when GameState::PostGame
    text = format_time(@car.replay.data.size)
  end

  # Easing in/out
  start_offset = 200
  x -= start_offset - Math.sin(ease * Math::PI / 2) * start_offset

  # Draw time
  draw_rect(x, y, w, h, back_color)
  draw_aligned_text(text, font, x + w / 2, y + padding, 0, text_color, 0.5, 0)
end

def draw_gui_elements(elements)
  i = 0
  while (i < elements.size)
    element = elements[i]

    case element.class.name
    when "Array"
      # Recursively draw nested arrays
      draw_gui_elements(element)
    when "TextButton", "IconButton"
      draw_button(element)
    when "Textbox"
      draw_textbox(element)
    end

    i += 1
  end
end
