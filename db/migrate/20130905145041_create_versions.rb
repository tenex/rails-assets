class CreateVersions < ActiveRecord::Migration
  def change
    create_table :versions do |t|
      t.references :component, index: true
      t.string :string, index: true
      t.hstore :dependencies

      t.timestamps
    end
  end
end
