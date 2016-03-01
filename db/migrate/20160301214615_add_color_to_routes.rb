class AddColorToRoutes < ActiveRecord::Migration
  def change
    add_column :current_routes, :color, :string, default: 'FFFFFF'
    add_column :old_routes, :color, :string
  end
end
