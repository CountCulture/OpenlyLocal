class CharitiesController < ApplicationController
  
  def show
    @charity = Charity.find(params[:id], :include => { :supplying_relationships => :organisation })
    @title = "#{@charity.title} :: Charities"
  end
end
