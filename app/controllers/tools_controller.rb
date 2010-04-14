class ToolsController < ApplicationController
  before_filter :load_councils
  def gadget
  end

  def ning
  end

  def widget
  end

  private
  def load_councils
    if params[:council_id].blank?
      @councils = Council.parsed({})
    else
      @council = Council.find(params[:council_id])
    end
  end
end
