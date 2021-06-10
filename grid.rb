class Grid
  attr_accessor :cells, :timestamp

  def initialize
    @cells = {}
    @timestamp = 0
  end

  def neighbors(cell)
    x = cell[:x]
    y = cell[:y]
    [
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

  def cell_has_pulse?(cell)
    # check to see if this cell will be alive in the next iteration
    live_neighbors = count_live_neighbors cell
    case live_neighbors
    when 2
      return true if cells.include? cell
    when 3
      return true
    end
    false
  end

  def add_cell(cell)
    @cells[cell] = 0
  end

  def delete_cell(cell)
    @cells.delete cell
  end

  def next
    new_cells = {}
    cells.each_key do |cell|
      neighbors(cell).each do |neighbor|
        new_cells[neighbor] = new_cells.fetch(neighbor, 0) + 1
      end
    end

    new_cells.each do |cell, n|
      if n < 2 || n > 3
        new_cells.delete cell
      elsif n == 2 && @cells[cell].nil?
        new_cells.delete cell
      end
    end

    @cells = new_cells
  end
end
