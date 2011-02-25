class ParishCouncilsController < ApplicationController
  
  def show
    @parish_council = params[:os_id] ? ParishCouncil.find_by_os_id(params[:os_id]) : ParishCouncil.find(params[:id])
    @title = @parish_council.title
  end
end
