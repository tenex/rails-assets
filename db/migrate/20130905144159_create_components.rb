class CreateComponents < ActiveRecord::Migration
  def change
    create_table :components do |t|
      t.string :name, index: :unique
      t.text :description
      t.string :homepage

      t.timestamps
    end
  end
end
