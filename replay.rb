class Replay
  attr_accessor :data, :index, :duration

  def initialize()
    @data = Array.new()
    @index = -1
    @duration = 0
  end
end

def add_replay_data(replay, data)
  # Convert to data to integers
  i = 0
  while (i < data.size)
    data[i] = data[i] ? 1 : 0
    i += 1
  end

  # Check if data is the same as last tick
  if (replay.data.size == 0 || replay.data[-1][0...-1] != data)
    # Add new data entry
    replay.data << data
  else
    # Increment last data entry
    replay.data[-1][-1] += 1
  end
end

def faster_replay?(replay)
  !@ghost || replay.data.size < @ghost.replay.data.size
end

def save_replay(replay)
  Dir.mkdir("Replays")

  file_name = File.basename(@track.file_path, ".txt")
  file_path = "Replays/#{file_name}.replay"

  file = File.new(file_path, "w")
  file.puts replay.duration

  # Compress data
  data = compress_replay_data(replay.data)

  # Write data
  i = 0
  while (i < data.size)
    file.puts(data[i].join(" "))
    i += 1
  end

  puts "Saved replay - #{file_path}"
  file.close
end

def load_track_replay
  replay = nil

  file_name = File.basename(@track.file_path, ".txt")
  file_path = "Replays/#{file_name}.replay"

  # Load file
  if (File.file?(file_path))
    file = File.new(file_path, "r")
    replay = Replay.new()

    replay.duration = file.gets.to_i

    # Read data
    data = Array.new()
    while (line = file.gets)
      data << line.chomp.split(" ").map(&:to_i)
    end

    # Decompress data
    replay.data = decompress_replay_data(data)

    puts "Loaded replay - #{file_path}"
  else
    puts "Replay doesn't exist - #{file_path}"
  end

  replay
end

def delete_replay(replay_file_path)
  if (File.exist?(replay_file_path))
    File.delete(replay_file_path)
    puts "Deleted replay - #{replay_file_path}"
  end
end

def start_replay(car)
  car.replay.index = 0
end

def replay_step(car)
  if (replay_in_progress?(car.replay))
    data = car.replay.data[car.replay.index]
    car.up = data[0] == 1
    car.down = data[1] == 1
    car.left = data[2] == 1
    car.right = data[3] == 1
    car.hop = data[4] == 1

    car.replay.index += 1
    if (car.replay.index >= car.replay.data.size)
      puts "Finished replay"
    end
  else
    car.up = false
    car.down = false
    car.left = false
    car.right = false
    car.hop = false
  end
end

def decompress_replay_data(data)
  arr = Array.new()
  i = 0
  while (i < data.size)
    d = data[i]
    j = 0
    while (j < d[-1])
      arr << d[0...-1]
      j += 1
    end
    i += 1
  end
  arr
end

def compress_replay_data(data)
  arr = Array.new()
  i = 0
  while (i < data.size)
    d = data[i]
    if (arr.size == 0 || d != arr[-1][0...-1])
      d << 1
      arr << d
    else
      arr[-1][-1] += 1
    end
    i += 1
  end
  arr
end

def replay_in_progress?(replay)
  (0...replay.data.size).include?(replay.index)
end
