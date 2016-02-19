class DropDonations < ActiveRecord::Migration
  def change
    drop_table :donations
  end
end
