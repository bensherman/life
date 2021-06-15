require "grid"

RSpec.describe Grid do
  describe "#neighbors" do
    it "has exactly 8 neighbors" do
      expect(Grid.new.neighbors({ x: 0, y: 0 }).length).to eq(8)
    end

    it "has neighbors in all directions" do
      neighbors = Grid.new.neighbors({ x: 0, y: 0 })
      expect(neighbors).to include({ x: 1, y: 1 })
      expect(neighbors).to include({ x: -1, y: -1 })
      expect(neighbors).to include({ x: 1, y: -1 })
      expect(neighbors).to include({ x: -1, y: 1 })
      expect(neighbors).to include({ x: 1, y: 0 })
      expect(neighbors).to include({ x: -1, y: 0 })
      expect(neighbors).to include({ x: 0, y: 1 })
      expect(neighbors).to include({ x: 0, y: -1 })
    end
  end

  describe "#next" do
    it "is stable with three cells in a line" do
      grid = Grid.new
      grid.add_cell({ x: 0, y: 0 })
      grid.add_cell({ x: 1, y: 0 })
      grid.add_cell({ x: 2, y: 0 })
      10.times { grid.next }
      expect(grid.cells).to eq(
        {
          { x: 1, y: 0 } => 0,
          { x: 2, y: 0 } => 0,
          { x: 0, y: 0 } => 0
        }
      )
    end
  end
end
