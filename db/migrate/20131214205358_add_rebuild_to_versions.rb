class AddRebuildToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :rebuild, :boolean, default: false
  end
end
