class AreasController < ApplicationController
  def show
    @postcode = Postcode.find_by_code(params[:postcode].sub(/\s/,'').upcase)
    @council = @postcode.council
    @county = @postcode.county
    @ward = @postcode.ward
    @members = @ward&&@ward.members
    @title = "Local information for #{@postcode.pretty_code}"
  end
end
