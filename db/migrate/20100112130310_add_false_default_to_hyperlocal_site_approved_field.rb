class AddFalseDefaultToHyperlocalSiteApprovedField < ActiveRecord::Migration
  def self.up
    change_column_default :hyperlocal_sites, :approved, false
    HyperlocalSite.update_all('approved = 0', 'approved IS NULL')
  end

  def self.down
    change_column_default :hyperlocal_sites, :approved, nil
  end
end
