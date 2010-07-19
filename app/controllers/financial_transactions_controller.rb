class FinancialTransactionsController < ApplicationController
  def index
    @title = "Transactions :: Local Spending :: Page #{(params[:page]||1).to_i}"
    @financial_transactions = FinancialTransaction.paginate(:page => params[:page], :order => 'value DESC')
    respond_to do |format|
      format.html
      format.xml do
        render :xml => @financial_transactions.to_xml(:include => [:supplier]) { |xml|
                    xml.tag! 'total-entries', @financial_transactions.total_entries
                    xml.tag! 'per-page', @financial_transactions.per_page
                    xml.tag! 'page', (params[:page]||1).to_i
                  }
      end
      format.json do
        render :json => { :page => (params[:page]||1).to_i,
                          :per_page => @financial_transactions.per_page,
                          :total_entries => @financial_transactions.total_entries,
                          :financial_transactions => @financial_transactions.to_json(:include => [:supplier])
                        }
      end
    end
  end
  
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
