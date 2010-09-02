class CharitiesController < ApplicationController
  
  def show
    @charity = Charity.find(params[:id], :include => { :supplying_relationships => :organisation })
    @title = "#{@charity.title} :: Charities"
    respond_to do |format|
      includes = {:except => :email, :methods => :openlylocal_url}
      format.html
      format.xml { render :xml => @charity.to_xml(includes) }
      format.rdf 
      format.json { render :as_json => @charity.to_xml(includes) }
    end
  end
end
