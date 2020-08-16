TRACKS_FOLDER = "Tracks/"
TRACK_IMAGES = ["Images/Tiles/Asphalt road/", "Images/Tiles/Dirt road/", "Images/Tiles/Sand road/"]
BACKGROUND_IMAGES = ["Images/Tiles/Grass/land_grass04.png", "Images/Tiles/Dirt/land_dirt05.png", "Images/Tiles/Sand/land_sand05.png"]
TILE_SIZE = 128

class Track
  attr_accessor :file_path, :name, :w, :h, :tiles, :checkpoints, :pixel_w, :pixel_h, :track_type, :background_type, :car_x, :car_y, :car_angle

  def initialize()
    @name = "Custom Track"
    @tiles = Array.new()
    @checkpoints = Array.new()
    @w = @h = 0
    @pixel_w = 0
    @pixel_h = 0
    @track_type = 0
    @background_type = 0
    @car_x = 0.0
    @car_y = 0.0
    @car_angle = 0.0
  end
end

class TrackTile
  attr_accessor :x, :y, :image_index, :rotation

  def initialize(x, y, image_index, rotation)
    @x = x
    @y = y
    @image_index = image_index
    @rotation = rotation
  end
end

def load_tracks
  files = Dir.entries(TRACKS_FOLDER)
  tracks = Array.new()

  i = 2
  while (i < files.size)
    tracks << load_track(TRACKS_FOLDER + files[i])
    i += 1
  end

  tracks
end

def load_track(file_path)
  file = File.new(file_path, "r")
  track = Track.new()

  # Track info
  track.file_path = file_path
  track.name = file.gets.chomp

  # Tile types
  tile_types = file.gets.chomp.split(" ")
  track.track_type = tile_types[0].to_i
  track.background_type = tile_types[1].to_i

  # Car variables
  car_vars = file.gets.chomp.split(" ")
  track.car_x = car_vars[0].to_f
  track.car_y = car_vars[1].to_f
  track.car_angle = car_vars[2].to_f

  # Track dimensions
  dim = file.gets.chomp.split(" ")
  track.w = dim[0].to_i
  track.h = dim[1].to_i

  # Track tiles
  track.tiles = Array.new()

  y = 0
  while (y < track.h)
    line = file.gets.chomp.split(" ")

    x = 0
    while (x < line.size)
      data = line[x]
      if (data != "----")
        vars = data.split("-")
        image_index = vars[0].to_i
        rotation = vars[1].to_i

        track.tiles << TrackTile.new(x, y, image_index, rotation)
      end
      x += 1
    end
    y += 1
  end

  track.pixel_w = track.w * TILE_SIZE
  track.pixel_h = track.h * TILE_SIZE

  # Checkpoints
  count = file.gets.chomp.to_i

  i = 0
  while (i < count)
    data = file.gets.chomp.split(" ")

    p1 = Point.new(data[0].to_f, data[1].to_f)
    p2 = Point.new(data[2].to_f, data[3].to_f)

    track.checkpoints << Line.new(p1, p2)

    i += 1
  end

  puts "Loaded track - #{track.name} (#{file_path})"

  file.close()
  track
end

def draw_background
  if (in_game?)
    x = (@view_x / TILE_SIZE).floor * TILE_SIZE
    y = (@view_y / TILE_SIZE).floor * TILE_SIZE
  else
    x = (-@tick / 2) % TILE_SIZE.to_f - TILE_SIZE
    y = (@tick / 2) % TILE_SIZE.to_f - TILE_SIZE
  end

  @full_backgrounds[@track.background_type].draw(x, y, 0)
end

def draw_track
  i = 0
  while (i < @track.tiles.size)
    tile = @track.tiles[i]
    x = (tile.x + 0.5) * TILE_SIZE
    y = (tile.y + 0.5) * TILE_SIZE
    image = @track_images[@track.track_type][tile.image_index]
    image.draw_rot(x, y, 0, tile.rotation * 90, 0.5, 0.5)
    i += 1
  end
end

def get_track_tile(x, y)
  found_track = nil
  i = 0
  while (i < @track.tiles.size && !found_track)
    track = @track.tiles[i]
    if (track.x == x && track.y == y)
      found_track = track
    end
    i += 1
  end
  found_track
end

def get_track_tile_index(x, y)
  found_index = -1

  i = 0
  while (i < @track.tiles.size && found_index == -1)
    track = @track.tiles[i]
    if (track.x == x && track.y == y)
      found_index = i
    end
    i += 1
  end

  found_index
end

def track_at_position?(x, y)
  get_track_tile(x, y) != nil
end

def valid_cell?(x, y)
  x >= 0 && x < @track.w &&
  y >= 0 && y < @track.h
end

# Loads each type of track tile
def load_all_track_images
  arr = Array.new()

  i = 0
  while (i < TRACK_IMAGES.size)
    arr << load_track_images(TRACK_IMAGES[i])
    i += 1
  end

  puts "Loaded track images"
  arr
end

# Loads each tile of a type of track
def load_track_images(folder_path)
  files = Dir.entries(folder_path)
  arr = Array.new()

  i = 2
  while (i < files.size)
    arr << Gosu::Image.new(folder_path + files[i])
    i += 1
  end

  arr
end

# Loads each type of background tile
def load_background_images
  arr = Array.new()

  i = 0
  while (i < BACKGROUND_IMAGES.size)
    arr << Gosu::Image.new(BACKGROUND_IMAGES[i])
    i += 1
  end

  arr
end

# Draws background tiles to a singular image which only needs to be drawn once for the entire background
def load_full_backgrounds
  arr = Array.new()

  i = 0
  while (i < @background_images.size)
    arr << load_full_background(@background_images[i])
    i += 1
  end

  arr
end

def load_full_background(background_image)
  Gosu.record(1, 1) do
    w = self.width / TILE_SIZE.to_f + 1
    h = self.height / TILE_SIZE.to_f + 1

    x = 0
    while (x < w)
      y = 0
      while (y < h)
        background_image.draw(x * TILE_SIZE, y * TILE_SIZE, 0)
        y += 1
      end
      x += 1
    end
  end
end

def select_track(index)
  set_track(index)
  if (valid_track_index?(index))
    buttons = get_buttons_by_group(@gui[Menus::TrackSelect], "tracks")
    select_button(Menus::TrackSelect, buttons[@track_index])
  end
end

def set_track(index)
  @track_index = index
  if (valid_track_index?(index))
    @track = @tracks[index]
  else
    @track = Track.new()
  end
end

def valid_track_index?(index)
  (0...@tracks.size).include?(index)
end

def delete_selected_track()
  if (valid_track_index?(@track_index) && File.exist?(@track.file_path))
    File.delete(@track.file_path)
    puts "Deleted track - #{@track.file_path}"

    @tracks = load_tracks()
    index = [@track_index, @tracks.size - 1].min
    set_track(index)
    set_game_state(GameState::TrackSelect)
  end
end
