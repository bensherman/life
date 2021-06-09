require "set"
require "gosu"
require "rmagick"
require "benchmark"
require "byebug"

class Grid
  attr_accessor :cells, :timestamp

  def initialize
    clear
    @timestamp = 0
  end

  def add_cell(cell)
    @cells.add(cell)
  end

  def delete_cell(cell)
    @cells.delete(cell)
  end

  def clear
    @cells = Set[]
  end

  def reset
    clear
    @offset = {x: 0, y: 0}
  end

  def neighbors(cell)
    x = cell[:x]
    y = cell[:y]
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
    checked = Set[]

    cells.each do |cell|
      checks = Set[cell] + neighbors(cell)

      checks.each do |c|
        next if checked.include? c

        live_neighbors = count_live_neighbors c
        if live_neighbors < 2 || live_neighbors > 3
          new_cells.delete c
        elsif live_neighbors == 3
          new_cells.add c
        end
      end
    end
    @cells = new_cells
  end

  def count_live_neighbors(cell)
    (@cells & neighbors(cell)).length
  end
end

class Game < Gosu::Window
  def initialize
    @cell_size = 20
    @height = 60
    @width = 60
    super @width * @cell_size, @height * @cell_size
    self.caption = "Life"
    @grid = Grid.new
    @grid.timestamp = 0
    @alive_cells = []
    @alive = Gosu::Image.new(circle(@cell_size))
    @step_time = 0
    @step_time_shift_ms = 25
    @offset = { x: 0, y: 0 }
    @print_info = true
  end

  def circle(diameter, color = "green", opacity = 1, bg = "black")
    r = diameter / 2 - 1
    image = Magick::Image.new(diameter, diameter, Magick::SolidFill.new(bg))
    c = Magick::Draw.new
    c.fill_opacity opacity
    c.fill(color)
    c.circle(r, r, 0, r)
    c.draw(image)
    image
  end

  def speedup
    if (@step_time -= @step_time_shift_ms).negative?
      @step_time = 0
    else
      @step_time -= @step_time_shift_ms
    end
  end

  def slowdown
    @step_time += @step_time_shift_ms
  end

  def info
    puts "step_time: #{@step_time}"
    puts "mouse_x, mouse_y: #{mouse_x}, #{mouse_y}"
    puts "offset: #{@offset}"
    puts "moving_coords: #{@moving_coords}"
    puts "cells: #{@grid.cells.length}"
    puts "displayed: #{@alive_cells.length}"
    puts "fps: #{Gosu.fps}"
  end

  def random_fill
    pixel_count = @width * @height
    fill_percent = 10
    fill_count = pixel_count / fill_percent
    fill_count.times do
      @grid.add_cell({ x: rand(@width), y: rand(@height) })
    end
  end

  def update
    if @deleting
      cell_x = (mouse_x / @cell_size).to_i + @offset[:x]
      cell_y = (mouse_y / @cell_size).to_i + @offset[:y]
      @grid.delete_cell({ x: cell_x, y: cell_y })
      @alive_cells.delete({ x: cell_x, y: cell_y })
    end

    if @adding
      cell_x = (mouse_x / @cell_size).to_i + @offset[:x]
      cell_y = (mouse_y / @cell_size).to_i + @offset[:y]
      @grid.add_cell({ x: cell_x, y: cell_y })
      @alive_cells.append({ x: cell_x, y: cell_y })
    end

    @alive_cells = []
    @grid.cells.each do |cell|
      @alive_cells.append(cell) if in_view? cell
    end
    info if @print_info
    set_offset if @moving
    return if @paused || @mouse_paused

    if Gosu.milliseconds - @grid.timestamp > @step_time
      @grid.next
      @grid.timestamp = Gosu.milliseconds
    end
  end

  def in_view?(cell)
    (
      cell[:x] > @offset[:x] &&
      cell[:x] < @offset[:x] + @width &&
      cell[:y] > @offset[:y] &&
      cell[:y] < @offset[:y] + @height
    )
  end

  def set_offset
    @offset[:x] = (@moving_coords[:x] - (mouse_x / @cell_size)).to_i
    @offset[:y] = (@moving_coords[:y] - (mouse_y / @cell_size)).to_i
  end

  def draw
    @alive_cells.each do |c|
      @alive.draw((c[:x] - @offset[:x]) * @cell_size, (c[:y] - @offset[:y]) * @cell_size)
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
    when Gosu::KB_F
      random_fill
    when Gosu::KB_R
      @grid.reset
    when Gosu::KB_NUMPAD_MINUS
      slowdown
    when Gosu::KB_NUMPAD_PLUS
      speedup
    when Gosu::KB_I
      @print_info = !@print_info
    when Gosu::MS_RIGHT
      @mouse_paused = true
      @moving = true
      @moving_coords = { x: (mouse_x / @cell_size).to_i + @offset[:x], y: (mouse_y / @cell_size).to_i + @offset[:y] }
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
    when Gosu::MS_RIGHT
      @mouse_paused = false
      @moving = false
    end
  end
end

Game.new.show if __FILE__ == $0
