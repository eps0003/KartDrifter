LAPS = 3
COUNTDOWN_TIME = 3
POSTGAME_TIME = 2
MISSED_CHECKPOINT_PENALTY = 20

module GameState
  MainMenu, TrackSelect, Editor, Controls, PreGame, MidGame, PostGame, ScorePage = *0...8
end

def update_game
  manage_game_state()
  update_car(@ghost) if (@ghost)
  update_car(@car)

  # Move view in front of car depending on velocity
  angle_radians = Gosu::degrees_to_radians(@car.image_angle)
  vel_x = Math.sin(angle_radians) * @car.vel
  vel_y = -Math.cos(angle_radians) * @car.vel
  set_view_position(@car.pos_x + vel_x * 10, @car.pos_y + vel_y * 10)
end

def set_view_position(x, y)
  @view_x = (x - self.width / 2).round
  @view_y = (y - self.height / 2).round
end

def manage_game_state
  case @game_state
  when GameState::PreGame
    if (@game_time >= COUNTDOWN_TIME * 60)
      set_game_state(GameState::MidGame)
      Gosu::Sample.new("Sounds/go.mp3").play(0.05)
    elsif (@game_time % 60 == 0)
      Gosu::Sample.new("Sounds/321.mp3").play(0.05)
    end
  when GameState::PostGame
    if (@game_time >= POSTGAME_TIME * 60)
      set_game_state(GameState::ScorePage)
    end
  end

  if (in_game?)
    @game_time += 1
  end
end

def start_race_with_ghost
  if (valid_track_index?(@track_index))
    set_game_state(GameState::PreGame)
    @car = create_car()
    replay = load_track_replay()
    @ghost = create_car(true, replay)
    start_replay(@ghost) if (@ghost)
  end
end

def start_race_with_replay(replay)
  if (valid_track_index?(@track_index))
    set_game_state(GameState::PreGame)
    replay = load_track_replay() if (!replay)
    @car = create_car(true, replay)
    @ghost = nil
    start_replay(@car)
  end
end

def set_game_state(index)
  @game_state = index
  @game_time = 0

  # Stop song if one is playing
  if (@song)
    @song.stop()
    @song = nil
  end

  # Initialize stuff depending on game state
  case @game_state
  when GameState::TrackSelect
    create_track_buttons()
    select_track(@track_index)
  when GameState::PreGame
    @game_paused = false
    @gui_ease_time = Gosu.milliseconds
  when GameState::PostGame
    Gosu::Sample.new("Sounds/gunshot.mp3").play(0.1)
    @car.replay.duration = @car.replay.data.size + @car.missed_checkpoints * MISSED_CHECKPOINT_PENALTY * 60
    save_replay(@car.replay) if (!@car.bot && faster_replay?(@car.replay))
  when GameState::ScorePage
    if (!@car.bot)
      @song = Gosu::Song.new("Sounds/cheering.mp3")
      @song.volume = 0.05
    end
  end

  @song.play if (@song)
end
