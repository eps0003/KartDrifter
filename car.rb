module CarState
  Idle, Accelerating, Reversing, Hopping, Drifting = *0...5
end

class Car
  attr_accessor :pos_x, :pos_y, :pos_z, :old_pos_x, :old_pos_y, :angle,
                :image_angle, :image,
                :vel, :max_vel, :max_reverse_vel,
                :acc, :fric,
                :offroad_max_vel_mult, :offroad_fric,
                :turn_spd, :drift_turn_spd, :hop_turn_spd,
                :hop_start, :hop_duration,
                :drift_min_vel, :drift_dir, :drift_angle, :drift_end, :drift_acc, :drift_realign_amount, :drift_realign_duration,
                :up, :down, :left, :right, :hop, :replay,
                :state, :bot,
                :checkpoint, :missed_checkpoints, :lap

  def initialize(posX, posY, angle, image_path, bot)
    @pos_x = posX
    @pos_y = posY
    @pos_z = 0
    @old_pos_x = posX
    @old_pos_y = posY
    @angle = angle

    @image = Gosu::Image.new(image_path)
    @image_angle = angle

    @vel = 0
    @max_vel = 12
    @max_reverse_vel = @max_vel / 2.0

    @acc = 0.2
    @fric = 0.95

    @offroad_max_vel_mult = 0.5
    @offroad_fric = 0.9

    @turn_spd = 1
    @drift_turn_spd = 1.5
    @hop_turn_spd = 1.5

    @hop_start = 0
    @hop_duration = 30

    @drift_min_vel = @max_vel * 0.2
    @drift_dir = 0
    @drift_angle = 40
    @drift_end = 0
    @drift_acc = @acc / 4.0
    @drift_realign_amount = @drift_angle * 0.5
    @drift_realign_duration = 60

    @up = false
    @down = false
    @left = false
    @right = false
    @hop = false
    @replay = Replay.new()

    @state = CarState::Idle
    @bot = bot

    @checkpoint = 0
    @missed_checkpoints = 0
    @lap = 0

    if (!bot)
      Gosu::Sample.new("Sounds/enginestarting.mp3").play(0.05, 1, false)
    end
  end
end

def update_car(car)
  press_keys(car)
  manage_car_state(car)
  wrap_car(car)
  check_checkpoints(car)

  car.old_pos_x = car.pos_x
  car.old_pos_y = car.pos_y
end

def press_keys(car)
  if (car.bot)
    if (@game_state == GameState::MidGame || @game_state == GameState::PostGame)
      replay_step(car)
    end
  else
    if (@game_state == GameState::MidGame)
      car.up = Gosu.button_down?(Gosu::KB_UP) || Gosu.button_down?(Gosu::KB_W)
      car.down = Gosu.button_down?(Gosu::KB_DOWN) || Gosu.button_down?(Gosu::KB_S)
      car.left = Gosu.button_down?(Gosu::KB_LEFT) || Gosu.button_down?(Gosu::KB_A)
      car.right = Gosu.button_down?(Gosu::KB_RIGHT) || Gosu.button_down?(Gosu::KB_D)
      car.hop = Gosu.button_down?(Gosu::KB_SPACE) || Gosu.button_down?(Gosu::KB_LEFT_SHIFT) || Gosu.button_down?(Gosu::KB_RIGHT_SHIFT)

      data = [car.up, car.down, car.left, car.right, car.hop]
      add_replay_data(car.replay, data)
    else
      car.up = false
      car.down = false
      car.left = false
      car.right = false
      car.hop = false
    end
  end
end

def manage_car_state(car)
  dir_x = (car.right ? 1 : 0) - (car.left ? 1 : 0)
  dir_y = (car.up ? 1 : 0) - (car.down ? 1 : 0)

  max_vel = car_offroad?(car) ? car.offroad_max_vel_mult : 1
  fric = car_offroad?(car) ? car.offroad_fric : car.fric

  case car.state
  when CarState::Idle
    if (car.up)
      set_car_state(car, CarState::Accelerating)
    elsif (car.down)
      set_car_state(car, CarState::Reversing)
    elsif (car.hop && car_on_ground?(car))
      set_car_state(car, CarState::Hopping)
    end

    max_vel *= car.max_vel
    car_turn(car, dir_x)
    car_friction(car, max_vel, fric)
    car_realign(car)
  when CarState::Accelerating
    if (!car.up)
      set_car_state(car, CarState::Idle)
    elsif (car.hop && car_on_ground?(car))
      set_car_state(car, CarState::Hopping)
    end

    max_vel *= car.max_vel
    car_turn(car, dir_x)
    car_accelerate(car, car.acc, max_vel, fric)
    car_friction(car, max_vel, fric) if (car.vel < 0)
    car_slow_down(car, max_vel, fric)
    car_realign(car)
  when CarState::Reversing
    if (!car.down)
      set_car_state(car, CarState::Idle)
    elsif (car.hop && car_on_ground?(car))
      set_car_state(car, CarState::Hopping)
    end

    max_vel *= car.max_reverse_vel
    car_turn(car, dir_x)
    car_accelerate(car, -car.acc, max_vel, fric)
    car_friction(car, max_vel, fric) if (car.vel > 0)
    car_slow_down(car, max_vel, fric)
    car_realign(car)
  when CarState::Hopping
    if (car_on_ground?(car))
      car.angle = car.image_angle
      car.pos_z = 0

      if (car.up)
        if (car.vel > car.drift_min_vel && car.drift_dir != 0)
          set_car_state(car, CarState::Drifting)
        else
          set_car_state(car, CarState::Accelerating)
        end
      elsif (car.down)
        set_car_state(car, CarState::Reversing)
      else
        set_car_state(car, CarState::Idle)
      end
    end

    car_hop(car, dir_x)
  when CarState::Drifting
    if (!car.up || !car.hop || car.vel <= car.drift_min_vel)
      car.angle = car.image_angle - car.drift_realign_amount * car.drift_dir

      if (car.up)
        set_car_state(car, CarState::Accelerating)
      elsif (car.down)
        set_car_state(car, CarState::Reversing)
      else
        set_car_state(car, CarState::Idle)
      end
    end

    max_vel *= car.max_vel
    car_drift(car, car.down, dir_x)
    car_accelerate(car, car.drift_acc, max_vel, fric)
    car_slow_down(car, max_vel, fric)
  end

  car_move(car)
end

def car_offroad?(car)
  !track_at_position?((car.pos_x / TILE_SIZE).to_i, (car.pos_y / TILE_SIZE).to_i)
end

def car_accelerate(car, acc, max_vel, fric)
  if (acc > 0)
    if (car.vel < max_vel)
      car.vel = [car.vel + acc, max_vel].min
    end
  else
    if (car.vel > -max_vel)
      car.vel = [car.vel + acc, -max_vel].max
    end
  end
end

def car_turn(car, dir_x)
  car.angle += (car.turn_spd * dir_x * car.vel.abs / car.max_vel) % 360
  car.image_angle = car.angle if (car.drift_end + car.drift_realign_duration < @tick)
end

def car_friction(car, max_vel, fric)
  car.vel *= fric
  if (car.vel.abs < 0.1)
    car.vel = 0
  end
end

def car_slow_down(car, max_vel, fric)
  if (car.vel.abs > max_vel)
    car_friction(car, max_vel, fric)
    if (car.vel.abs < max_vel)
      car.vel = max_vel * sign(car.vel)
    end
  end
end

def car_hop(car, dir_x)
  t = (@tick - car.hop_start) / car.hop_duration.to_f * Math::PI
  car.pos_z = Math.sin(t)

  if (dir_x != 0 && car.drift_dir == 0)
    car.drift_dir = dir_x
  end

  car.image_angle += car.drift_dir * car.hop_turn_spd
end

def car_drift(car, down, dir_x)
  car.image_angle += car.drift_dir * car.drift_turn_spd + dir_x * 1
  car.angle = car.image_angle - car.drift_angle * car.drift_dir
end

def car_realign(car)
  if (car.drift_end + car.drift_realign_duration >= @tick)
    diff = Gosu.angle_diff(car.image_angle, car.angle) * ((@tick - car.drift_end) / car.drift_realign_duration.to_f)
    car.image_angle += diff
  end
end

def car_move(car)
  angle_radians = Gosu::degrees_to_radians(car.angle)
  car.pos_x += Math.sin(angle_radians) * car.vel
  car.pos_y -= Math.cos(angle_radians) * car.vel
end

def car_on_ground?(car)
  @tick - car.hop_start > car.hop_duration
end

def draw_car(car, ghost = false)
  if (!car_on_ground?(car) && !ghost)
    # Draw shadow for real car
    color = Gosu::Color.new(255 / 3, 0, 0, 0)
    scale = 1 - car.pos_z / 10
    car.image.draw_rot(car.pos_x + car.pos_z * 8, car.pos_y + car.pos_z * 8, 0, car.image_angle, 0.5, 0.5, scale, scale, color)
  end

  alpha = ghost ? 0.5 : 1
  color = Gosu::Color.new(255 * alpha, 255, 255, 255)
  scale = 1 + car.pos_z / 8

  if (ghost)
    # Draw fake ghost cars so screen wrap is seamless
    left = (@track.w + 1) * TILE_SIZE + (self.width / TILE_SIZE).ceil * TILE_SIZE
    car.image.draw_rot(car.pos_x + left, car.pos_y, 0, car.image_angle, 0.5, 0.5, scale, scale, color)

    right = (@track.w + 1) * TILE_SIZE + (self.width / TILE_SIZE).floor * TILE_SIZE
    car.image.draw_rot(car.pos_x - right, car.pos_y, 0, car.image_angle, 0.5, 0.5, scale, scale, color)

    up = (@track.h + 1) * TILE_SIZE + (self.height / TILE_SIZE).ceil * TILE_SIZE
    car.image.draw_rot(car.pos_x, car.pos_y + up, 0, car.image_angle, 0.5, 0.5, scale, scale, color)

    down = (@track.h + 1) * TILE_SIZE + (self.height / TILE_SIZE).floor * TILE_SIZE
    car.image.draw_rot(car.pos_x, car.pos_y - down, 0, car.image_angle, 0.5, 0.5, scale, scale, color)
  end

  # Draw real car
  car.image.draw_rot(car.pos_x, car.pos_y, 0, car.image_angle, 0.5, 0.5, scale, scale, color)
end

def wrap_car(car)
  # Left
  if (car.pos_x < -self.width / 2)
    x = (@track.w + 1) * TILE_SIZE + (self.width / TILE_SIZE).ceil * TILE_SIZE
    car.pos_x += x
    car.old_pos_x += x
  end
  # Right
  if (car.pos_x > @track.pixel_w + self.width / 2)
    x = (@track.w + 1) * TILE_SIZE + (self.width / TILE_SIZE).floor * TILE_SIZE
    car.pos_x -= x
    car.old_pos_x -= x
  end
  # Up
  if (car.pos_y < -self.height / 2)
    y = (@track.h + 1) * TILE_SIZE + (self.height / TILE_SIZE).ceil * TILE_SIZE
    car.pos_y += y
    car.old_pos_y += y
  end
  # Down
  if (car.pos_y > @track.pixel_h + self.height / 2)
    y = (@track.h + 1) * TILE_SIZE + (self.height / TILE_SIZE).floor * TILE_SIZE
    car.pos_y -= y
    car.old_pos_y -= y
  end
end

def create_car(bot = false, replay = nil)
  car_color = bot ? "black" : "blue"
  car = Car.new(@track.car_x * TILE_SIZE, @track.car_y * TILE_SIZE, @track.car_angle * 90, "Images/Cars/car_#{car_color}_small_1.png", bot)

  if (!bot)
    car
  elsif (replay)
    car.replay = replay
    car
  else
    nil
  end
end

def set_car_state(car, state)
  case car.state
  when CarState::Drifting
    car.drift_end = @tick
  end

  car.state = state

  case state
  when CarState::Hopping
    car.hop_start = @tick
    car.drift_dir = 0
  end
end
