class AddBuildStatusToVersions < ActiveRecord::Migration
  def up
    add_column :versions, :build_status, :string
    add_column :versions, :build_message, :text

    execute "UPDATE versions SET build_status='built'"
  end
end
