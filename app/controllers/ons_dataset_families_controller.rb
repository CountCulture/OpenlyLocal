class OnsDatasetFamiliesController < ApplicationController
  def index
    @ons_subjects = OnsSubject.all(:include => [:ons_dataset_families])
  end

  def show
    @ons_dataset_family = OnsDatasetFamily.find(params[:id])
    @title = @ons_dataset_family.title
  end

end
