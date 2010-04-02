class AreasController < ApplicationController
  def search
    unless @postcode = Postcode.find_from_messy_code(params[:postcode])
      render :text => "<p class='alert'>Couldn't find postcode</p>" and return
    end
    @council = @postcode.council
    @county = @postcode.county
    @ward = @postcode.ward
    @members = @ward&&@ward.members
    @title = "Local information for #{@postcode.pretty_code}"
  end
end
