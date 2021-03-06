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
    @mi.ar_object.should be_nil
  end
  
  it 'should allow setting ar_object' do
    n = Node.new
    @mi.ar_object = n
    @mi.ar_object.should == n
  end
  
  it 'should only allow AR::B objects as ar_object' do
    running{@mi.ar_object = 1}.should raise_error(TypeError)
  end
  
  describe 'with AR object' do
    before(:each) do
      @mi.ar_object = Node.new
    end
    
    it 'should not allow changing ar_object' do
      running{@mi.ar_object = Node.new}.should raise_error(SecurityError)
    end
  end
end

require 'acts_as_nested_moebius'
ActiveRecord::Base.class_eval{include ChinasaurLi::Acts::NestedMoebius}
class Node
  acts_as_nested_moebius
  def <=>(other)
    raise unless other.is_a?(Node)
    moebius_interval <=> other.moebius_interval
  end
end

describe 'with basic network' do
  before(:each) do
    @valid = [4913, 225, 1594, 73]
    @mi   = MoebiusInterval.new(@valid)
    @mic  = @mi.child(1)
    @mic2 = @mi.child(2)
    @migc = @mic.child(1)
    @mip  = @mi.parent
    @mins = @mi.next_sibling
    @n   = Node.new(:moebius_interval => @mi,   :name => @mi.materialized_path.join('.'))
    @nc  = Node.new(:moebius_interval => @mic,  :name => @mic.materialized_path.join('.'))
    @nc2 = Node.new(:moebius_interval => @mic2, :name => @mic2.materialized_path.join('.'))
    @ngc = Node.new(:moebius_interval => @migc, :name => @migc.materialized_path.join('.'))
    @np  = Node.new(:moebius_interval => @mip,  :name => @mip.materialized_path.join('.'))
    @nns = Node.new(:moebius_interval => @mins, :name => @mins.materialized_path.join('.'))
    @n.save!
    @nc.save!
    @nc2.save!
    @ngc.save!
    @np.save!
    @nns.save!
  end
  
  after(:each) do
    Node.delete_all
  end
  
  it 'should get access to parent_id from ar_object' do
    @n.parent_id = 101
    @mi.parent_id.should == 101
  end
  
  it 'should find descendents via SQL query on ar_object' do
    @mi.find_descendents.sort.should == [@nc, @nc2, @ngc].sort
    @mic.find_descendents.should == [@ngc]
    @mip.find_descendents.sort.should == [@n, @nns, @nc, @nc2, @ngc].sort
    @mins.find_descendents.should == []
  end
  
  it 'should find ancestors via SQL query on ar_object' do
    @mi.find_ancestors.should == [@np]
    @mic2.find_ancestors.sort.should == [@np, @n].sort
  end
  
  it 'should return ancestors in reverse-age order' do
    @migc.find_ancestors.should == [@nc, @n, @np]
  end
  
  it 'should be able to override order' do
    @migc.find_ancestors(:order => 'id').should == [@n, @nc, @np]
  end
  
  it 'should find siblings (including self) via SQL query on ar_object' do
    @mi.find_siblings.sort.should == [@n, @nns].sort
    @mic.find_siblings.sort.should == [@nc, @nc2].sort
  end
  
  it 'should return siblings in child index order' do
    @mi.find_siblings.should == [@n, @nns]
    @mic.find_siblings.should == [@nc, @nc2]
  end
  
  it 'should be able to override order' do
    @mi.find_siblings(:order => 'nm_a DESC').should == [@nns, @n]
  end
  
  it 'should be able to move a node with its descendent subtree' do
    @mi.move_to('2.2')
    @n.moebius_interval(reload=true).materialized_path.should == [2, 2]
    @nc.reload
    @nc2.reload
    @ngc.reload
    @nc.moebius_interval(reload=true).materialized_path.should == [2, 2, 1]
    @nc2.moebius_interval(reload=true).materialized_path.should == [2, 2, 2]
    @ngc.moebius_interval(reload=true).materialized_path.should == [2, 2, 1, 1]
  end
  
end
