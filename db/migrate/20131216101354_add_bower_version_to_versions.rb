class AddBowerVersionToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :bower_version, :string
    add_index :versions, :bower_version
  end
end
