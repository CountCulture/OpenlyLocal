class OnsDatasetsController < ApplicationController
  def index
    @ons_datasets_families = OnsDatasetFamily.all(:include => [:ons_subjects, :ons_datasets])
  end
  
  def show
    @ons_dataset = OnsDataset.find(params[:id])
    @title = @ons_dataset.extended_title
  end
  
end
