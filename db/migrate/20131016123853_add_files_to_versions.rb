class AddFilesToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :asset_paths, :text, array: true, default: []
    add_column :versions, :main_paths, :text, array: true, default: []
  end
end
