# Make startup quiet...
orig_stdout = $stdout
$stdout = File.new('NUL', 'w')

require 'rubygems'
require 'active_record'

$: << File.join(File.dirname(__FILE__), '..', 'lib')
require 'acts_as_nested_moebius'
include ChinasaurLi::Acts::NestedMoebius

class ActiveRecord::Base
  include ChinasaurLi::Acts::NestedMoebius
end

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :dbfile => ':memory:')

ActiveRecord::Schema.define(:version => 1) do
  create_table :nodes do |t|
    t.string  :name
    
    t.integer :nm_a
    t.integer :nm_b
    t.integer :nm_c
    t.integer :nm_d
    t.integer :nm_parent_id
    
    t.integer :column_a
  end
end

class Node < ActiveRecord::Base
  acts_as_nested_moebius
end

$stdout = orig_stdout
