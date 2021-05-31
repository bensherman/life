require "set"

class Grid
  attr_accessor :cells

  def initialize
    @cells = Set[]
  end

  def add_cell(x, y)
    cells.add({ x: x, y: y })
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
    new_grid = Grid.new
    new_grid.cells = cells.dup

    checklist = cells.dup
    cells.each do |cell|
      checklist += neighbors(cell[:x], cell[:y])
    end

    checklist.each do |cell|
      live_neighbors = count_live_neighbors(cell[:x], cell[:y])
      if live_neighbors < 2 || live_neighbors > 3
        new_grid.cells.delete cell
      elsif live_neighbors == 3
        new_grid.add_cell(cell[:x], cell[:y])
      end
    end
    new_grid
  end

  def count_live_neighbors(x, y)
    (@cells & neighbors(x, y)).length
  end
end

class Screen
  def initialize(width, height)
    @width = width
    @height = height
  end

  def draw(cells)
    (-@height / 2..@height / 2).each do |y|
      (-@width / 2..@width / 2).each do |x|
        c = cells.include?({ x: x, y: y }) ? "*" : " "
        print c
      end
      puts
    end
  end
end

if __FILE__ == $0
  height = 25
  width = 80
  grid = Grid.new
  grid.add_cell(0, 0)
  grid.add_cell(1, 0)
  grid.add_cell(2, 0)
  grid.add_cell(2, 10)
  1000.times do
    grid.add_cell(rand(-width/2..width/2), rand(-height/2..height/2))
  end

  screen = Screen.new(width, height)
  loop do
    screen.draw grid.cells
    puts(grid.cells.length)
    grid = grid.next
    sleep 0.2
  end
end
