class CreateFailedJobs < ActiveRecord::Migration
  def change
    create_table :failed_jobs do |t|
      t.string :name
      t.string :worker
      t.text :args
      t.text :message

      t.timestamps
    end
    add_index :failed_jobs, :name
  end
end
