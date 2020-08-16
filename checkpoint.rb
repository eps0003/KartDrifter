Point = Struct.new(:x, :y)
Line = Struct.new(:p1, :p2)

def draw_checkpoints
  i = 0
  while (i < @track.checkpoints.size)
    checkpoint = @track.checkpoints[i]
    draw_checkpoint(checkpoint, i)
    i += 1
  end
end

def draw_checkpoint(checkpoint, index = -1)
  color = Gosu::Color::RED
  p1 = checkpoint.p1
  p2 = checkpoint.p2

  draw_line(
    screen_position_x(p1.x * TILE_SIZE), screen_position_y(p1.y * TILE_SIZE), color,
    screen_position_x(p2.x * TILE_SIZE), screen_position_y(p2.y * TILE_SIZE), color
  )

  if (index > -1)
    x = (p1.x + (p2.x - p1.x) / 2) * TILE_SIZE
    y = (p1.y + (p2.y - p1.y) / 2) * TILE_SIZE
    x = screen_position_x(x)
    y = screen_position_y(y)
    draw_aligned_text(index + 1, @body_font, x, y, 0, Gosu::Color::BLACK)
  end
end

def check_checkpoints(car)
  i = 0
  while (i < @track.checkpoints.size)
    checkpoint = @track.checkpoints[i]

    if (car_crossed_checkpoint?(car, checkpoint))
      apply_checkpoint(car, checkpoint)
    end

    i += 1
  end
end

def apply_checkpoint(car, checkpoint)
  index = get_checkpoint_index(checkpoint)

  crossing_finish = index == 0 && car.checkpoint != 0
  crossing_new = index > car.checkpoint
  crossing_next = index == car.checkpoint + 1

  if (crossing_new)
    car.missed_checkpoints += index - car.checkpoint - 1
    car.checkpoint = index
  end

  if (crossing_finish)
    car.missed_checkpoints += @track.checkpoints.size - car.checkpoint - 1
    car.checkpoint = index

    if (car.lap < LAPS - 1)
      car.lap += 1
    elsif (car != @ghost)
      set_game_state(GameState::PostGame)
    end
  end
end

def car_crossed_checkpoint?(car, checkpoint)
  p1 = Point.new(car.old_pos_x, car.old_pos_y)
  p2 = Point.new(car.pos_x, car.pos_y)
  car_line = Line.new(p1, p2)

  p1 = Point.new(checkpoint.p1.x * TILE_SIZE, checkpoint.p1.y * TILE_SIZE)
  p2 = Point.new(checkpoint.p2.x * TILE_SIZE, checkpoint.p2.y * TILE_SIZE)
  checkpoint_line = Line.new(p1, p2)

  line_intersect?(checkpoint_line, car_line)
end

def valid_checkpoint?(checkpoint)
  checkpoint && !same_point?(checkpoint.p1, checkpoint.p2)
end

def same_point?(p1, p2)
  p1.x == p2.x && p1.y == p2.y
end

def get_checkpoint_index(checkpoint)
  found_index = -1

  i = 0
  while (i < @track.checkpoints.size && found_index == -1)
    cp = @track.checkpoints[i]

    if (cp == checkpoint)
      found_index = i
    end

    i += 1
  end

  found_index
end

def same_checkpoint?(checkpoint1, checkpoint2)
  (same_point?(checkpoint1.p1, checkpoint2.p1) && same_point?(checkpoint1.p2, checkpoint2.p2)) ||
  (same_point?(checkpoint1.p1, checkpoint2.p2) && same_point?(checkpoint1.p2, checkpoint2.p1))
end

def find_same_checkpoint(checkpoint)
  found_checkpoint = nil

  i = 0
  while (i < @track.checkpoints.size && !found_checkpoint)
    cp = @track.checkpoints[i]

    if (same_checkpoint?(checkpoint, cp))
      found_checkpoint = cp
    end

    i += 1
  end

  found_checkpoint
end
