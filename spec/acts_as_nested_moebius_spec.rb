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
    t.integer :parent_id
    
    t.integer :column_a
  end
end

$stdout = orig_stdout

class Node < ActiveRecord::Base
end

describe 'Testing data setup' do
  it 'should have a Node class with valid table' do
    Node.column_names.include?('nm_a').should be_true
  end
end



require 'init'
include ChinasaurLi::Acts::NestedMoebius

describe ChinasaurLi::Acts::NestedMoebius do
  it 'should add itself to AR::B' do
    Node.respond_to?(:acts_as_nested_moebius).should be_true
  end
end

Node.acts_as_nested_moebius
describe ChinasaurLi::Acts::NestedMoebius do
  
  it 'should have default options' do
    Node.acts_as_nested_moebius_options.should == ChinasaurLi::Acts::NestedMoebius::ClassMethods::DEFAULT_OPTIONS
  end
  
  describe 'instances' do
    before(:each) do
      @n = Node.new
      @valid_mi = [4913, 225, 1594, 73]
      @mp = [3, 12, 5, 1, 21]
    end
    
    it 'should have access to options' do
      @n.acts_as_nested_moebius_options.should == ChinasaurLi::Acts::NestedMoebius::ClassMethods::DEFAULT_OPTIONS
    end
    
    it 'should return nil for MI if no data' do
      @n.moebius_interval.should be_nil
    end
    
    it 'should calculate MI from columns if possible' do
      @n.attributes = {:nm_a => 4913, :nm_b => 225, :nm_c => 1594, :nm_d => 73}
      @n.moebius_interval.to_a.should == @valid_mi
    end
    
    it 'should be able to set MI directly' do
      @n.moebius_interval = MoebiusInterval.new(@valid_mi)
      @n.moebius_interval.to_a.should == @valid_mi
    end
    
    it 'should be able to set MI with a valid array' do
      @n.moebius_interval = @valid_mi
      @n.moebius_interval.should == MoebiusInterval.new(@valid_mi)
    end
    
    it 'should be able to set MI with splat too' do
      @n.moebius_interval = *@valid_mi
      @n.moebius_interval.should == MoebiusInterval.new(@valid_mi)
    end
    
    it 'should complain on invalid MI setting' do
      running{@n.moebius_interval = 1}.should raise_error(ArgumentError)
      running{@n.moebius_interval = 1, 2}.should raise_error(ArgumentError)
      running{@n.moebius_interval = '1'}.should raise_error(ArgumentError)
    end
    
    it 'should set a, b, c, d when setting MI' do
      @n.moebius_interval = @valid_mi
      opts = @n.acts_as_nested_moebius_options
      [ @n[opts[:a]], @n[opts[:b]], @n[opts[:c]], @n[opts[:d]] ].should == @valid_mi
    end
    
    it 'should calculate materialized path' do
      @n.moebius_interval = @valid_mi
      @n.materialized_path.should == @mp
    end
    
    it 'should be able to set MI from MP' do
      @n.materialized_path = @mp
      @n.moebius_interval.to_a.should == @valid_mi
    end
    
    it 'should be able to set MI from MP string' do
      @n.materialized_path = (@mp * '.')
      @n.moebius_interval.to_a.should == @valid_mi
    end
    
    it 'should be able to set MI from MP string with custom delimiter' do
      @n.materialized_path = (@mp * '|'), '|'
      @n.moebius_interval.to_a.should == @valid_mi
    end
    
    it 'should complain on invalid MP string' do
      running{@n.materialized_path = 'asdf'}.should raise_error(TypeError)
    end
    
    describe 'second instance' do
      before(:each) do
        @n2 = Node.new
      end
      
      # Better way to test this would probably be with a stubbed MI...
      it 'should delegate relation checking to MIs' do
        @n.moebius_interval  = @valid_mi
        @n2.moebius_interval = @n.moebius_interval.parent
        @n2.parent_of?(@n).should  be_true
        @n.child_of?(@n2).should   be_true
        @n.sibling_of?(@n2).should be_false
      end
      
      it 'should raise error on relation checking is passed the wrong type or if either MI is not defined' do
        running{@n.parent_of?(@n2)}.should raise_error(ArgumentError)
      end
    end
    
  end
  
end


describe ChinasaurLi::Acts::NestedMoebius, 'with user specified options' do
  before(:each) do
    @opts = {:a => 'column_a', :mprefix => 'nm_'}
    Node.acts_as_nested_moebius(@opts)
    # Note, this is not actually independent from the acts_as_nested_moebius declaration on Node above.
    # So now Node actually has both child_of? and nm_child_of? defined, for example.
    # This is okay for most of the tests.
  end
  
  it 'should get options into class' do
    Node.acts_as_nested_moebius_options.should == ChinasaurLi::Acts::NestedMoebius::ClassMethods::DEFAULT_OPTIONS.merge(@opts)
  end
  
  describe 'instances' do
    before(:each) do
      @n = Node.new
    end
    
    it 'should use the user specified columns' do
      @n.attributes = {:column_a => 4913, :nm_a => 0, :nm_b => 225, :nm_c => 1594, :nm_d => 73}
      @n.moebius_interval.to_a.should == [4913, 225, 1594, 73]
    end
    
    it 'should have methods defined according to the user specified method prefix' do
      @n.respond_to?(:nm_child_of?).should be_true
    end
  end
end
