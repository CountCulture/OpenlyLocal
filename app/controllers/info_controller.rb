class InfoController < ApplicationController
  before_filter :assign_title
  def about_us
  end
  
  def api
    @sample_council = Council.first  
  end
  
  def vocab
    render :layout => false
  end
  
  private
  def assign_title
    @title = action_name.titleize + " :: Info"
  end
end
