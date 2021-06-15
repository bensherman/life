class Grid
  attr_accessor :cells, :dead, :timestamp

  def initialize
    @cells = {}
    @dead = {}
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

  def add_cell(cell)
    cells[cell] = 0
  end

  def delete_cell(cell)
    dead[cell] = 5 if @cells[cell]
    @cells.delete cell
  end

  def next
    neighbor_tracker = Hash.new(0)
    cells.each_key do |cell|
      neighbors(cell).each do |neighbor|
        neighbor_tracker[neighbor] += 1
      end
      # this is a way to get the default set if it does not exist,
      # but leave it alone if it does.
      neighbor_tracker[cell] = neighbor_tracker[cell]
    end

    neighbor_tracker.each do |cell, n|
      case n
      when 2
        next
      when 3
        add_cell cell unless @cells[cell]
      else
        delete_cell cell
      end
    end

    @dead.each_pair do |cell, time|
      time -= 1
      if time <= 0
        @dead.delete cell
        next
      end
      @dead[cell] = time
    end
  end
end
