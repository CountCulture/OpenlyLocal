class ParishCouncilsController < ApplicationController
  
  def show
    @parish_council = ParishCouncil.find_by_os_id(params[:os_id])
    @title = @parish_council.title
  end
end
