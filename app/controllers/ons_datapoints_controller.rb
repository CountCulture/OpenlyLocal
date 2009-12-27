class OnsDatapointsController < ApplicationController
  helper :wards
  def show
    @ons_datapoint = OnsDatapoint.find(params[:id])
    @area = @ons_datapoint.area
    @council = @area.council if @area.is_a?(Ward)
    @datapoints = @ons_datapoint.related_datapoints
    @title = "#{@area.title} :: #{@ons_datapoint.title}"
  end

end
