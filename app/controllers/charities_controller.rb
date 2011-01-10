class CharitiesController < ApplicationController
  before_filter :linked_data_available, :only => :show
  
  def show
    @charity = Charity.find(params[:id], :include => { :supplying_relationships => :organisation })
    @title = "#{@charity.title} :: Charities"
    @resource_uri = @charity.resource_uri
    respond_to do |format|
      includes = {:except => [:email, :accounts, :financial_information, :trustees, :other_names], :methods => [:openlylocal_url]}
      format.html
      format.xml { render :xml => @charity.to_xml(includes) }
      format.rdf 
      format.json { render :as_json => @charity.to_xml(includes) }
    end
  end
end
