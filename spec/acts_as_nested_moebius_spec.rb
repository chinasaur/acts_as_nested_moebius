require File.join(File.dirname(__FILE__), 'spec_helper')

# Thanks!: 
# http://stackoverflow.com/questions/722918/testing-ruby-gems-under-rails
require 'rubygems'
require 'active_record'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :dbfile => ':memory:')

ActiveRecord::Schema.define(:version => 1) do
  create_table :nodes do |t|
    t.string :name
  end
end

class Node < ActiveRecord::Base
end
