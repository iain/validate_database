begin
  require File.dirname(__FILE__) + '/../../../../spec/spec_helper'
rescue LoadError
  puts "You need to install rspec in your base app"
  exit
end

plugin_spec_dir = File.dirname(__FILE__)
ActiveRecord::Base.logger = Logger.new(plugin_spec_dir + "/debug.log")

databases = YAML::load(IO.read(plugin_spec_dir + "/db/database.yml"))
ActiveRecord::Base.establish_connection(databases[ENV["DB"] || "sqlite3"])
load(File.join(plugin_spec_dir, "db", "schema.rb"))

class Model < ActiveRecord::Base
  validates_according_to_database :all
end

Types = [ :integer, :float, :date, :time, :datetime ]
Nulls = [ :required, :some ]
Value = { 
  :integer => 3213, 
  :float => 323.12, 
  :date => Date.today, 
  :time => Time.now.to_time, 
  :datetime => Time.now
}
ValueValid = lambda do |type, null| 
  hash = { Value[type] => :valid, "foo" => :invalid }
  hash.merge!(nil => :invalid) if null == :required
  hash.merge!(nil => :valid) if null == :some
  hash
end
Might = { :valid => "should", :invalid => "should_not" }
HaveError = { :valid => [:have_at_most,0], :invalid => [:have_at_least, 1] }
R = { :required => "a required", :some => "some" }
C = lambda { |type, null| :"#{null}_#{type}" }
It = lambda do |attrs|
  defaults = {:limited_string => "aaa"}
  Types.each { |t| Nulls.each { |n| defaults.merge!(C[t, n] => Value[t]) } }
  Model.new(defaults.merge(attrs))
end
