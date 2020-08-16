class Textbox < Gosu::TextInput
  attr_accessor :id, :x, :y, :w, :h, :font, :image, :margin_x, :padding_x, :text_x, :text_w, :text_offset_x, :placeholder_text, :selecting_text, :max_length, :text_color, :placeholder_color, :caret_color, :selection_color

  def initialize(id, x, y, w, placeholder_text = "", max_length = 0)
    super()

    @id = id
    @font = Gosu::Font.new(20)
    @image = Gosu::Image.new("Images/GUI/blue_button13.png")
    @x = x
    @y = y
    @w = @image.width
    @h = @image.height
    @margin_x = 5
    @padding_x = 6
    @text_x = @margin_x + @padding_x
    @text_w = @w - @text_x * 2
    @text_offset_x = 0
    @placeholder_text = placeholder_text
    @selecting_text = false
    @max_length = max_length

    @text_color = Gosu::Color::BLACK
    @placeholder_color = Gosu::Color::GRAY
    @caret_color = Gosu::Color::BLACK
    @selection_color = Gosu::Color.new(50, 100, 100, 255)
  end

  def filter(new_text)
    if (@max_length > 0)
      allowed_length = [@max_length - text.length, 0].max
      new_text[0, allowed_length]
    else
      new_text
    end
  end
end

def mouse_over_textbox?(textbox)
  textbox && mouse_in_area?(textbox.x, textbox.y, textbox.w, textbox.h)
end

def move_caret_to_mouse(textbox)
  moved = false

  # Default case: user must have clicked the right edge
  textbox.caret_pos = textbox.selection_start = textbox.text.length

  i = 1
  while (i <= textbox.text.length && !moved)
    if (mouse_x < textbox.x + textbox.text_offset_x + textbox.margin_x + textbox.font.text_width(textbox.text[0...i]))
      textbox.caret_pos = textbox.selection_start = i - 1
      moved = true
    end
    i += 1
  end

  textbox.selecting_text = true
end

def draw_textbox(textbox)
  # Moving caret past left edge
  x = -textbox.font.text_width(textbox.text[0...textbox.caret_pos])
  textbox.text_offset_x = x if (textbox.text_offset_x < x)

  # Moving caret past right edge
  x = textbox.text_w - textbox.font.text_width(textbox.text[0...textbox.caret_pos])
  textbox.text_offset_x = x if (textbox.text_offset_x > x)

  # Sticking text to right edge when deleting
  x = textbox.text_w - textbox.font.text_width(textbox.text)
  textbox.text_offset_x = [0, x].min if (textbox.text_offset_x < x)

  text_x = textbox.x + textbox.text_x + textbox.text_offset_x
  center_y = textbox.y + textbox.h / 2
  text_h = textbox.font.height

  # Calculate the position of the caret and the selection start
  caret_x = text_x + textbox.font.text_width(textbox.text[0...textbox.caret_pos])
  selection_x = text_x + textbox.font.text_width(textbox.text[0...textbox.selection_start])
  selection_w = caret_x - selection_x

  # Draw textbox image
  textbox.image.draw(textbox.x, textbox.y, 0)

  Gosu.clip_to(textbox.x + textbox.margin_x, textbox.y, textbox.w - textbox.margin_x * 2, textbox.h) do
    # Draw caret
    if (self.text_input == textbox)
      Gosu.draw_line(caret_x, center_y - text_h / 2, textbox.caret_color, caret_x, center_y + text_h / 2, textbox.caret_color, 0)
    end

    # Draw selection
    Gosu.draw_rect(selection_x, center_y - text_h / 2, selection_w, text_h, textbox.selection_color, 0)

    # Draw text
    if (textbox.text == "")
      draw_aligned_text(textbox.placeholder_text, textbox.font, text_x, center_y, 0, textbox.placeholder_color, 0, 0.5)
    else
      draw_aligned_text(textbox.text, textbox.font, text_x, center_y, 0, textbox.text_color, 0, 0.5)
    end
  end
end

def textbox_key_down(id)
  textbox = self.text_input
  control = Gosu.button_down?(Gosu::KB_LEFT_CONTROL) || Gosu.button_down?(Gosu::KB_RIGHT_CONTROL)

  case id
  when Gosu::MS_LEFT
    if (mouse_over_textbox?(textbox))
      move_caret_to_mouse(textbox)
    else
      self.text_input = nil
    end
  when Gosu::KB_A
    if (control)
      textbox.selection_start = 0
      textbox.caret_pos = textbox.text.length
    end
  end
end

def update_textbox(textbox)
  left_mouse = Gosu.button_down?(Gosu::MS_LEFT)

  if (textbox.selecting_text)
    moved = false
    index = textbox.text.length

    i = 1
    while (i <= textbox.text.length && !moved)
      if (mouse_x < textbox.x + textbox.text_offset_x + textbox.margin_x + textbox.font.text_width(textbox.text[0...i]))
        index = i - 1
        moved = true
      end
      i += 1
    end

    textbox.selection_start = index
  end

  if (!left_mouse)
    textbox.selecting_text = false
  end

  if (self.text_input != textbox)
    textbox.caret_pos = 0
    textbox.selection_start = 0
  end
end

def get_textbox_by_id(menu, id)
  found_textbox = nil

  i = 0
  while (i < @gui[menu].size && !found_textbox)
    element = @gui[menu][i]

    if (element.class.name == "Textbox")
      if (element.id == id)
        found_textbox = element
      end
    end

    i += 1
  end

  found_textbox
end

def select_textbox(menu)
  i = 0
  while (i < @gui[menu].size)
    element = @gui[menu][i]

    if (element.class.name == "Textbox")
      if (mouse_over_textbox?(element))
        self.text_input = element
      end
    end

    i += 1
  end
end
