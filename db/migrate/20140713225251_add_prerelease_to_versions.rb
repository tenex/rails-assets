class AddPrereleaseToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :prerelease, :boolean, default: false
    add_index :versions, :prerelease
  end
end
