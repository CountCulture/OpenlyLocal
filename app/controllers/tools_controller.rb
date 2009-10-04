class ToolsController < ApplicationController
  def gadget
    @councils = Council.parsed
    render :layout => false
  end

  def ning
  end

end
