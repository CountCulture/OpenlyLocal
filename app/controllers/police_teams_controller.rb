class PoliceTeamsController < ApplicationController
  def show
    @police_team = PoliceTeam.find(params[:id])
    @title = @police_team.name
  end
end
