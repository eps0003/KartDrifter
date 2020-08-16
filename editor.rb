EDITOR_WIDTH = 50
EDITOR_HEIGHT = 50
EDITOR_SCALE_LEVELS = [0.1, 0.15, 0.2, 0.25, 0.5, 0.75, 1.0]
EDITOR_TILE_CATEGORIES = [0..7, 8..12, 13..27, 28..38, 39..43] # Straights, turns, angles, connectors, planes

class Minimap
  attr_accessor :scale, :margin, :border_thickness, :view_thickness, :view_color, :image,
                :x, :y, :w, :h,
                :view_x, :view_y, :view_w, :view_h

  def initialize
    @scale = 2
    @margin = 20
    @border_thickness = 3
    @view_thickness = 2
    @view_color = Gosu::Color.new(255 / 2, 255, 0, 0)

    @w = EDITOR_WIDTH * @scale
    @h = EDITOR_HEIGHT * @scale
    @x = $window.width - @w - @border_thickness - @margin
    @y = $window.height - @h - @border_thickness - @margin
  end
end

def init_editor
  @editor_category = 0
  @editor_tile_rotation = 0
  @editor_scale_index = 0
  @editor_scale = EDITOR_SCALE_LEVELS[@editor_scale_index]

  @editor_car_image = Gosu::Image.new("Images/Cars/car_blue_small_1.png")
  create_editor_buttons()
end

def reset_editor
  @game_state = GameState::Editor

  @editor_tile_rotation = 0

  setup_new_track()

  @editor_minimap = Minimap.new()
  update_minimap()

  @editor_category = 0
  select_tile(0)

  @editor_history = Array.new()
  @editor_history_index = 0
  @editor_actions = Array.new()

  button = get_buttons_by_group(@gui[Menus::Editor], "categories")[0]
  select_button(Menus::Editor, button)

  button = get_buttons_by_group(@gui[Menus::Editor], "buttons")[0]
  select_button(Menus::Editor, button)

  # Reset view
  set_view_scale(0)
  set_view_position(
    EDITOR_WIDTH * TILE_SIZE / 2 * @editor_scale,
    EDITOR_HEIGHT * TILE_SIZE / 2 * @editor_scale
  )
end

def draw_editor
  Gosu.translate(-@view_x, -@view_y) do
    Gosu.scale(@editor_scale, @editor_scale, 0, 0) do
      draw_editor_background()
      draw_track()
      draw_editor_grid()
      draw_editor_car()
      draw_selected_track()
      draw_selected_special()
    end
  end

  if (@editor_tile_index == -1 && @editor_special_selection == "checkpoint")
    draw_checkpoint(@editor_checkpoint_preview) if (@editor_checkpoint_preview)
    draw_checkpoints()
  end
end

def draw_editor_car
  @editor_car_image.draw_rot(@track.car_x * TILE_SIZE, @track.car_y * TILE_SIZE, 0, @track.car_angle * 90, 0.5, 0.5, 1, 1, Gosu::Color::WHITE)
end

def draw_editor_gui_elements(elements)
  i = 0
  while (i < elements.size)
    element = elements[i]

    case element.class.name
    when "TextButton", "IconButton"
      if (button_visible?(element))
        draw_button(element)
      end
    when "Textbox"
      draw_textbox(element)
    when "Array"
      draw_editor_gui_elements(element)
    end

    i += 1
  end
end

def draw_editor_minimap
  @editor_minimap.view_x = @editor_minimap.x + (@view_x * @editor_minimap.w).to_f / (EDITOR_WIDTH * TILE_SIZE * @editor_scale).to_f
  @editor_minimap.view_y = @editor_minimap.y + (@view_y * @editor_minimap.h).to_f / (EDITOR_HEIGHT * TILE_SIZE * @editor_scale).to_f
  @editor_minimap.view_w = self.width.to_f / TILE_SIZE.to_f / @editor_scale * @editor_minimap.scale
  @editor_minimap.view_h = self.height.to_f / TILE_SIZE.to_f / @editor_scale * @editor_minimap.scale

  # Border
  draw_rect_outline(
    @editor_minimap.x - @editor_minimap.border_thickness,
    @editor_minimap.y - @editor_minimap.border_thickness,
    @editor_minimap.w + @editor_minimap.border_thickness * 2,
    @editor_minimap.h + @editor_minimap.border_thickness * 2,
    @editor_minimap.border_thickness,
    Gosu::Color::BLACK
  )

  Gosu.clip_to(@editor_minimap.x, @editor_minimap.y, @editor_minimap.w, @editor_minimap.h) do
    # Background
    draw_rect(
      @editor_minimap.x,
      @editor_minimap.y,
      @editor_minimap.w,
      @editor_minimap.h,
      Gosu::Color.new(255 / 2, 0, 0, 0)
    )

    # Tiles
    @editor_minimap.image.draw(@editor_minimap.x, @editor_minimap.y, 0)

    # View
    draw_rect_outline(
      @editor_minimap.view_x,
      @editor_minimap.view_y,
      @editor_minimap.view_w,
      @editor_minimap.view_h,
      @editor_minimap.view_thickness,
      @editor_minimap.view_color
    )
  end
end

def update_minimap
  @editor_minimap.image = Gosu.record(1, 1) do
    i = 0
    while (i < @track.tiles.size)
      tile = @track.tiles[i]

      scale = 1 / TILE_SIZE.to_f * @editor_minimap.scale
      image = @track_images[@track.track_type][tile.image_index]
      image.draw_rot(
        tile.x * @editor_minimap.scale + 1,
        tile.y * @editor_minimap.scale + 1,
        0,
        tile.rotation * 90,
        0.5, 0.5,
        scale, scale
      )

      i += 1
    end
  end
end

def draw_rect_outline(x, y, width, height, thickness, c, z = 0)
  # Top
  draw_rect(x + thickness, y, width - thickness * 2, thickness, c, z)
  # Left
  draw_rect(x, y, thickness, height, c, z)
  # Bottom
  draw_rect(x + thickness, y + height, width - thickness * 2, -thickness, c, z)
  # Right
  draw_rect(x + width, y, -thickness, height, c, z)
end

def press_editor_buttons
  press_elements(@gui[Menus::Editor])
end

def press_editor_buttons(elements)
  i = 0
  while (i < elements.size)
    element = elements[i]
    if (element.is_a?(Array))
      press_editor_buttons(element)
    elsif (is_button?(element) && button_visible?(element))
      press_button(element)
    end
    i += 1
  end
end

def release_editor_buttons(elements)
  i = 0
  while (i < elements.size)
    element = elements[i]
    if (element.is_a?(Array))
      release_editor_buttons(element)
    elsif (is_button?(element) && button_visible?(element))
      if (release_button(element))
        select_button(Menus::Editor, element)
      end
    end
    i += 1
  end
end

def update_editor
  left_mouse = Gosu.button_down?(Gosu::MS_LEFT)
  right_mouse = Gosu.button_down?(Gosu::MS_RIGHT)
  control = Gosu.button_down?(Gosu::KB_LEFT_CONTROL) || Gosu.button_down?(Gosu::KB_RIGHT_CONTROL)
  alt = button_down?(Gosu::KB_LEFT_ALT) || button_down?(Gosu::KB_RIGHT_ALT)

  if (!left_mouse)
    @panning_editor = control
    @clicking_editor_gui = mouse_over_gui?(@gui[Menus::Editor]) || @clicked_button
  elsif (@clicking_editor_gui)
    # Allow view scaling while clicking on gui elements
    @panning_editor = control
  end

  if (!@clicking_editor_gui)
    if (!@panning_editor)
      x = index_position(editor_position_x(mouse_x))
      y = index_position(editor_position_y(mouse_y))

      if (can_do_stuff?(x, y))
        if (left_mouse)
          if (@editor_tile_index > -1)
            place_tile(x, y, alt)
          elsif (@editor_special_selection == "car")
            place_car(x + 0.5, y + 0.5, @editor_tile_rotation)
          elsif (@editor_special_selection == "checkpoint")
            @editor_checkpoint_preview_p2 = Point.new(x + 0.5, y + 0.5)
            if (@editor_checkpoint_preview_p1)
              @editor_checkpoint_preview = Line.new(@editor_checkpoint_preview_p1, @editor_checkpoint_preview_p2)
            else
              @editor_checkpoint_preview = nil
            end
          end
        end

        if (right_mouse)
          if (@editor_tile_index > -1)
            remove_tile(x, y)
          end
        end
      else
        @editor_checkpoint_preview = nil
      end
    else
      mouse_pan_view() if (left_mouse)
    end
  end

  restrict_view()

  update_gui_elements(@gui[Menus::Editor])
  validate_editor_textboxes()
end

def editor_button_down(id)
  control = Gosu.button_down?(Gosu::KB_LEFT_CONTROL) || Gosu.button_down?(Gosu::KB_RIGHT_CONTROL)
  shift = Gosu.button_down?(Gosu::KB_LEFT_SHIFT) || Gosu.button_down?(Gosu::KB_RIGHT_SHIFT)
  left_mouse = Gosu.button_down?(Gosu::MS_LEFT)

  scroll_up = id == Gosu::MS_WHEEL_UP
  scroll_down = id == Gosu::MS_WHEEL_DOWN
  scroll_dir = (scroll_up ? 1 : 0) - (scroll_down ? 1 : 0)

  scale_view(scroll_dir) if (!left_mouse)

  case id
  when Gosu::KB_SPACE
    dir = shift ? -1 : 1
    rotate_selected_track(dir)
  when Gosu::MS_MIDDLE
    x = index_position(editor_position_x(mouse_x))
    y = index_position(editor_position_y(mouse_y))
    select_tile_at_position(x, y)
  when Gosu::KB_S
    save_track() if (control)
  when Gosu::KB_O
    load_track_into_editor() if (control)
  when Gosu::KB_N
    reset_editor() if (control)
  when Gosu::KB_Z
    if (control)
      if (shift)
        redo_action()
      else
        undo_action()
      end
    end
  when Gosu::KB_Y
    redo_action() if (control)
  when Gosu::KB_G
    toggle_editor_grid() if (control)
  when Gosu::MS_LEFT
    select_textbox(Menus::Editor)

    x = index_position(editor_position_x(mouse_x))
    y = index_position(editor_position_y(mouse_y))

    if (@editor_special_selection == "checkpoint" && can_do_stuff?(x, y))
      @editor_checkpoint_preview_p1 = Point.new(x + 0.5, y + 0.5)
    else
      @editor_checkpoint_preview_p1 = nil
    end
  when Gosu::KB_LEFT
    move_track(-1, 0)
  when Gosu::KB_RIGHT
    move_track(1, 0)
  when Gosu::KB_UP
    move_track(0, -1)
  when Gosu::KB_DOWN
    move_track(0, 1)
  end
end

def editor_button_up(id)
  case id
  when Gosu::MS_LEFT
    x = index_position(editor_position_x(mouse_x))
    y = index_position(editor_position_y(mouse_y))

    if (@editor_special_selection == "checkpoint" && can_do_stuff?(x, y) && valid_checkpoint?(@editor_checkpoint_preview))
      if (!remove_checkpoint(@editor_checkpoint_preview))
        add_checkpoint(@editor_checkpoint_preview)
      end
    end

    @editor_checkpoint_preview = nil

    apply_actions()
  when Gosu::MS_RIGHT
    apply_actions()
  end
end

def setup_new_track
  @track = Track.new()
  @track.w = EDITOR_WIDTH
  @track.h = EDITOR_HEIGHT

  place_car(EDITOR_WIDTH / 2 + 0.5, EDITOR_HEIGHT / 2 + 0.5, 0, false)
  load_editor_background()
end

def validate_editor_textboxes
  i = 0
  while (i < @gui[Menus::Editor].size)
    element = @gui[Menus::Editor][i]

    if (element.class.name == "Textbox")
      track_name_valid = element.id == "track name" && valid_track_name?(element.text)
      file_name_valid = element.id == "file name" && valid_file_name?(element.text)
      if (track_name_valid || file_name_valid)
        element.image = Gosu::Image.new("Images/GUI/blue_button13.png")
      else
        element.image = Gosu::Image.new("Images/GUI/red_button10.png")
      end
    end

    i += 1
  end

  textbox = get_textbox_by_id(Menus::Editor, "track name")
end

def valid_track_name?(track_name)
  track_name.length > 0
end

def valid_file_name?(file_name)
  file_name.match?(/^[a-z_\d-]+$/i)
end

def valid_track?(dim)
  w = dim[2]
  h = dim[3]

  valid_dim = w + h > 0
  valid_checkpoints = @track.checkpoints.size >= 2

  valid_dim && valid_checkpoints
end

def move_track(dir_x, dir_y)
  dim = get_track_dimensions()
  x, y, w, h = *dim

  if (w + h > 0)
    move_x = (dir_x < 0 && x > 0) || (dir_x > 0 && x + w < EDITOR_WIDTH)
    move_y = (dir_y < 0 && y > 0) || (dir_y > 0 && y + h < EDITOR_HEIGHT)

    # Car
    @track.car_x += dir_x if (move_x)
    @track.car_y += dir_y if (move_y)

    # Tiles
    i = 0
    while (i < @track.tiles.size)
      tile = @track.tiles[i]

      tile.x += dir_x if (move_x)
      tile.y += dir_y if (move_y)

      i += 1
    end

    # Checkpoints
    i = 0
    while (i < @track.checkpoints.size)
      checkpoint = @track.checkpoints[i]

      checkpoint.p1.x += dir_x if (move_x)
      checkpoint.p1.y += dir_y if (move_y)
      checkpoint.p2.x += dir_x if (move_x)
      checkpoint.p2.y += dir_y if (move_y)

      i += 1
    end
  end
end

def undo_action
  if (@editor_history.size > 0)
    do_history_action(0)
    @editor_history_index = [@editor_history_index - 1, -1].max
  end
end

def redo_action
  if (@editor_history.size > 0)
    old_index = @editor_history_index
    @editor_history_index = [@editor_history_index + 1, @editor_history.size - 1].min
    do_history_action(1) if (old_index != @editor_history_index)
  end
end

def apply_actions
  if (@editor_actions.size > 0)
    @editor_history.slice!((@editor_history_index + 1)..-1)
    @editor_history << @editor_actions
    @editor_history_index = @editor_history.size - 1
    @editor_actions = Array.new()
  end
end

# 0 for undo, 1 for redo
def do_history_action(index)
  if (@editor_history_index > -1)
    actions = @editor_history[@editor_history_index]

    i = actions.size - 1
    while (i >= 0)
      type = actions[i][0]

      case type
      when "tile"
        tile = actions[i][index + 1]

        if (tile.image_index < 0)
          remove_tile(tile.x, tile.y, false)
        else
          set_tile(tile.x, tile.y, tile.image_index, tile.rotation)
        end
      when "checkpoint"
        checkpoint = actions[i][1]
        arr_index = actions[i][2]

        if (!remove_checkpoint(checkpoint, false))
          add_checkpoint_to_index(checkpoint, arr_index, false)
        end
      when "car"
        ii = (index == 0) ? i : (@editor_actions.size - 1 - i)
        car = actions[ii][index + 1]

        x = car[0]
        y = car[1]
        angle = car[2]

        place_car(x, y, angle, false)
      end

      i -= 1
    end

    update_minimap()
  end
end

def restrict_view
  w = EDITOR_WIDTH * TILE_SIZE * @editor_scale - self.width / 2
  h = EDITOR_HEIGHT * TILE_SIZE * @editor_scale - self.height / 2

  @view_x = @view_x.clamp(-self.width / 2, w)
  @view_y = @view_y.clamp(-self.height / 2, h)
end

def scale_view(scroll_dir)
  x = editor_position_x(mouse_x)
  y = editor_position_y(mouse_y)

  old_index = @editor_scale_index

  index = @editor_scale_index + scroll_dir
  set_view_scale(index)

  # Check if scale changed
  if (old_index != @editor_scale_index)
    # Position view relative to cursor
    @view_x = (x * @editor_scale - self.width * mouse_x / self.width).round
    @view_y = (y * @editor_scale - self.height * mouse_y / self.height).round
  end
end

def set_view_scale(index)
  @editor_scale_index = index.clamp(0, EDITOR_SCALE_LEVELS.size - 1)
  @editor_scale = EDITOR_SCALE_LEVELS[@editor_scale_index]
end

def mouse_pan_view
  x = editor_position_x(@old_mouse_x)
  y = editor_position_y(@old_mouse_y)

  @view_x = (x * @editor_scale - self.width * mouse_x / self.width).round
  @view_y = (y * @editor_scale - self.height * mouse_y / self.height).round
end

# Draws background tiles to a singular image which only needs to be drawn once for the entire background
# https://www.rubydoc.info/github/gosu/gosu/master/Gosu#record-class_method
def load_editor_background
  x_extra = (self.width / TILE_SIZE.to_f / EDITOR_SCALE_LEVELS[0] / 2).ceil
  y_extra = (self.height / TILE_SIZE.to_f / EDITOR_SCALE_LEVELS[0] / 2).ceil

  @editor_background = Gosu.record(1, 1) do
    x = -x_extra
    while (x < EDITOR_WIDTH + x_extra)
      y = -y_extra
      while (y < EDITOR_HEIGHT + y_extra)
        color = position_in_bounds?(x, y) ? Gosu::Color::WHITE : Gosu::Color.new(255 / 2, 255, 255, 255)
        background = @background_images[@track.background_type]
        background.draw(x * TILE_SIZE, y * TILE_SIZE, 0, 1, 1, color)
        y += 1
      end
      x += 1
    end
  end
end

def draw_editor_background
  @editor_background.draw(0, 0, 0)
end

def cycle_background_type
  index = (@track.background_type + 1) % BACKGROUND_IMAGES.size
  set_background_type(index)
end

def cycle_track_type
  index = (@track.track_type + 1) % TRACK_IMAGES.size
  set_track_type(index)
end

def draw_selected_track
  if (@editor_tile_index > -1)
    ix = index_position(editor_position_x(mouse_x))
    iy = index_position(editor_position_y(mouse_y))

    if (can_do_stuff?(ix, iy))
      alt = button_down?(Gosu::KB_LEFT_ALT) || button_down?(Gosu::KB_RIGHT_ALT)

      x = aligned_position(editor_position_x(mouse_x))
      y = aligned_position(editor_position_y(mouse_y))

      track = @track_images[@track.track_type][@editor_tile_index]
      color = (track_at_position?(ix, iy) && !alt) ? Gosu::Color.new(255 / 2, 255, 0, 0) : Gosu::Color.new(255 / 2, 255, 255, 255)
      track.draw_rot(x + TILE_SIZE / 2, y + TILE_SIZE / 2, 0, @editor_tile_rotation * 90, 0.5, 0.5, 1, 1, color)
    end
  end
end

def can_do_stuff?(x, y)
  position_in_bounds?(x, y) && !mouse_over_gui?(@gui[Menus::Editor]) && !@panning_editor && !@clicking_editor_gui
end

def draw_selected_special
  if (@editor_special_selection)
    ix = index_position(editor_position_x(mouse_x))
    iy = index_position(editor_position_y(mouse_y))

    if (can_do_stuff?(ix, iy))
      alt = button_down?(Gosu::KB_LEFT_ALT) || button_down?(Gosu::KB_RIGHT_ALT)

      x = aligned_position(editor_position_x(mouse_x)) + TILE_SIZE / 2
      y = aligned_position(editor_position_y(mouse_y)) + TILE_SIZE / 2

      if (@editor_special_selection == "car")
        @editor_car_image.draw_rot(x, y, 0, @editor_tile_rotation * 90, 0.5, 0.5, 1, 1, Gosu::Color::WHITE)
      elsif (@editor_special_selection == "checkpoint")
        circle = Gosu::Image.new("Images/GUI/grey_circle.png") #Gosu::Image.new(Circle.new(10))
        color = Gosu::Color::RED
        circle.draw_rot(x, y, 0, 0)
      end
    end
  end
end

def place_tile(x, y, overwrite)
  if (@editor_tile_index > -1)
    old_tile = get_track_tile(x, y)
    new_tile = TrackTile.new(x, y, @editor_tile_index, @editor_tile_rotation)

    if (position_in_bounds?(x, y) && (overwrite || !old_tile) && !mouse_over_gui?(@gui[Menus::Editor]) && !same_tile?(old_tile, new_tile))
      remove_tile(x, y, false)

      @track.tiles << new_tile

      update_minimap()

      if (old_tile)
        @editor_actions << ["tile", old_tile, new_tile]
      else
        @editor_actions << ["tile", TrackTile.new(x, y, -1, -1), new_tile]
      end
    end
  end
end

def place_car(x, y, angle = 0, add_action = true)
  old_car = [@track.car_x, @track.car_y, @track.car_angle]

  @track.car_x = x
  @track.car_y = y
  @track.car_angle = angle

  new_car = [@track.car_x, @track.car_y, @track.car_angle]
  @editor_actions << ["car", old_car, new_car] if (add_action && old_car != new_car)
end

def set_tile(x, y, image_index, rotation)
  remove_tile(x, y, false)
  @track.tiles << TrackTile.new(x, y, image_index, rotation)
  update_minimap()
end

def add_checkpoint(checkpoint, add_action = true)
  @track.checkpoints << checkpoint
  @editor_actions << ["checkpoint", checkpoint, @track.checkpoints.size - 1] if (add_action)
end

def add_checkpoint_to_index(checkpoint, index, add_action = true)
  @track.checkpoints.insert(index, checkpoint)
  @editor_actions << ["checkpoint", checkpoint, index] if (add_action)
end

def remove_checkpoint(checkpoint, add_action = true)
  removed = false

  i = 0
  while (i < @track.checkpoints.size && !removed)
    cp = @track.checkpoints[i]

    if (same_checkpoint?(cp, checkpoint))
      @track.checkpoints.delete_at(i)
      removed = true
      @editor_actions << ["checkpoint", checkpoint, i] if (add_action)
    end

    i += 1
  end

  removed
end

def remove_tile(x, y, add_action = true)
  index = get_track_tile_index(x, y)
  if (index > -1)
    removed_tile = @track.tiles[index]
    @track.tiles.delete_at(index)

    if (add_action)
      @editor_actions << ["tile", removed_tile, TrackTile.new(x, y, -1, -1)]
      update_minimap()
    end
  end
end

def position_in_bounds?(x, y)
  x >= 0 && y >= 0 && x < EDITOR_WIDTH && y < EDITOR_HEIGHT
end

def rotate_selected_track(dir)
  @editor_tile_rotation = (@editor_tile_rotation + dir) % 4
end

def same_tile?(tile1, tile2)
  # Both are exact same tile or both nil
  (tile1 == tile2) ||
    # Both have same properties
  (tile1 && tile2 && tile1.image_index == tile2.image_index && tile1.rotation == tile2.rotation)
end

def select_tile(index)
  @editor_tile_index = index
  deselect_special()
end

def select_special(special)
  @editor_special_selection = special
  deselect_tile()
end

def deselect_tile
  @editor_tile_index = -1
end

def deselect_special
  @editor_special_selection = nil
end

def select_tile_at_position(x, y)
  track = get_track_tile(x, y)
  if (track)
    @editor_tile_index = track.image_index
    @editor_tile_rotation = track.rotation
  end
end

def set_category(index)
  @editor_category = index
end

def create_editor_buttons
  categories = Array.new()
  track_buttons = Array.new()
  special_buttons = Array.new()

  i = 0
  while (i < EDITOR_TILE_CATEGORIES.size)
    track = @track_images[@track.track_type][EDITOR_TILE_CATEGORIES[i].first]
    categories << IconButton.new(
      "categories",
      "tile",
      20 + i * 60,
      self.height - 80,
      -1, 1,
      track,
      "Images/GUI/green_button11.png",
      "Images/GUI/green_button12.png",
      Proc.new { |val| set_category(val) },
      i,
      true,
      "Images/GUI/red_button06.png",
      "Images/GUI/red_button07.png"
    )

    x = 0
    while (x < EDITOR_TILE_CATEGORIES[i].size)
      index = EDITOR_TILE_CATEGORIES[i].to_a[x]
      track = @track_images[@track.track_type][index]

      track_buttons << IconButton.new(
        "buttons",
        "tile",
        20 + x * 60,
        self.height - 20,
        -1, 1,
        track,
        "Images/GUI/blue_button09.png",
        "Images/GUI/blue_button10.png",
        Proc.new { |val| select_tile(val) },
        index,
        true,
        "Images/GUI/yellow_button09.png",
        "Images/GUI/yellow_button10.png"
      )

      x += 1
    end
    i += 1
  end

  special_category = IconButton.new(
    "categories",
    "special",
    20 + i * 60,
    self.height - 80,
    -1, 1,
    "Images/Objects/arrow_white.png",
    "Images/GUI/green_button11.png",
    "Images/GUI/green_button12.png",
    Proc.new { |val| set_category(val) },
    i,
    true,
    "Images/GUI/red_button06.png",
    "Images/GUI/red_button07.png"
  )

  # Special
  car_button = IconButton.new(
    "buttons",
    "special",
    20 + 0 * 60,
    self.height - 20,
    -1, 1,
    Gosu::Image.new("Images/Cars/car_blue_small_1.png"),
    "Images/GUI/blue_button09.png",
    "Images/GUI/blue_button10.png",
    Proc.new { |val| select_special(val) },
    "car",
    true,
    "Images/GUI/yellow_button09.png",
    "Images/GUI/yellow_button10.png"
  )
  checkpoint_button = TextButton.new(
    "buttons",
    "special",
    20 + 1 * 60,
    self.height - 20,
    -1, 1,
    "CP",
    "Images/GUI/blue_button09.png",
    "Images/GUI/blue_button10.png",
    Proc.new { |val| select_special(val) },
    "checkpoint",
    true,
    "Images/GUI/yellow_button09.png",
    "Images/GUI/yellow_button10.png"
  )

  @gui[Menus::Editor] << categories + [special_category]
  @gui[Menus::Editor] << track_buttons
  @gui[Menus::Editor] << [car_button, checkpoint_button]
end

def update_editor_track_buttons
  buttons = get_buttons_by_group(@gui[Menus::Editor], "buttons")

  i = 0
  while (i < buttons.size)
    button = buttons[i]

    if (button.id == "tile")
      image = @track_images[@track.track_type][button.value]
      button.image = image
    end

    i += 1
  end

  buttons = get_buttons_by_group(@gui[Menus::Editor], "categories")

  i = 0
  while (i < buttons.size - 1)
    button = buttons[i]

    if (button.id == "tile")
      image = @track_images[@track.track_type][EDITOR_TILE_CATEGORIES[i].first]
      button.image = image
    end

    i += 1
  end
end

def save_track
  track_name = get_textbox_by_id(Menus::Editor, "track name").text
  file_name = get_textbox_by_id(Menus::Editor, "file name").text
  dim = get_track_dimensions()

  if (valid_track_name?(track_name) && valid_file_name?(file_name) && valid_track?(dim))
    file_path = TRACKS_FOLDER + file_name + ".txt"

    file = File.new(file_path, "w")

    # Track info
    file.puts track_name

    # Track top left position
    xx = dim[0] - 1
    yy = dim[1] - 1

    # Tile types
    file.puts [@track.track_type, @track.background_type].join(" ")
    file.puts [@track.car_x - xx, @track.car_y - yy, @track.car_angle].join(" ")

    # Track dimensions
    w = dim[2] + 2
    h = dim[3] + 2
    file.puts [w, h].join(" ")

    # Track tiles
    y = yy
    while (y < yy + h)
      x = xx
      arr = Array.new()
      while (x < xx + w)
        track = get_track_tile(x, y)
        if (track)
          arr << track.image_index.to_s.rjust(2, "0") + "-" + track.rotation.to_s
        else
          arr << "----"
        end
        x += 1
      end
      file.puts arr.join(" ")
      y += 1
    end

    # Checkpoints
    file.puts @track.checkpoints.size
    i = 0
    while (i < @track.checkpoints.size)
      checkpoint = @track.checkpoints[i]
      file.puts [checkpoint.p1.x - xx, checkpoint.p1.y - yy, checkpoint.p2.x - xx, checkpoint.p2.y - yy].join(" ")
      i += 1
    end

    puts "Saved track - #{@track.name} (#{file_path})"
    file.close()

    delete_replay("Replays/#{file_name}.replay")
    @tracks = load_tracks()
  else
    puts "Unable to save track"
  end
end

def can_load_track_into_editor?(file_name)
  file_path = TRACKS_FOLDER + file_name + ".txt"
  valid_file_name?(file_name) && File.exist?(file_path)
end

def load_track_into_editor
  file_name = get_textbox_by_id(Menus::Editor, "file name").text
  if (can_load_track_into_editor?(file_name))
    file_path = TRACKS_FOLDER + file_name + ".txt"
    @track = load_track(file_path)
    load_editor_background()
    center_track()
    update_minimap()
  else
    puts "Unable to load track"
  end
end

def center_track
  dim = get_track_dimensions()
  x, y, w, h = *dim

  center_x = EDITOR_WIDTH / 2 - w / 2 - 1 - x
  center_y = EDITOR_HEIGHT / 2 - h / 2 - 1 - y

  # Tiles
  i = 0
  while (i < @track.tiles.size)
    tile = @track.tiles[i]

    tile.x += center_x
    tile.y += center_y

    i += 1
  end

  # Car
  @track.car_x += center_x
  @track.car_y += center_y

  # Checkpoints
  i = 0
  while (i < @track.checkpoints.size)
    checkpoint = @track.checkpoints[i]

    checkpoint.p1.x += center_x
    checkpoint.p1.y += center_y
    checkpoint.p2.x += center_x
    checkpoint.p2.y += center_y

    i += 1
  end
end

def get_track_dimensions
  if (@track.tiles.size > 0)
    smallest_x = EDITOR_WIDTH
    smallest_y = EDITOR_HEIGHT
    largest_x = largest_y = 0

    i = 0
    while (i < @track.tiles.size)
      track = @track.tiles[i]

      smallest_x = track.x if (track.x < smallest_x)
      smallest_y = track.y if (track.y < smallest_y)
      largest_x = track.x if (track.x > largest_x)
      largest_y = track.y if (track.y > largest_y)

      i += 1
    end

    # Calculate width
    w = largest_x - smallest_x + 1
    h = largest_y - smallest_y + 1

    # Return x, y, w, h
    return smallest_x, smallest_y, w, h
  end

  return 0, 0, 0, 0
end

def exit_editor
  set_game_state(GameState::MainMenu)
  set_track(0)
end

def toggle_editor_grid
  @editor_grid = !@editor_grid
end

def draw_editor_grid
  if (@editor_grid)
    color = Gosu::Color.new(255 / 3, 0, 0, 0)

    i = 1
    while (i < EDITOR_WIDTH)
      x1 = i * TILE_SIZE
      y1 = 0
      x2 = x1
      y2 = EDITOR_HEIGHT * TILE_SIZE

      draw_line(x1, y1, color, x2, y2, color)

      i += 1
    end

    i = 1
    while (i < EDITOR_HEIGHT)
      x1 = 0
      y1 = i * TILE_SIZE
      x2 = EDITOR_WIDTH * TILE_SIZE
      y2 = y1

      draw_line(x1, y1, color, x2, y2, color)

      i += 1
    end
  end
end

def set_track_type(index)
  @track.track_type = index
  update_editor_track_buttons()
  update_minimap()
end

def set_background_type(index)
  @track.background_type = index
  load_editor_background()
end

def aligned_position(pos)
  index_position(pos) * TILE_SIZE
end

def index_position(pos)
  (pos / TILE_SIZE).floor
end

def editor_position_x(screen_pos_x)
  (@view_x + screen_pos_x) / @editor_scale
end

def editor_position_y(screen_pos_y)
  (@view_y + screen_pos_y) / @editor_scale
end

def screen_position_x(pos)
  pos * @editor_scale - @view_x
end

def screen_position_y(pos)
  pos * @editor_scale - @view_y
end
