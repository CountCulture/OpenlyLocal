class CharitiesController < ApplicationController
  before_filter :linked_data_available, :only => :show
  before_filter :authenticate, :except => [:show, :refresh]
  
  def show
    @charity = Charity.find(params[:id], :include => { :supplying_relationships => :organisation })
    @title = "#{@charity.title} :: Charities"
    @resource_uri = @charity.resource_uri
    respond_to do |format|
      excepts = [:email, :accounts, :financial_information, :trustees, :other_names]
      excepts += [:telephone] if @charity.date_removed?
      includes = {:except => excepts, :methods => [:openlylocal_url]}
      format.html
      format.xml { render :xml => @charity.to_xml(includes) }
      format.rdf 
      format.json { render :as_json => @charity.to_xml(includes) }
    end
  end
  
  def edit
    @charity = Charity.find(params[:id])
  end
  
  def refresh
    @charity = Charity.find(params[:id])
    @charity.delay.update_from_charity_register
    if request.xhr?
      head :ok
    else
      flash[:notice] = 'Queued charity for updating'
      redirect_to charity_url(@charity)
    end
  end
  
  def update
    @charity = Charity.find(params[:id])
    @charity.update_attributes!(params[:charity])
    @charity.update_attribute(:manually_updated, Time.now)
    flash[:notice] = "Successfully updated charity"
    redirect_to charity_url(@charity)
  rescue
    render :action => "edit"
  end
end
