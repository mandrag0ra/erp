class Backend::Cells::DemoPieCellsController < Backend::CellsController

  def show
    max = rand(1_000_000)
    @values = (rand(3) + 2).times.inject({}) do |hash, index|
      hash["Month #{index}"] = rand(max)
      hash
    end
  end

end