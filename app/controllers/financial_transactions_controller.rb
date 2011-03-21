class FinancialTransactionsController < ApplicationController
  def index
    page = (params[:page]||1).to_i
    page = 50 if page > 50
    @organisation = params[:organisation_type].constantize.find(params[:organisation_id]) if params[:organisation_type] && params[:organisation_id]
    @title = (@organisation ? "#{@organisation.title} " : "") + "Transactions :: Spending Data :: Page #{page}"
    @financial_transactions = @organisation ? @organisation.payments.paginate(:page => page, :order => 'value DESC') : 
                                              FinancialTransaction.paginate(:page => page, :order => 'value DESC')
    respond_to do |format|
      format.html
      format.xml do
        render :xml => @financial_transactions.to_xml(:include => [:supplier]) { |xml|
                    xml.tag! 'total-entries', @financial_transactions.total_entries
                    xml.tag! 'per-page', @financial_transactions.per_page
                    xml.tag! 'page', page
                  }
      end
      format.json do
        render :json => { :page => page,
                          :per_page => @financial_transactions.per_page,
                          :total_entries => @financial_transactions.total_entries,
                          :financial_transactions => @financial_transactions.to_json(:include => [:supplier])
                        }
      end
    end
  end
  
  def show
    @financial_transaction = FinancialTransaction.find(params[:id])
    @related_transactions = @financial_transaction.related
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
