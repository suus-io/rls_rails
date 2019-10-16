ActiveRecord::Schema.define(:version => 0) do
  create_table :tenants, :force => true do |t|
    t.string :name
  end

  create_table :users, :force => true do |t|
    t.string :name
  end
end