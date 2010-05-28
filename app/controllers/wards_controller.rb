class WardsController < ApplicationController
  before_filter :authenticate, :except => [:show, :index]
  before_filter :find_ward, :except => [:index]
  before_filter :linked_data_available, :only => :show
  helper :datapoints
  caches_action :show
  
  def index
    @council = Council.find(params[:council_id]) if params[:council_id]
    @wards = @council ? @council.wards.current : Ward.restrict_to_oac(params).current.paginate(:page => params[:page], :include => :council)
    @title = "Current Wards"
    @title += " :: Page #{(params[:page]||1).to_i}" unless @council
  end
  
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
    @ward = 
    case 
    when params[:snac_id]
      Ward.find_by_snac_id(params[:snac_id])
    when params[:os_id]
      Ward.find_by_os_id(params[:os_id])
    else
      Ward.find(params[:id])
    end
  end
end
