class PensionFundsController < ApplicationController
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
    @pension_fund = PensionFund.find(params[:id])
    @title = @pension_fund.name
  end
end
