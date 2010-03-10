class PollsController < ApplicationController
  def show
    @poll = Poll.find(params[:id])
    @title = "Election for #{@poll.position} for #{@poll.area.title} #{@poll.area.class} on #{@poll.date_held.to_s(:event_date)}"
    @total_votes = @poll.candidacies.all.sum{ |c| c.votes.to_i }
  end
end
