class FinancialTransactionsController < ApplicationController
  
  def show
    @financial_transaction = FinancialTransaction.find(params[:id])
    @supplier = @financial_transaction.supplier
    @organisation = @supplier.organisation
    @title = "#{@financial_transaction.title} :: #{@organisation.title}"
    respond_to do |format|
      format.html
      format.xml { render :xml => @financial_transaction.to_xml(:include => [:supplier]) }
      format.json { render :as_json => @financial_transaction.to_xml(:include => [:supplier]) }
    end
  end
  
end
