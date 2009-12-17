class OnsDatapointsController < ApplicationController
  def show
    @ons_datapoint = OnsDatapoint.find(params[:id])
    @ward = @ons_datapoint.ward
    @council = @ward.council
    @datapoints = @ons_datapoint.related_datapoints
    @title = "#{@ward.title} :: #{@ons_datapoint.title}"
  end

end
