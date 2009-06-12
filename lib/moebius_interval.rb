module ChinasaurLi
  module Acts
    module NestedMoebius
      
      # Basically just a 4 element array that behaves like 2x2 matrix:
      #   | self[0] self[1] | = | a b |
      #   | self[2] self[3] |   | c d |
      class MoebiusInterval
        
        def initialize(*args)
          if (args.size == 1 or args.size == 2) and args.all?{|arg|arg.is_a?(String)}
            path = klass.string_to_path(*args)
            @encoding = klass.mi_array_from_materialized_path(path)
          else
            args.flatten!
            raise TypeError unless mi_array?(args)
            @encoding = args
          end
        end
        
        def a; @encoding[0]; end
        def b; @encoding[1]; end
        def c; @encoding[2]; end
        def d; @encoding[3]; end
        
        def determinant_valid?
          determinant.abs == 1
        end
        
        def determinant
          a*d - b*c
        end
        
        # Simple 2x2 matrix inversion
        def inverse
          det = determinant
          [d/det, -b/det, -c/det, a/det]
        end
        
        def to_a
          @encoding
        end
        
        def dup
          new(*@encoding)
        end
        
        def ==(other)
          other.is_a?(klass) and to_a == other.to_a
        end
        
        # This is tricky and important.  <, >, <=, >= all work only on the
        # rational encoding of the MI, which takes only mi.a and mi.c and treats
        # them as rational number a/c.
        # I defined these comparisons using cross multiplication rather than
        # division to avoid generating floats
        def <(other); a*other.c < other.a*c; end
        def >(other); a*other.c > other.a*c; end
        def <=(other); a*other.c <= other.a*c; end
        def >=(other); a*other.c >= other.a*c; end
        
        # These are some nasty special cases that have to be handled carefully!
        def root?
          to_a == [a, 1, 1, 0]
        end
        
        def path_x_1?
          to_a == [a, a-1, 1, 1]
        end
        
        def path_1_x?
          to_a == [a, 1, a-1, 1]
        end
        
        def path_x_1_x?
          to_a == [a, b, child_index+1, 1]
        end
        
        def parent
          return nil               if root?
          return new(b, 1, 1, 0)   if path_x_1? or path_1_x? # Nasty special cases
          return new(b, b-1, 1, 1) if path_x_1_x?            # Nasty special case
          new(b, a%b, d, c%d)
        end
        
        # indexes begin at 1, not 0
        # Could use klass.mmult and klass.mi_array_from_path_fragment,
        # but this is a bit more direct.
        def child(index)
          index = index.to_i
          raise ArgumentError unless index > 0
          new(b + a*index, a, d + c*index, c)
        end
        
        def children(indexes)
          indexes.collect do |index|
            child(index)
          end
        end
        
        def next_sibling
          new(a+b, b, c+d, d)
        end
        
        def prev_sibling
          return nil if child_index == 1
          new([a-b, b, c-d, d])
        end
        
        # This does not guarantee that self is valid, so should check
        # self.child_index_valid?() first if this is important.
        def child_index
          return c if path_x_1? or path_1_x? # Nasty special cases
          a / b
        end
        
        def child_index_valid?
          return true if root?
          
          pa, pb, pc, pd = parent.to_a
          i1 = (a-pb) / pa
          i2 = (c-pd) / pc
          
          i1.is_a?(Integer) and i1 > 0 and i1 == i2
        end
        
        def materialized_path
          mp = [child_index]
          mi = self
          while mi = mi.parent
            mp.unshift(mi.child_index)
          end
          mp
        end
        
        def level
          materialized_path.size
        end
        
        def child_of?(other)
          parent == other
        end
        
        def parent_of?(other)
          other.child_of?(self)
        end
        
        # Ususally it's sufficient just to check whether the [b,d] are equal,
        # but not always, due to the first child versus next sibling ambiguity
        def sibling_of?(other)
          parent == other.parent
        end
        
        # < and <= consider only the MI's rational encoding: a/c (see notes
        # above on <, >, <=, >=)
        def descendent_of?(other)
          # Guard against tricky edge case; rational encoding of first child and next sibling is the same!
          # The == here includes full MI, below <= includes only the rational encoding.
          return false if self == other.next_sibling
          
          # Direction of descendents interval reverses at each level!
          case other.determinant
            when -1 then return (other              <  self and self <= other.next_sibling)
            when  1 then return (other.next_sibling <= self and self <  other)
            else raise
          end
        end
        
        def ancestor_of?(other)
          other.descendent_of?(self)
        end
        
        def select_descendents(*mis)
          case determinant
            when -1 then mis.select { |mi| mi != next_sibling and self         <  mi and mi <= next_sibling }
            when  1 then mis.select { |mi| mi != next_sibling and next_sibling <= mi and mi <  self}
            else raise
          end
        end
        
        ### Could improve...
        def select_ancestors(*mis)
          mis.select{ |mi| self.descendent_of?(mi) }
        end
        
        # See http://arxiv.org/abs/cs.DB/0402051 heading 7. The receiver is
        # taken to be the head of the subtree to move. The position to move to
        # is given as a new self node. The remaining arguments are assumed to
        # represent the entire tree of existing nodes. Receiver and descendents
        # are moved, all other nodes are left alone.
        def move_subtree(new_self, *tree)
          tree.flatten!
          raise ArgumentError if tree.any?{|mi| mi == new_self} # Cannot move to a position that already exists
          
          inv = self.inverse
          tree.each do |mi|
            next unless mi.descendent_of?(self) ### Could make this check more efficient...
            moved = klass.mmult(new_self.to_a, inv, mi.to_a) # Calculate new position
            mi.instance_variable_set(:@encoding, moved)      # Set new position
          end
          @encoding = new_self.to_a # Move self to new_self
          
          tree
        end
        
        def succ
          next_sibling
        end
        
        def <=>(other)
          materialized_path <=> other.materialized_path
        end
        
        class << self
          # Check whether the argument is an array that meets requirements to be
          # converted into a MI
          def mi_array?(*args)
            args.all? do |a|
              a.is_a?(Array) and a.size == 4 and a.all?{|x|x.is_a?(Integer)}
            end
          end
          
          # Chainable 2x2 matrix multiplication
          # (Works with and returns arrays)
          def mmult(*arrays)
            raise TypeError unless arrays.all?{|array| mi_array?(array)}
            
            result_array = arrays.inject do |array1, array2|
              a1, b1, c1, d1 = array1
              a2, b2, c2, d2 = array2
              [(a1*a2 + b1*c2), (a1*b2 + b1*d2), (c1*a2 + d1*c2), (c1*b2 + d1*d2)]
            end
          end
          
          def from_materialized_path(path)
            new(mi_array_from_materialized_path(path))
          end
          
          def mi_array_from_materialized_path(path)
            raise TypeError unless path.all?{|frag| frag.is_a?(Integer) and frag > 0}
            arrays = path.collect{|frag| mi_array_from_path_fragment(frag)}
            mmult(*arrays)
          end
          
          def string_to_path(path_str, delim='.')
            path_str.split(delim).collect{|frag|frag.to_i}
          end
          
          private
          
          def mi_array_from_path_fragment(fragment)
            [fragment, 1, 1, 0]
          end
          
        end
        
        
        private
        
        def mi_array?(a=self)
          klass.mi_array?(a)
        end
        
        # Shorthand...
        def klass
          self.class
        end
        
        # Shorthand
        def new(*args)
          self.class.new(*args)
        end
        
      end
      
    end
  end
end
