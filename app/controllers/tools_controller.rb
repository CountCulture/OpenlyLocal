class ToolsController < ApplicationController
  before_filter :load_councils
  def gadget
  end

  def ning
  end

  def load_councils
    @councils = Council.parsed({})
  end
end
