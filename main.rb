require "gosu"
require "./gui.rb"
require "./button.rb"
require "./textbox.rb"
require "./checkpoint.rb"
require "./replay.rb"
require "./car.rb"
require "./track.rb"
require "./game.rb"
require "./editor.rb"
require "./draw.rb"
require "./util.rb"

DEFAULT_WIDTH = 1280
DEFAULT_HEIGHT = 720
FONT_NAME = "Newsflash BB"

class Game < Gosu::Window
  def initialize
    # Launch options
    width = DEFAULT_WIDTH
    height = DEFAULT_HEIGHT
    fullscreen = false

    if (ARGV.size >= 2)
      width = ARGV[0].to_i
      height = ARGV[1].to_i
    end

    if (ARGV.size >= 3)
      fullscreen = true?(ARGV[2])
    end

    # Setup window
    super(width, height, fullscreen)
    self.caption = "Kart Drifter"

    # Initialize
    $window = self
    @tick = 0

    @title_font = Gosu::Font.new(self, FONT_NAME, 100)
    @header_font = Gosu::Font.new(self, FONT_NAME, 40)
    @body_font = Gosu::Font.new(self, FONT_NAME, 30)

    @view_x = 0
    @view_y = 0

    @track_index = 0

    @gui = create_gui()
    @tracks = load_tracks()
    @track_images = load_all_track_images()
    @background_images = load_background_images()
    @full_backgrounds = load_full_backgrounds()
    set_track(0)
    set_game_state(GameState::MainMenu)
    init_editor()
  end

  def needs_cursor?
    in_menu?
  end

  def button_down(id)
    editor_button_down(id) if (@game_state == GameState::Editor)
    textbox_key_down(id) if (text_input)

    case id
    when Gosu::KB_ESCAPE
      if (in_game?)
        # Toggle paused
        @game_paused = !@game_paused
      else
        # Go back to main menu
        if (@game_state == GameState::MainMenu)
          close!
        else
          set_game_state(GameState::MainMenu)
        end
      end
    when Gosu::MsLeft
      # Press gui buttons
      case @game_state
      when GameState::MainMenu
        press_buttons(@gui[Menus::MainMenu])
      when GameState::TrackSelect
        press_buttons(@gui[Menus::TrackSelect])
      when GameState::Editor
        press_editor_buttons(@gui[Menus::Editor])
      when GameState::Controls
        press_editor_buttons(@gui[Menus::Controls])
      when GameState::ScorePage
        press_buttons(@gui[Menus::ScorePage])
      end

      press_buttons(@gui[Menus::Paused]) if (@game_paused)
    end
  end

  def button_up(id)
    editor_button_up(id) if (@game_state == GameState::Editor)

    case id
    when Gosu::MsLeft
      # Release gui buttons
      case @game_state
      when GameState::MainMenu
        release_buttons(@gui[Menus::MainMenu])
      when GameState::TrackSelect
        release_buttons(@gui[Menus::TrackSelect])
      when GameState::Editor
        release_editor_buttons(@gui[Menus::Editor])
      when GameState::Controls
        release_buttons(@gui[Menus::Controls])
      when GameState::ScorePage
        release_buttons(@gui[Menus::ScorePage])
      end

      release_buttons(@gui[Menus::Paused]) if (@game_paused)

      @clicked_button = nil
    end
  end

  def update
    # Un-pause when not it game
    if (!in_game? && @game_paused)
      @game_paused = false
    end

    if (!in_game?)
      if (@game_state == GameState::Editor)
        update_editor()
      else
        @view_x = 0
        @view_y = 0
      end
    elsif (!@game_paused)
      update_game()
    end

    # Save old mouse position for editor panning
    @old_mouse_x = mouse_x
    @old_mouse_y = mouse_y

    # Tick game
    @tick += 1
  end

  def draw
    if (in_game?)
      draw_game()
    else
      if (@game_state == GameState::Editor)
        draw_editor()
      else
        draw_background()
      end
    end

    draw_gui()

    if (@game_state == GameState::TrackSelect)
      draw_track_select_preview()
    end
  end
end

Game.new.show if (__FILE__ == $0)
