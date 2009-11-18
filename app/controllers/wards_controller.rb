class WardsController < ApplicationController
  before_filter :authenticate, :except => [:show]
  before_filter :linked_data_available, :only => :show
  
  def show
    @ward = Ward.find(params[:id])
    @council = @ward.council
    @members = @ward.members
    @committees = @ward.committees
    @title = "#{@ward.name} ward"
    respond_to do |format|
      format.html
      format.xml { render :xml => @ward.to_xml(:include => [:members, :committees, :meetings]) }
      format.rdf 
      format.json { render :json => @ward.to_json(:include => [:members, :committees, :meetings]) }
    end
  end
  
  def edit
    @ward = Ward.find(params[:id])
  end
  
  def update
    @ward = Ward.find(params[:id])
    @ward.update_attributes!(params[:ward])
    flash[:notice] = "Successfully updated ward"
    redirect_to ward_url(@ward)
  end
  
  def destroy
    @ward = Ward.find(params[:id])
    @council = @ward.council
    @ward.destroy
    flash[:notice] = "Successfully destroyed ward"
    redirect_to council_url(@council)
  end
end
