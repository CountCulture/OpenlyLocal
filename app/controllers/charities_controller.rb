class CharitiesController < ApplicationController
  before_filter :linked_data_available, :only => :show
  before_filter :authenticate, :except => :show
  
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
  
  def update
    @charity = Charity.find(params[:id])
    if params[:commit] == 'Update from CC website'
      @charity.update_from_charity_register
      flash[:notice] = "Successfully updated charity from Charity Commission website"
    else
      @charity.update_attributes!(params[:charity])
      @charity.update_attribute(:manually_updated, Time.now)
      flash[:notice] = "Successfully updated charity"
    end
    redirect_to charity_url(@charity)
  rescue
    render :action => "edit"
  end
end
