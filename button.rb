class TextButton
  attr_accessor :group, :id, :x, :y, :h_align, :v_align, :text, :normal_image, :pressed_image, :selected_image, :selected_pressed_image, :w, :h, :click_proc, :value, :selectable, :selected

  def initialize(group, id, x, y, h_align, v_align, text, normal_path, pressed_path, click_proc, value = nil, selectable = false, selected_image = "", selected_pressed_image = "")
    @group = group
    @id = id
    @x = x
    @y = y
    @h_align = h_align
    @v_align = v_align
    @text = text
    @normal_image = Gosu::Image.new(normal_path)
    @pressed_image = Gosu::Image.new(pressed_path)
    @w = @normal_image.width
    @h = @normal_image.height
    @click_proc = click_proc
    @value = value
    @selectable = selectable
    @selected = false
    if (selectable)
      @selected_image = Gosu::Image.new(selected_image)
      @selected_pressed_image = Gosu::Image.new(selected_pressed_image)
    end
  end
end

class IconButton
  attr_accessor :group, :id, :x, :y, :h_align, :v_align, :image, :normal_image, :pressed_image, :selected_image, :selected_pressed_image, :w, :h, :click_proc, :value, :selectable, :selected

  def initialize(group, id, x, y, h_align, v_align, image_path, normal_path, pressed_path, click_proc, value = nil, selectable = false, selected_image = "", selected_pressed_image = "")
    @group = group
    @id = id
    @x = x
    @y = y
    @h_align = h_align
    @v_align = v_align
    @image = Gosu::Image.new(image_path)
    @normal_image = Gosu::Image.new(normal_path)
    @pressed_image = Gosu::Image.new(pressed_path)
    @w = @normal_image.width
    @h = @normal_image.height
    @click_proc = click_proc
    @value = value
    @selectable = selectable
    @selected = false
    if (selectable)
      @selected_image = Gosu::Image.new(selected_image)
      @selected_pressed_image = Gosu::Image.new(selected_pressed_image)
    end
  end
end

def mouse_over_button?(button)
  if (button_visible?(button))
    x_offset = button.w / 2 + button.w / 2 * button.h_align
    y_offset = button.h / 2 + button.h / 2 * button.v_align

    mouse_in_area?(button.x - x_offset, button.y - y_offset, button.w, button.h)
  else
    false
  end
end

def press_buttons(elements)
  i = 0
  while (i < elements.size)
    element = elements[i]
    if (element.is_a?(Array))
      # Recursively press buttons in nested arrays
      press_buttons(element)
    elsif (is_button?(element))
      press_button(element)
    end
    i += 1
  end
end

def press_button(button)
  if (mouse_over_button?(button))
    @clicked_button = button
    Gosu::Sample.new("Sounds/GUI/click1.ogg").play(0.05)
    true
  else
    false
  end
end

def release_buttons(elements)
  i = 0
  while (i < elements.size)
    element = elements[i]
    if (element.is_a?(Array))
      # Recursively release buttons in nested arrays
      release_buttons(element)
    elsif (is_button?(element))
      release_button(element)
    end
    i += 1
  end
end

def release_button(button)
  if (mouse_over_button?(button) && @clicked_button == button)
    Gosu::Sample.new("Sounds/GUI/click2.ogg").play(0.05)
    button.click_proc.call(button.value)
    true
  else
    false
  end
end

def select_button(menu, button)
  if (button.selectable)
    buttons = get_buttons_by_group(@gui[menu], button.group)
    deselect_buttons(buttons)
    button.selected = true
  end
end

def is_button?(gui_element)
  class_name = gui_element.class.name
  class_name == "TextButton" || class_name == "IconButton"
end

def draw_button(button)
  w = button.normal_image.width
  h = button.normal_image.height

  x_offset = w / 2 * button.h_align
  y_offset = h / 2 * button.v_align

  x = button.x - button.w / 2 - x_offset
  y = button.y - button.h / 2 - y_offset

  pressed_offset = 0

  if (mouse_over_button?(button) && Gosu.button_down?(Gosu::MsLeft) && @clicked_button == button)
    pressed_offset = 4
    if (button.selected)
      button.selected_pressed_image.draw(x, y + pressed_offset, 0)
    else
      button.pressed_image.draw(x, y + pressed_offset, 0)
    end
  else
    if (button.selected)
      button.selected_image.draw(x, y, 0)
    else
      button.normal_image.draw(x, y, 0)
    end
  end

  case button.class.name
  when "TextButton"
    draw_aligned_text(button.text, @body_font, button.x - x_offset, button.y - y_offset + pressed_offset)
  when "IconButton"
    padding = 20
    x_scale = (button.normal_image.width - padding) / button.image.width.to_f
    y_scale = (button.normal_image.height - padding) / button.image.height.to_f

    if (x_scale <= y_scale)
      ratio = button.image.width / button.image.height
      y_scale = x_scale * ratio
    else
      ratio = button.image.height / button.image.width
      x_scale = y_scale * ratio
    end

    button.image.draw_rot(button.x - x_offset, button.y - y_offset + pressed_offset - 2, 0, 0, 0.5, 0.5, x_scale, y_scale)
  end
end

def button_visible?(button)
  if (@editor_category < EDITOR_TILE_CATEGORIES.size)
    button.group != "buttons" || EDITOR_TILE_CATEGORIES[@editor_category].include?(button.value)
  else
    button.group != "buttons" || button.id == "special"
  end
end

def get_buttons_by_group(elements, group)
  buttons = Array.new()

  i = 0
  while (i < elements.size)
    element = elements[i]

    if (element.is_a?(Array))
      buttons += get_buttons_by_group(element, group)
    elsif (is_button?(element))
      if (element.group == group)
        buttons << element
      end
    end

    i += 1
  end

  buttons
end

def get_buttons_by_id(elements, id)
  buttons = Array.new()

  i = 0
  while (i < elements.size)
    element = elements[i]

    if (element.is_a?(Array))
      buttons += get_buttons_by_id(element, id)
    elsif (is_button?(element))
      if (element.id == id)
        buttons << element
      end
    end

    i += 1
  end

  buttons
end

def deselect_buttons(buttons)
  i = 0
  while (i < buttons.size)
    buttons[i].selected = false
    i += 1
  end
end
