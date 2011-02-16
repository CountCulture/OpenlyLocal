class CompaniesController < ApplicationController
  before_filter :linked_data_available, :only => :show

  def show
    @company = Company.find(params[:id], :include => { :supplying_relationships => :organisation })
    @title = "#{@company.title} :: Companies"
    @resource_uri = @company.resource_uri
    respond_to do |format|
      format.html
      format.xml { render :xml => @company.to_xml(:include => { :supplying_relationships => { :include => :organisation }}) }
      format.json { render :as_json => @company.to_xml(:include => { :supplying_relationships => { :include => :organisation }}) }
      format.rdf 
    end
  end
  
  def spending
    @title = "Companies supplying Councils"
    @council_spending_data = Council.cached_spending_data
    # @biggest_companies = Company.all(:limit => 10, :joins => :spending_stat, :order => 'spending_stats.total_spend DESC')
  end
end
