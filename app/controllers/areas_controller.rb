class AreasController < ApplicationController
  def search
    unless !params[:postcode].blank? && @postcode = Postcode.find_from_messy_code(params[:postcode])
      render :text => "<p class='alert'>Couldn't find postcode</p>", :layout => true and return
    end
    @council = @postcode.council
    @county = @postcode.county
    @ward = @postcode.ward
    @latitude = @postcode.lat
    @longitude = @postcode.lng
    @members = @ward&&@ward.members.current
    @title = "Local information for #{@postcode.pretty_code}"
    respond_to do |format|
      format.html
      format.xml { render :xml => @postcode.to_xml(:include => { :ward => { :include => [:members, :council, :committees] }, :crime_area => {} }) }
      # format.rdf 
      format.json { render :json => @postcode.to_json(:include => { :ward => { :include => [:members, :council, :committees] }, :crime_area => {} }) }
    end
  end
end
