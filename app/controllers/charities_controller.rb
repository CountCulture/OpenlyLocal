class CharitiesController < ApplicationController
  
  def show
    @charity = Charity.find(params[:id])
    @title = "#{@charity.title} :: Charities"
  end
end
