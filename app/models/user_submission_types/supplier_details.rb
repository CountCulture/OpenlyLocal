class SupplierDetails < UserSubmissionDetails
  attr_accessor :url, :company_number
  
  def approve(submission)
    submission.item.update_supplier_details(self) rescue return false
  end
end