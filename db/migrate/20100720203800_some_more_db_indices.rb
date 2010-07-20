class SomeMoreDbIndices < ActiveRecord::Migration
  def self.up

    add_index :parsers, [:id, :type]
    add_index :investigations, [:related_organisation_id, :related_organisation_type], :name => "index_investigations_on_related_organisation"
    add_index :spending_stats, [:organisation_id, :organisation_type], :name => "index_spending_stats_on_organisation"
    add_index :investigation_subject_connections, :investigation_id
    add_index :investigation_subject_connections, [:subject_id, :subject_type], :name => "index_investigation_subject_connections_on_subject"
    add_index :user_submissions, [:item_id, :item_type]
    add_index :suppliers, [:payee_id, :payee_type]
  end

  def self.down
    remove_index :parsers, :column => [:id, :type]
    remove_index :investigations, :column => [:related_organisation_id, :related_organisation_type], :name => "index_investigations_on_related_organisation"
    remove_index :spending_stats, :column => [:organisation_id, :organisation_type], :name => "index_spending_stats_on_organisation"
    remove_index :investigation_subject_connections, :investigation_id
    remove_index :investigation_subject_connections, :column => [:subject_id, :subject_type], :name => "index_investigation_subject_connections_on_subject"
    remove_index :user_submissions, :column => [:item_id, :item_type]
    remove_index :suppliers, :column => [:payee_id, :payee_type]
  end
end
