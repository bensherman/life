require "gosu"
require "byebug"

class Life < Gosu::Window
  def initialize
    super 1000, 1000
    self.caption = "larf"
    @cursor_x = 500
    @cursor_y = 500
  end

  def draw
  end
end

class Cell
  def initialize(alive: false)
    @alive = alive
  end

  def alive?
    @alive
  end

  def die!
    @alive = false
  end
end

class Location
  attr_reader :x, :y

  def initialize(coords)
    @x = coords[0]
    @y = coords[1]
  end

  def hash
    coords.hash
  end

  def eql?(other)
    x == other.x && y == other.y
  end

  def coords
    [x, y]
  end

  def n
    y = @y + 1
    x = @x
    Location.new([x, y])
  end

  def s
    y = @y - 1
    x = @x
    Location.new([x, y])
  end

  def e
    y = @y
    x = @x + 1
    Location.new([x, y])
  end

  def w
    y = @y
    x = @x - 1
    Location.new([x, y])
  end

  def nw
    y = @y + 1
    x = @x - 1
    Location.new([x, y])
  end

  def ne
    y = @y + 1
    x = @x + 1
    Location.new([x, y])
  end

  def sw
    y = @y - 1
    x = @x - 1
    Location.new([x, y])
  end

  def se
    y = @y - 1
    x = @x + 1
    Location.new([x, y])
  end

  def neighbors
    [n, ne, e, se, s, sw, w, nw]
  end
end

class Grid
  attr_accessor :cells
  def initialize(width, height)
    @screen_w = width
    @screen_h = height
    @cells = {}
  end

  def draw
    (-@screen_h/2..@screen_h/2).each do |y|
      (-@screen_w/2..@screen_w/2).each do |x|
        c = cells[Location.new([x,y])]&.alive? ? "O" : "."
        print(c)
      end
      puts("")
      STDOUT.flush
    end
    puts("\n\n\n")
  end

  def add(x, y)
    location = Location.new([x,y])
    cells[location] = Cell.new(alive: true)
    location.neighbors.each do |neighbor|
      cells[neighbor] = cells.fetch(neighbor, Cell.new)
    end
  end

  def deep_dup(obj)
    Marshal.load(Marshal.dump(obj))
  end

  def next
    new_cells = deep_dup cells

    cells.each do |location, _cell|
      alive_neighbors = 0
      location.neighbors.each do |neighbor|
        cells[neighbor]&.alive? && alive_neighbors += 1
      end

      if alive_neighbors.zero?
        new_cells.delete location
      elsif alive_neighbors == 1 || alive_neighbors > 3
        new_cells[location]&.die!
      elsif alive_neighbors == 2
        next
      elsif alive_neighbors == 3
        new_cells[location] = Cell.new(alive: true)
        location.neighbors.each do |neighbor|
          new_cells[neighbor] = new_cells.fetch(neighbor, Cell.new(alive: false))
        end
      end
    end
    @cells = new_cells
  end
end

if __FILE__ == $0
  height = 30
  width = 120
  grid = Grid.new(width, height)
  grid.add(0, 0)
  grid.add(1, 0)
  grid.add(2, 0)
  1000.times do
    grid.add(rand(-width..width), rand(-height..height))
  end

  loop do
    grid.draw
    grid.next
    sleep 0.3
  end
end