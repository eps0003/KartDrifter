module Menus
  MainMenu, TrackSelect, Editor, Controls, Paused, ScorePage = *0...6
end

def create_gui
  [
    [
      TextButton.new("main", "play", self.width / 2, self.height / 1.7 - 90, 0, 0, "Play", "Images/GUI/green_button04.png", "Images/GUI/green_button05.png", Proc.new { set_game_state(GameState::TrackSelect) }),
      TextButton.new("main", "editor", self.width / 2, self.height / 1.7 - 30, 0, 0, "Editor", "Images/GUI/blue_button04.png", "Images/GUI/blue_button05.png", Proc.new { reset_editor() }),
      TextButton.new("main", "controls", self.width / 2, self.height / 1.7 + 30, 0, 0, "Controls", "Images/GUI/blue_button04.png", "Images/GUI/blue_button05.png", Proc.new { set_game_state(GameState::Controls) }),
      TextButton.new("main", "exit", self.width / 2, self.height / 1.7 + 90, 0, 0, "Exit", "Images/GUI/red_button01.png", "Images/GUI/red_button02.png", Proc.new { close! }),
    ], [
      TextButton.new("main", "play", self.width / 2 - 200, self.height - self.height / 10, 0, 0, "Play", "Images/GUI/green_button04.png", "Images/GUI/green_button05.png", Proc.new { start_race_with_ghost() }),
      TextButton.new("main", "delete", self.width / 2, self.height - self.height / 10, 0, 0, "Delete", "Images/GUI/red_button01.png", "Images/GUI/red_button02.png", Proc.new { delete_selected_track() }),
      TextButton.new("main", "menu", self.width / 2 + 200, self.height - self.height / 10, 0, 0, "Main Menu", "Images/GUI/red_button01.png", "Images/GUI/red_button02.png", Proc.new { set_game_state(GameState::MainMenu) }),
      [], # Track buttons
    ], [
      Textbox.new("track name", 20, 20, 200, "Track name", 20),
      Textbox.new("file name", 20, 80, 200, "File name"),
      TextButton.new("main", "save", self.width - 20, 20, 1, -1, "Save Track", "Images/GUI/green_button04.png", "Images/GUI/green_button05.png", Proc.new { save_track() }),
      TextButton.new("main", "load", self.width - 20, 80, 1, -1, "Load Track", "Images/GUI/yellow_button04.png", "Images/GUI/yellow_button05.png", Proc.new { load_track_into_editor() }),
      TextButton.new("main", "back type", self.width - 20, 140, 1, -1, "Background", "Images/GUI/blue_button04.png", "Images/GUI/blue_button05.png", Proc.new { cycle_background_type() }),
      TextButton.new("main", "track type", self.width - 20, 200, 1, -1, "Track Type", "Images/GUI/blue_button04.png", "Images/GUI/blue_button05.png", Proc.new { cycle_track_type() }),
      TextButton.new("main", "grid", self.width - 20, 260, 1, -1, "Toggle Grid", "Images/GUI/blue_button04.png", "Images/GUI/blue_button05.png", Proc.new { toggle_editor_grid() }),
      TextButton.new("main", "reset", self.width - 20, 320, 1, -1, "Reset", "Images/GUI/red_button01.png", "Images/GUI/red_button02.png", Proc.new { reset_editor() }),
      TextButton.new("main", "menu", self.width - 20, 380, 1, -1, "Main Menu", "Images/GUI/red_button01.png", "Images/GUI/red_button02.png", Proc.new { exit_editor() }),
    ], [
      TextButton.new("main", "menu", self.width / 2, self.height - self.height / 10, 0, 0, "Main Menu", "Images/GUI/red_button01.png", "Images/GUI/red_button02.png", Proc.new { set_game_state(GameState::MainMenu) }),
    ], [
      TextButton.new("main", "resume", self.width / 2, self.height / 1.7 - 90, 0, 0, "Resume", "Images/GUI/green_button04.png", "Images/GUI/green_button05.png", Proc.new { @game_paused = false }),
      TextButton.new("main", "retry", self.width / 2, self.height / 1.7 - 30, 0, 0, "Retry", "Images/GUI/blue_button04.png", "Images/GUI/blue_button05.png", Proc.new { start_race_with_ghost() }),
      TextButton.new("main", "change track", self.width / 2, self.height / 1.7 + 30, 0, 0, "Change Track", "Images/GUI/blue_button04.png", "Images/GUI/blue_button05.png", Proc.new { set_game_state(GameState::TrackSelect) }),
      TextButton.new("main", "menu", self.width / 2, self.height / 1.7 + 90, 0, 0, "Main Menu", "Images/GUI/red_button01.png", "Images/GUI/red_button02.png", Proc.new { set_game_state(GameState::MainMenu) }),
    ], [
      TextButton.new("main", "retry", self.width / 3, self.height / 1.7 - 90, 0, 0, "Retry", "Images/GUI/green_button04.png", "Images/GUI/green_button05.png", Proc.new { start_race_with_ghost() }),
      TextButton.new("main", "replay", self.width / 3, self.height / 1.7 - 30, 0, 0, "View Replay", "Images/GUI/blue_button04.png", "Images/GUI/blue_button05.png", Proc.new { start_race_with_replay(@car.replay) }),
      TextButton.new("main", "change track", self.width / 3, self.height / 1.7 + 30, 0, 0, "Change Track", "Images/GUI/blue_button04.png", "Images/GUI/blue_button05.png", Proc.new { set_game_state(GameState::TrackSelect) }),
      TextButton.new("main", "menu", self.width / 3, self.height / 1.7 + 90, 0, 0, "Main Menu", "Images/GUI/red_button01.png", "Images/GUI/red_button02.png", Proc.new { set_game_state(GameState::MainMenu) }),
    ],
  ]
end

def create_track_buttons
  arr = Array.new()

  if (@tracks.size > 0)
    x = self.width / 4
    y = self.height / 2
    n = @tracks.size - 1
    max_rows = 8
    cols = n / max_rows

    i = 0
    while (i < @tracks.size)
      row = i % max_rows
      col = i / max_rows
      e = [n, max_rows - 1].min
      x_offset = (col - cols / 2.0) * 200
      y_offset = (-e / 2.0 + row) * 60

      # Add track button
      arr << TextButton.new(
        "tracks",
        "track",
        x + x_offset,
        y + y_offset,
        0, 0,
        @tracks[i].name,
        "Images/GUI/blue_button04.png",
        "Images/GUI/blue_button05.png",
        Proc.new { |val| select_track(val) },
        i,
        true,
        "Images/GUI/yellow_button04.png",
        "Images/GUI/yellow_button05.png",
      )

      i += 1
    end
  end

  # Add buttons to gui
  @gui[Menus::TrackSelect][-1] = arr
end

def update_gui_elements(elements)
  i = 0
  while (i < elements.size)
    element = elements[i]

    case element.class.name
    when "Array"
      # Recursively update nested arrays
      update_gui_elements(element)
    when "Textbox"
      update_textbox(element)
    end

    i += 1
  end
end

def mouse_over_gui?(elements)
  over_gui = false

  i = 0
  while (i < elements.size && !over_gui)
    element = elements[i]

    case element.class.name
    when "Array"
      # Recursively check nested arrays
      over_gui = mouse_over_gui?(element)
    when "TextButton", "IconButton"
      over_gui = mouse_over_button?(element)
    when "Textbox"
      over_gui = mouse_over_textbox?(element)
    end

    i += 1
  end

  over_gui
end

def find_nearest_scale(scale_levels, scale)
  smallest_scale = scale_levels[0]
  new_scale = smallest_scale

  i = scale_levels.size - 1
  while (i >= 0 && new_scale == smallest_scale)
    scale_level = scale_levels[i]

    if (scale >= scale_level)
      new_scale = scale_level
    end

    i -= 1
  end

  new_scale
end
