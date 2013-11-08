class AddBowerNameToComponents < ActiveRecord::Migration
  def change
    add_column :components, :bower_name, :string
  end
end
