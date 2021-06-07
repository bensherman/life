require "set"

require "gosu"
require "rmagick"
class Grid
  attr_accessor :cells

  def initialize
    @cells = Set[]
  end

  def add_cell(x, y)
    @cells.add({ x: x, y: y })
  end

  def delete_cell(x, y)
    @cells.delete({ x: x, y: y })
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
    @cell_size = 20
    @height = 60
    @width = 60
    super @width * @cell_size, @height * @cell_size, @options = { update_interval: 100 }
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

    @alive = Gosu::Image.new(circle(@cell_size))
  end

  def circle(diameter, color = 'green', opacity = 1, bg = 'black')
    r = diameter / 2 - 1
    image = Magick::Image.new(diameter, diameter, Magick::SolidFill.new(bg))
    c = Magick::Draw.new
    c.fill_opacity opacity
    c.fill(color)
    c.circle(r, r, 0, r)
    c.draw(image)
    image
  end

  def update
    if @deleting
      puts(mouse_x, mouse_y)
      cell_x = mouse_x.to_i / @cell_size
      cell_y = mouse_y.to_i / @cell_size
      @grid.delete_cell cell_x, cell_y
      puts("adding cell at #{cell_x} #{cell_y}")
      @alive_cells.delete({ x: cell_x, y: cell_y })
    end
    if @adding
      puts(mouse_x, mouse_y)
      cell_x = mouse_x.to_i / @cell_size
      cell_y = mouse_y.to_i / @cell_size
      @grid.add_cell cell_x, cell_y
      puts("adding cell at #{cell_x} #{cell_y}")
      @alive_cells.append({ x: cell_x, y: cell_y })
    end
    return if @paused || @mouse_paused

    @alive_cells = []
    puts("cells: #{@grid.cells.length}")
    @grid.cells.each do |c|
      @alive_cells.append(c) if c[:x].positive? && c[:x] < @width && c[:y].positive? && c[:y] < @height
    end
    @grid.next
  end

  def draw
    puts("alive pixels: #{@alive_cells.length}")
    @alive_cells.each do |c|
      @alive.draw(c[:x] * @cell_size, c[:y] * @cell_size)
    end
  end

  def button_down(id)
    case id
    when Gosu::KB_SPACE
      @paused = !@paused
    when Gosu::MS_LEFT
      @mouse_paused = true
      if @shift
        @deleting = true
      else
        @adding = true
      end
    when Gosu::KB_LEFT_SHIFT
      @shift = true
    end
  end

  def button_up(id)
    case id
    when Gosu::MS_LEFT
      @adding = false
      @deleting = false
      @mouse_paused = false
    when Gosu::KB_LEFT_SHIFT
      @shift = false
    end
  end
end

Game.new.show if __FILE__ == $0
