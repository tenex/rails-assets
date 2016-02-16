class CreateDonations < ActiveRecord::Migration
  def change
    create_table :donations do |t|
      t.datetime :created_at, null: false
      t.money :amount, null: false
      t.string :email
      t.string :client_ip
    end
  end
end
