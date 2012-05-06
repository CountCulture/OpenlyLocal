class CompaniesController < ApplicationController
  before_filter :linked_data_available, :only => :show
  before_filter :find_company

  def show
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
  
  private
  def find_company
    if params[:company_number]
      @company = Company.find_by_company_number(params[:company_number], :include => { :supplying_relationships => [:organisation, :spending_stat] })
    else
      @company = Company.find(params[:id], :include => { :supplying_relationships => [:organisation, :spending_stat] })
    end
  end
end
