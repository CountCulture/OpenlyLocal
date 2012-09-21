class PensionFundsController < ApplicationController
  before_filter :authenticate, :except => [:index, :show]
  before_filter :find_pension_fund, :except => :index
  
  def index
    @pension_funds = PensionFund.all
    @title = 'Local Authority Pension Funds'
    respond_to do |format|
      format.html
      format.xml { render :xml => @pension_funds.to_xml }
      format.json { render :json => @pension_funds.to_json }
    end
  end
  
  def show
    @title = @pension_fund.name
  end
  
  def edit
  end
  
  def update
    if @pension_fund.update_attributes(params[:pension_fund])
      flash[:notice] = "Successfully updated pension fund"
      redirect_to pension_fund_url(@pension_fund)
    else
      render :action => 'edit'
    end
  end

  private
  def find_pension_fund
    @pension_fund = PensionFund.find(params[:id])
  end
end
