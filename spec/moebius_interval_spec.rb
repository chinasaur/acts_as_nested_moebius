require File.join(File.dirname(__FILE__), 'spec_helper')

require 'moebius_interval'
include ChinasaurLi::Acts::NestedMoebius


describe MoebiusInterval do
  
  it 'should require full integer encoding on initialization' do
    running{MoebiusInterval.new}.should            raise_error(TypeError)
    running{MoebiusInterval.new(1)}.should         raise_error(TypeError)
    running{MoebiusInterval.new(1,2,3,'a')}.should raise_error(TypeError)
    
    running{MoebiusInterval.new(1,2,3,4)}.should_not   raise_error
    running{MoebiusInterval.new([1,2,3,4])}.should_not raise_error
  end
  
end


describe MoebiusInterval do
  # See http://arxiv.org/abs/cs.DB/0402051
  before(:each) do
    @valid   = [4913, 225, 1594, 73]
    @mp = [3, 12, 5, 1, 21]
    @mps = '3.12.5.1.21'
    @mi = MoebiusInterval.new(*@valid)
  end
  
  it 'should validate determinants' do
    @mi.determinant_valid?.should                             be_true
    MoebiusInterval.new(1, 2, 3, 4).determinant_valid?.should be_false
  end
  
  it 'should be dupable' do
    @mi.should == @mi.dup
    @mi.equal?(@mi.dup).should be_false
  end
  
  it 'should calculate parent encoding' do
    @mi.parent.to_a.should == [225, 188, 73, 61]
  end
  
  it 'should give nil as parent of root node' do
    MoebiusInterval.new(3, 1, 1, 0).parent.should == nil
  end
  
  it 'should calculate next sibling' do
    @mi.next_sibling.to_a.should == [5138, 225, 1667, 73]
  end
  
  it 'should calculate prev sibling' do
    @mi.next_sibling.prev_sibling.should == @mi
  end
  
  it 'should give nil as previous sibling of 1st child' do
    MoebiusInterval.new(225, 188, 73, 61).prev_sibling.should be_nil
  end
  
  it 'should calculate child encoding given an index' do
    @mi.parent.child(21).should == @mi
  end
  
  it 'should have this interesting property' do
    next_sibling = @mi.next_sibling
    first_child  = @mi.child(1)
    [next_sibling.a, next_sibling.c].should == [first_child.a, first_child.c]
  end
  
  it 'should calculate child index of self' do
    @mi.child_index.should == 21
  end
  
  it 'should check child/parent relationships' do
    @mi.child(1).child_of?(@mi).should be_true
    @mi.child(rand(100)+1).child_of?(@mi).should be_true
    @mi.parent.parent_of?(@mi).should be_true
  end
  
  it 'should not count a grandchild as a child' do
    @mi.child(rand(100)+1).child(rand(100)).child_of?(@mi).should be_false
  end
  
  it 'should count a grandchild as a descendent' do
    @mi.child(rand(100)+1).child(rand(100)+1).descendent_of?(@mi).should be_true
  end
  
  it 'should count a child as a descendent' do
    @mi.child(rand(100)+1).descendent_of?(@mi).should be_true
  end
  
  it 'should count first child as descendent due to semi-open interval' do
    @mi.child(1).descendent_of?(@mi).should be_true
  end
  
  it 'should count descendents correctly even though interval reverses at each level' do
    @mi.child(1).descendent_of?(@mi).should be_true
    @mi.child(1).child(1).descendent_of?(@mi.child(1)).should be_true
  end
  
  it 'should handle funny edge case of first child versus next sibling correctly' do
    @mi.next_sibling.descendent_of?(@mi).should be_false
  end
  
  it 'should count parent and grandparent as ancestors' do
    @mi.parent.ancestor_of?(@mi).should        be_true
    @mi.parent.parent.ancestor_of?(@mi).should be_true
  end
  
  it 'should be able to check validity of child index' do
    @mi.child_index_valid?.should                             be_true
    MoebiusInterval.new(1, 2, 3, 4).child_index_valid?.should be_false
  end
  
  it 'should be able to derive materialized path' do
    @mi.materialized_path.should == @mp
  end
  
  it 'should be able to build MI from materialized path' do
    MoebiusInterval.from_materialized_path(@mi.materialized_path).should == @mi
  end
  
  it 'should be able to build MI from materialized path string' do
    MoebiusInterval.new(@mps).should == @mi
  end
  
  it 'should do double check of descendent checking using mp' do
    MoebiusInterval.new('3.2.45.10').descendent_of?(MoebiusInterval.new('3.2')).should be_true
    MoebiusInterval.new('3.2.45.10.3').descendent_of?(MoebiusInterval.new('3.2.45')).should be_true
    
    MoebiusInterval.new('3.2.45.10').descendent_of?(MoebiusInterval.new('3.3')).should be_false
  end
  
end

describe MoebiusInterval do
  before(:each) do
    @valid   = [4913, 225, 1594, 73]
    @mi = MoebiusInterval.new(@valid)
    @mi2 = MoebiusInterval.new(2, 1, 1, 0)
  end
  
end
