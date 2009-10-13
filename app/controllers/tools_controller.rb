class ToolsController < ApplicationController
  def gadget
    @councils = Council.parsed({})
  end

  def ning
    @councils = Council.parsed({})
  end

end
