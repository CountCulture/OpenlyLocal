class MembersController < ApplicationController
  
  def show
    @member = Member.find(params[:id])
  end
end
