#!/usr/bin/env ruby

require "set"
require "gosu"
require "rmagick"
require "byebug"

require_relative "grid"

class Life < Gosu::Window
  def initialize
    setup
    @height = 50
    @width = 50
    super @width * @cell_size, @height * @cell_size, { resizable: true }
    self.caption = "Life"
  end

  def setup
    @cell_size = 20
    @grid = Grid.new
    @grid.timestamp = 0
    @alive_cells = []
    @cell_color = "green3"
    @alive_image = cell_image
    @dead_images = new_dead_images
    @step_time = 10
    @step_time_shift_ms = 10
    @offset = { x: 0, y: 0 }
    @print_info = true
  end

  def new_dead_images
    (1..10).collect do |opacity|
      cell_image(color: @cell_color, opacity: opacity / 10.0)
    end
  end

  def cell_image(color: @cell_color, opacity: 1, bg: "black")
    radius = @cell_size / 2
    image = Magick::Image.new(@cell_size, @cell_size, Magick::SolidFill.new(bg))
    drawing = Magick::Draw.new
    drawing.fill_opacity opacity
    drawing.fill(color)
    if @cell_size > 3
      drawing.circle(radius, radius, 1, radius)
    else
      drawing.rectangle(0, 0, @cell_size, @cell_size)
    end
    drawing.draw(image)
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
    puts "width, height: #{width}, #{height}"
    puts "@width, @height: #{@width}, #{@height}"
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
    @dead_images = new_dead_images
  end

  def shrink
    return unless @cell_size > 2

    @cell_size -= 1
    @alive_image = cell_image
    @dead_images = new_dead_images
  end

  def update
    @width = (width / @cell_size).to_i
    @height = (height / @cell_size).to_i

    if @deleting
      @grid.delete_cell mouse_location
      @alive_cells.delete(mouse_location)
    end

    if @adding
      @grid.add_cell(mouse_location)
      @alive_cells.append(mouse_location)
    end

    @alive_cells = []
    @grid.cells.each do |cell, _|
      @alive_cells.append(cell) if in_view? cell
    end

    @dead_cells = {}
    if @afterglow
      @grid.dead.each do |cell, opacity|
        @dead_cells[cell] = opacity if in_view? cell
      end
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
    @dead_cells.each do |cell, opacity|
      @dead_images[opacity].draw((cell[:x] - @offset[:x]) * @cell_size, (cell[:y] - @offset[:y]) * @cell_size)
    end
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
    when Gosu::KB_LEFT_SHIFT
      @shift = true
    when Gosu::KB_G
      @afterglow = !@afterglow
    when Gosu::KB_F
      random_fill
    when Gosu::KB_I
      @print_info = !@print_info
    when Gosu::KB_Q
      close!
    when Gosu::KB_R
      setup
    when Gosu::KB_S
      @grid.next
    when Gosu::KB_NUMPAD_MINUS, Gosu::KB_MINUS
      slowdown
    when Gosu::KB_NUMPAD_PLUS, Gosu::KB_EQUALS
      speedup
    when Gosu::MS_RIGHT
      @mouse_paused = true
      @moving = true
      @moving_coords = mouse_location
    when Gosu::MS_LEFT
      @mouse_paused = true
      if alive?
        @deleting = true
      else
        @adding = true
      end
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

