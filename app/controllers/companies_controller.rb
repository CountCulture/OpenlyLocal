class CompaniesController < ApplicationController
  
  def show
    @company = Company.find(params[:id], :include => { :suppliers => :organisation })
    @title = "#{@company.title} :: Companies"
    respond_to do |format|
      format.html
      format.xml { render :xml => @company.to_xml(:include => { :suppliers => { :include => :organisation }}) }
      format.json { render :as_json => @company.to_xml(:include => { :suppliers => { :include => :organisation }}) }
    end
  end
end
