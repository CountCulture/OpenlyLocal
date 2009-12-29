class OnsDatapointsController < ApplicationController
  helper :wards
  
  def index
    @ons_dataset_topic = OnsDatasetTopic.find(params[:ons_dataset_topic_id])
    # @ons_dataset_topic.ons_datapoints.limited_to(params.only(:group, :group_id))
  end
  
  def show
    @ons_datapoint = OnsDatapoint.find(params[:id])
    @area = @ons_datapoint.area
    @council = @area.council if @area.is_a?(Ward)
    @datapoints = @ons_datapoint.related_datapoints
    @title = "#{@area.title} :: #{@ons_datapoint.title}"
    @table_caption = "Comparison against other " + (@area.is_a?(Ward) ? "wards in #{@council.name}" : "#{@area.authority_type} Councils")
  end

end
