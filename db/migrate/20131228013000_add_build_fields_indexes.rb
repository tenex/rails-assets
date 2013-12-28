class AddBuildFieldsIndexes < ActiveRecord::Migration
  def change
    add_index :versions, :build_status
    add_index :versions, :rebuild
  end
end
