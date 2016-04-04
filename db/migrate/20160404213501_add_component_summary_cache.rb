class AddComponentSummaryCache < ActiveRecord::Migration
  def change
    add_column :components, :summary_cache, :json
    Component.reset_column_information
    Component.all.each(&:touch)
  end
end
