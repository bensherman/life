require "set"
require "gosu"
require "rmagick"
require "benchmark"
require "byebug"

class Grid
  attr_accessor :cells, :timestamp

  def initialize
    @cells = Set[]
    @timestamp = 0
  end

  def add_cell(cell)
    @cells.add(cell)
  end

  def delete_cell(cell)
    @cells.delete(cell)
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

class Life < Gosu::Window
  def initialize
    setup
    super @width * @cell_size, @height * @cell_size
    self.caption = "Life"
  end

  def setup
    @height = 50
    @width = 50
    @cell_size = 20
    @grid = Grid.new
    @grid.timestamp = 0
    @alive_cells = []
    @alive_image = cell_image
    @step_time = 0
    @step_time_shift_ms = 25
    @offset = { x: 0, y: 0 }
    @print_info = true
  end

  def cell_image(color = "green", opacity = 1, bg = "black")
    r = @cell_size / 2
    image = Magick::Image.new(@cell_size, @cell_size, Magick::SolidFill.new(bg))
    c = Magick::Draw.new
    c.fill_opacity opacity
    c.fill(color)
    if @cell_size > 3
      c.circle(r, r, 1, r)
    else
      c.rectangle(0, 0, @cell_size, @cell_size)
    end
    c.draw(image)
    Gosu::Image.new(image)
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
    puts "mouse_location (relative): #{mouse_location}"
    puts "alive? #{alive?}"
    puts "offset: #{@offset}"
    puts "moving_coords: #{@moving_coords}"
    puts "cells: #{@grid.cells.length}"
    puts "cell_size: #{@cell_size}"
    puts "displayed: #{@alive_cells.length}"
    puts "fps: #{Gosu.fps}"
  end

  def random_fill
    pixel_count = @width * @height
    fill_percent = 10
    fill_count = pixel_count / fill_percent
    fill_count.times do
      @grid.add_cell({ x: rand(@width) + @offset[:x], y: rand(@height) + @offset[:y] })
    end
  end

  def grow
    @cell_size += 1
    @alive_image = cell_image
    @width = (width / @cell_size).to_i
    @height = (height / @cell_size).to_i
  end

  def shrink
    return unless @cell_size > 2

    @cell_size -= 1
    @alive_image = cell_image
    @width = (width / @cell_size).to_i
    @height = (height / @cell_size).to_i
  end

  def update
    if @deleting
      @grid.delete_cell mouse_location
      @alive_cells.delete(mouse_location)
    end

    if @adding
      @grid.add_cell(mouse_location)
      @alive_cells.append(mouse_location)
    end

    @alive_cells = []
    @grid.cells.each do |cell|
      @alive_cells.append(cell) if in_view? cell
    end
    info if @print_info
    set_offset if @moving

    return if @paused || @mouse_paused
    return unless Gosu.milliseconds - @grid.timestamp > @step_time

    @grid.next
    @grid.timestamp = Gosu.milliseconds
  end

  def in_view?(cell)
    (
      cell[:x] >= @offset[:x] &&
      cell[:x] < @offset[:x] + @width &&
      cell[:y] >= @offset[:y] &&
      cell[:y] < @offset[:y] + @height
    )
  end

  def set_offset
    @offset[:x] = (@moving_coords[:x] - (mouse_x / @cell_size)).to_i
    @offset[:y] = (@moving_coords[:y] - (mouse_y / @cell_size)).to_i
  end

  def draw
    @alive_cells.each do |c|
      @alive_image.draw((c[:x] - @offset[:x]) * @cell_size, (c[:y] - @offset[:y]) * @cell_size)
    end
  end

  def alive?
    @grid.cells.include? mouse_location
  end

  def mouse_location
    { x: (mouse_x / @cell_size).to_i + @offset[:x],
      y: (mouse_y / @cell_size).to_i + @offset[:y] }
  end

  def button_down(id)
    case id
    when Gosu::KB_SPACE
      @paused = !@paused
    when Gosu::MS_LEFT
      @mouse_paused = true
      if alive?
        @deleting = true
      else
        @adding = true
      end
    when Gosu::KB_LEFT_SHIFT
      @shift = true
    when Gosu::KB_F
      random_fill
    when Gosu::KB_R
      setup
    when Gosu::KB_S
      @grid.next
    when Gosu::KB_NUMPAD_MINUS
      slowdown
    when Gosu::KB_NUMPAD_PLUS
      speedup
    when Gosu::KB_I
      @print_info = !@print_info
    when Gosu::MS_RIGHT
      @mouse_paused = true
      @moving = true
      @moving_coords = mouse_location
    when Gosu::MS_WHEEL_UP
      grow
    when Gosu::MS_WHEEL_DOWN
      shrink
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

Life.new.show if __FILE__ == $0
