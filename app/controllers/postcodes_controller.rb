class PostcodesController < ApplicationController
  def show
    @postcode = Postcode.find_from_messy_code params[:id]
    respond_to do |format|
      format.json do
        render :json => @postcode ? @postcode.to_json(:only => [:lat, :lng]) : ''
      end
    end
  end
end
