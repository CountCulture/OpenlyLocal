class WardsController < ApplicationController
  
  def show
    @ward = Ward.find(params[:id])
    @council = @ward.council
    @members = @ward.members
    @title = "#{@ward.name} ward"
    respond_to do |format|
      format.html
      format.xml { render :xml => @ward.to_xml(:include => :members) }
      format.json { render :json => @ward.to_json(:include => :members) }
    end
  end
end
