ActiveAdmin.register Component do
  index do
    column :id do |c|
      link_to c.id, admin_component_path(c)
    end
    column :name do |c|
      link_to c.name, admin_component_path(c)
    end
    column :description
    column :homepage
    column :versions do |c|
      ul do
        c.versions.map do |v|
          li do
            link_to v.string, admin_version_path(v)
          end
        end
      end
    end
    column :created_at
    column :updated_at
  end

  filter :name
  filter :homepage
  filter :created_at
  filter :updated_at
end
