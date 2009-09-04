class DeleteDocsWithNoInfo < ActiveRecord::Migration
  def self.up
    Document.delete_all("body LIKE '%The agenda  will be displayed%' OR body LIKE '%The agenda will be published%' ")
  end

  def self.down
  end
end
