ActiveRecord::Schema.define(:version => 0) do
  create_table :models, :force => true do |t|
    t.column :limited_string, :string, :limit => 5
    [:integer, :float, :date, :datetime, :time].each do |type|
      [:some, :required].each do |null|
        t.column :"#{null}_#{type}", type, :null => (null == :some)
      end
    end
  end
end
