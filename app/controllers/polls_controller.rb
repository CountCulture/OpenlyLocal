class PollsController < ApplicationController
  def show
    @poll = Poll.find(params[:id])
    @title = "Election for #{@poll.position} for #{@poll.area.title} on #{@poll.date_held.to_s(:event_date)}"
  end
end
