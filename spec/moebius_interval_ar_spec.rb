require File.join(File.dirname(__FILE__), 'spec_helper')

# Thanks!: 
# http://stackoverflow.com/questions/722918/testing-ruby-gems-under-rails
require 'rubygems'
require 'active_record'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :dbfile => ':memory:')

# Don't show Schema.define messages...
orig_stdout = $stdout
$stdout = File.new('NUL', 'w')

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

$stdout = orig_stdout

class Node < ActiveRecord::Base
end

require 'moebius_interval'
require 'moebius_interval_ar'
include ChinasaurLi::Acts::NestedMoebius
MoebiusInterval.instance_eval{include ChinasaurLi::Acts::NestedMoebius::MoebiusIntervalAr}

describe ChinasaurLi::Acts::NestedMoebius::MoebiusIntervalAr do
  before(:each) do
    @valid = [4913, 225, 1594, 73]
    @mi = MoebiusInterval.new(@valid)
  end
  
  it 'should add ar_class to MoebiusInterval' do
    @mi.ar_class.should be_nil
  end
  
  it 'should allow setting ar_class' do
    @mi.ar_class = Node
    @mi.ar_class.should == Node
  end
  
  it 'should only allow classes as ar_class' do
    running{@mi.ar_class = 1}.should raise_error(TypeError)
  end
  
  it 'should only allow AR::B classes as ar_class' do
    running{@mi.ar_class = Fixnum}.should raise_error(TypeError)
  end
  
  describe 'with AR class' do
    before(:each) do
      @mi.ar_class = Node
    end
    
    it 'should not allow changing ar_class' do
      running{@mi.ar_class = Node}.should raise_error
    end
    
  end
end
