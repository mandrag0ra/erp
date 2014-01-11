class Sep1t9 < ActiveRecord::Migration
  def self.up    
    add_column :entities,    :activity_code, :string, :limit=>32
    add_column :entities,    :photo, :string
    add_column :companies,   :sales_conditions, :text
    add_column :departments, :sales_conditions, :text

    add_column :sale_orders, :currency_id,  :integer,  :references=>:currencies, :on_delete=>:cascade, :on_update=>:cascade
    add_column :invoices,    :currency_id,  :integer,  :references=>:invoices, :on_delete=>:cascade, :on_update=>:cascade
    add_column :deliveries,  :currency_id,  :integer,  :references=>:deliveries, :on_delete=>:cascade, :on_update=>:cascade
    
    for result in select_all("SELECT id, company_id FROM currencies WHERE code = 'EUR'")
      execute "UPDATE sale_orders SET currency_id = #{result['id']} WHERE company_id = #{result['company_id']}"
      execute "UPDATE invoices SET currency_id = #{result['id']} WHERE company_id = #{result['company_id']}"
      execute "UPDATE deliveries SET currency_id = #{result['id']} WHERE company_id = #{result['company_id']}"
    end

  end



  def self.down
    remove_column :deliveries, :currency_id
    remove_column :invoices, :currency_id
    remove_column :sale_orders, :currency_id

    remove_column :entities,    :photo
    remove_column :entities,    :activity_code
    remove_column :companies,   :sales_conditions
    remove_column :departments, :sales_conditions
  end
end