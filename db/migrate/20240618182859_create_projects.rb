class CreateProjects < ActiveRecord::Migration[7.0]
  def change
    create_table :projects do |t|
      t.string :org, null: false
      t.string :name, null: false
      t.timestamps
    end

    create_table :project_gems do |t|
      t.string :org, null: false
      t.string :name, null: false

      t.references :project
      t.timestamps
    end
  end
end
