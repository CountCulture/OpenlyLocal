class DocumentsController < ApplicationController
  def show
    @document = Document.find(params[:id])
    @council = @document.document_owner.council
    @title = "#{@document.document_type} for #{@document.document_owner.extended_title}"
  end

end
