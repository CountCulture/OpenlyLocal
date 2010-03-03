class PoliceTeamsController < ApplicationController
  def show
    @police_team = PoliceTeam.find(params[:id])
    @title = @police_team.extended_title
  end
end
