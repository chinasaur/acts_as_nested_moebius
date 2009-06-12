module ChinasaurLi
  module Acts
    module NestedMoebius
      
      module MoebiusIntervalAr
        attr_reader :ar_class
        def ar_class=(other)
          raise SecurityError unless @ar_class.nil?
          raise TypeError     unless other.is_a?(Class) and other.ancestors.include?(ActiveRecord::Base)
          @ar_class = other
        end
        
        
      end
      
    end
  end
end
