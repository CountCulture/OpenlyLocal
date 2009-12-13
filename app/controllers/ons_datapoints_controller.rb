class OnsDatapointsController < ApplicationController
  def show
    @ons_datapoint = OnsDatapoint.find(params[:id])
    @related_datapoints = @ons_datapoint.related_datapoints
    @title = @ons_datapoint.title
  end

end
