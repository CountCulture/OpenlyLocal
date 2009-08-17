class RenameMemberDeclarationOfInterests < ActiveRecord::Migration
  def self.up
    rename_column :members, :declaration_of_interests, :register_of_interests
  end

  def self.down
    rename_column :members, :register_of_interests, :declaration_of_interests
  end
end
