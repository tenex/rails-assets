class AddPositionToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :position, :string, :limit => 1023
    add_index :versions, :position
  end
end
