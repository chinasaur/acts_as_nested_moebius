module ChinasaurLi
  module Acts
    module NestedMoebius
      
      # Basically just a 4 element array that behaves like 2x2 matrix:
      #   | self[0] self[1] | = | a b |
      #   | self[2] self[3] |   | c d |
      class MoebiusInterval
        
        def initialize(*args)
          if (args.size == 1 or args.size == 2) and args.all?{|arg|arg.is_a?(String)}
            @encoding = self.class.mi_array_from_materialized_path_string(*args)
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
        
        def to_a
          @encoding
        end
        
        def dup
          self.class.new(*@encoding)
        end
        
        def ==(other)
          other.is_a?(self.class) and to_a == other.to_a
        end
        
        def root?
          to_a == [a, 1, 1, 0]
        end
        
        def parent
          return nil if root?
          self.class.new([b, a % b, d, c % d])
        end
        
        # indexes begin at 1, not 0
        # Could use self.class.mmult and self.class.mi_array_from_path_fragment,
        # but this is a bit more direct.
        def child(index)
          index = index.to_i
          raise ArgumentError unless index > 0
          self.class.new(b + a*index, a, d + c*index, c)
        end
        
        def children(indexes)
          indexes.collect do |index|
            child(index)
          end
        end
        
        def next_sibling
          self.class.new(a+b, b, c+d, d)
        end
        
        def prev_sibling
          return nil if child_index == 1
          self.class.new([a-b, b, c-d, d])
        end
        
        # This does not guarantee that self is valid, so should check
        # self.child_index_valid?() first if this is important.
        def child_index
          (a / b).floor
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
          
          def mi_array_from_materialized_path_string(path_str, delim='.')
            path = path_str.split(delim).collect{|frag|frag.to_i}
            mi_array_from_materialized_path(path)
          end
          
          private
          
          def mi_array_from_path_fragment(fragment)
            [fragment, 1, 1, 0]
          end
          
        end
        
        
        private
        
        def mi_array?(a=self)
          self.class.mi_array?(a)
        end
        
      end
      
    end
  end
end