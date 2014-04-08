class LinkTables < ActiveRecord::Migration
  def change
    add_reference :analysis_items, :product_reading
    add_reference :interventions, :event
    add_reference :intervention_casts, :event_participation
    add_reference :products, :person

    add_column :events, :nature, :string
    execute "UPDATE events SET nature='meeting'"
    change_column_null :events, :nature, false
    remove_column :events, :nature_id
    drop_table :event_natures
  end

  # def down
 
  #   create_table :event_natures do |t|
  #     t.string   :name,                                   null: false
  #     t.string   :usage,        limit: 60
  #     t.boolean  :active,                  default: true, null: false
  #     t.stamps
  #     t.index    :name
  #   end
   
  # end

end
