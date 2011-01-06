class CompaniesController < ApplicationController
  before_filter :linked_data_available, :only => :show

  def show
    @company = Company.find(params[:id], :include => { :supplying_relationships => :organisation })
    @title = "#{@company.title} :: Companies"
    respond_to do |format|
      format.html
      format.xml { render :xml => @company.to_xml(:include => { :supplying_relationships => { :include => :organisation }}) }
      format.json { render :as_json => @company.to_xml(:include => { :supplying_relationships => { :include => :organisation }}) }
      format.rdf 
    end
  end
end
