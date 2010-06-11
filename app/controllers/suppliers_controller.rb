class SuppliersController < ApplicationController
  
  def show
    @supplier = Supplier.find(params[:id])
    @organisation = @supplier.organisation
    @title = @supplier.title
    respond_to do |format|
      format.html
      format.xml { render :xml => @supplier.to_xml }
      format.json { render :as_json => @supplier.to_xml }
      # format.rss { render :layout => false }
    end
    
  end
end
