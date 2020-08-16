def get_minutes(ticks)
  (ticks / 3600).to_s.rjust(2, "0")
end

def get_seconds(ticks)
  ((ticks / 60) % 60).to_s.rjust(2, "0")
end

def get_milliseconds(ticks)
  (ticks % 60).to_s.rjust(2, "0")
end

def format_time(ticks)
  min = get_minutes(ticks)
  sec = get_seconds(ticks)
  mil = get_milliseconds(ticks)

  "#{min}:#{sec}:#{mil}"
end

def true?(str)
  ["true", "t", "yes", "y", "1"].include?(str.downcase)
end

def sign(val)
  if (val > 0)
    1
  elsif (val < 0)
    -1
  else
    0
  end
end

def mouse_in_area?(x, y, w, h)
  mouse_x >= x && mouse_x < x + w &&
  mouse_y >= y && mouse_y < y + h
end

def draw_aligned_text(text, font, x, y, z = 0, color = Gosu::Color::WHITE, h_align = 0.5, v_align = 0.5, angle = 0)
  image = Gosu::Image.from_text(text, font.height)

  # Aligned text position
  xx = x - font.text_width(text) * h_align
  yy = y - image.height * v_align

  # Rotate and draw text
  Gosu.rotate(angle, x, y) do
    font.draw_text(text, xx, yy, z, 1, 1, color)
  end
end

# Source: https://bryceboe.com/2006/10/23/line-segment-intersection-algorithm/
def line_intersect?(l1, l2)
  ccw?(l1.p1, l2.p1, l2.p2) != ccw?(l1.p2, l2.p1, l2.p2) &&
  ccw?(l1.p1, l1.p2, l2.p1) != ccw?(l1.p1, l1.p2, l2.p2)
end

def ccw?(p1, p2, p3)
  (p3.y - p1.y) * (p2.x - p1.x) > (p2.y - p1.y) * (p3.x - p1.x)
end

def in_menu?
  [GameState::MainMenu, GameState::TrackSelect, GameState::Editor, GameState::Controls, GameState::ScorePage].include?(@game_state) || @game_paused
end

def in_game?
  [GameState::PreGame, GameState::MidGame, GameState::PostGame].include?(@game_state)
end
