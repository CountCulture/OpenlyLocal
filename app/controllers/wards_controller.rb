class WardsController < ApplicationController
  before_filter :authenticate, :except => [:show]
  before_filter :find_ward
  before_filter :linked_data_available, :only => :show
  helper :datapoints
  caches_action :show
  
  def show
    @council = @ward.council
    @members = @ward.members.current
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
  end
  
  def update
    @ward.update_attributes!(params[:ward])
    flash[:notice] = "Successfully updated ward"
    redirect_to ward_url(@ward)
  end
  
  def destroy
    @council = @ward.council
    @ward.destroy
    flash[:notice] = "Successfully destroyed ward"
    redirect_to council_url(@council)
  end
  
  private
  def find_ward
    @ward = params[:id] ? Ward.find(params[:id]) : Ward.find_by_snac_id(params[:snac_id])
  end
end
