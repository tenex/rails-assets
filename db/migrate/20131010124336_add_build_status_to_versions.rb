class AddBuildStatusToVersions < ActiveRecord::Migration
  def up
    add_column :versions, :build_status, :string
    add_column :versions, :build_message, :text

    Version.update_all("build_status = 'built'")
  end
end
