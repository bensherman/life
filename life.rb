require "byebug"
require "set"
require "gosu"
require "benchmark"

class Grid
  attr_accessor :cells

  def initialize
    @cells = Set[]
  end

  def add_cell(x, y)
    @cells.add({ x: x, y: y })
  end

  def neighbors(x, y)
    Set[
      { x: x + 1, y: y + 1 }, # northeast
      { x: x - 1, y: y - 1 }, # southwest
      { x: x + 1, y: y - 1 }, # southeast
      { x: x - 1, y: y + 1 }, # northwest
      { x: x + 1, y: y }, # east
      { x: x, y: y + 1 }, # north
      { x: x - 1, y: y }, # west
      { x: x, y: y - 1 } # south
    ]
  end

  def next
    new_cells = cells.dup
    checklist = cells.dup
    cells.each do |cell|
      checklist += neighbors(cell[:x], cell[:y])
    end

    puts("checklist size: #{checklist.length}")
    checklist.each do |cell|
      live_neighbors = count_live_neighbors(cell[:x], cell[:y])
      if live_neighbors < 2 || live_neighbors > 3
        new_cells.delete cell
      elsif live_neighbors == 3
        new_cells.add({ x: cell[:x], y: cell[:y] })
      end
    end
    @cells = new_cells
  end

  def count_live_neighbors(x, y)
    (@cells & neighbors(x, y)).length
  end
end

class Game < Gosu::Window
  def initialize
    @pixel_size = 10
    @height = 100
    @width = 100
    super @width * @pixel_size, @height * @pixel_size, @options = { update_interval: 10 }
    self.caption = "Life"
    @grid = Grid.new
    @grid.add_cell(0, 0)
    @grid.add_cell(1, 0)
    @grid.add_cell(2, 0)
    @grid.add_cell(2, 10)
    @alive_cells = []
    1000.times do
      @grid.add_cell(rand(@width), rand(@height))
    end

    @alive = record(@pixel_size, @pixel_size) do
      draw_rect(0, 0, @pixel_size, @pixel_size, Gosu::Color::WHITE)
    end
  end

  def update
    if @adding
      puts(mouse_x, mouse_y)
      pixel_x = mouse_x.to_i / @pixel_size
      pixel_y = mouse_y.to_i / @pixel_size
      @grid.add_cell pixel_x, pixel_y
      puts("adding cell at #{pixel_x} #{pixel_y}")
      @alive_cells.append({ x: pixel_x, y: pixel_y })
    end
    unless @paused || @mouse_paused
      @alive_cells = []
      puts("cells: #{@grid.cells.length}")
      @grid.cells.each do |c|
        @alive_cells.append(c) if c[:x].positive? && c[:x] < @width && c[:y].positive? && c[:y] < @height
      end
      @grid.next
    end
  end

  def draw
    puts("alive pixels: #{@alive_cells.length}")
    @alive_cells.each do |c|
      @alive.draw(c[:x] * @pixel_size, c[:y] * @pixel_size)
    end
  end

  def button_down(id)
    case id
    when Gosu::KB_SPACE
      @paused = !@paused
    when Gosu::MS_LEFT
      @mouse_paused = true
      @adding = true
    end
  end

  def button_up(id)
    case id
    when Gosu::MS_LEFT
      @adding = false
      @mouse_paused = false
    end
  end
end

Game.new.show if __FILE__ == $0
