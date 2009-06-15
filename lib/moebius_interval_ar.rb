module ChinasaurLi
  module Acts
    module NestedMoebius
      
      module MoebiusIntervalAr
        attr_reader :ar_object
        def ar_object=(other)
          raise SecurityError unless @ar_object.nil?
          raise TypeError     unless other.is_a?(ActiveRecord::Base)
          @ar_object = other
        end
        
        def ar_class
          return nil unless ar_object
          ar_object.class
        end
        
        def ar_a; ar_object.acts_as_nested_moebius_options[:a] rescue nil; end
        def ar_b; ar_object.acts_as_nested_moebius_options[:b] rescue nil; end
        def ar_c; ar_object.acts_as_nested_moebius_options[:c] rescue nil; end
        def ar_d; ar_object.acts_as_nested_moebius_options[:d] rescue nil; end
        def ar_p; ar_object.acts_as_nested_moebius_options[:p] rescue nil; end
        
        ### Could rewrite child_of?, parent_of?, sibling_of? to use simpler parent_id...?
        def parent_id
          return nil unless ar_object
          ar_object[ar_p]
        end
        
        def find_descendents(find_opts={})
          ns = next_sibling
          ns_cond = "NOT (#{ar_b}=#{b} AND #{ar_d}=#{d})"
          
          case determinant
            when -1 then interval_cond = "(#{a}   *#{ar_c} <  #{ar_a}*#{c})    AND (#{ar_a}*#{ns.c} <= #{ns.a}*#{ar_c})"
            when  1 then interval_cond = "(#{ns.a}*#{ar_c} <= #{ar_a}*#{ns.c}) AND (#{ar_a}*#{c}    <  #{a}   *#{ar_c})"
            else raise
          end
          
          find_opts[:conditions] = ar_class.merge_conditions(find_opts[:conditions], ns_cond, interval_cond)
          ar_class.find(:all, find_opts)
        end
        
      end
      
    end
  end
end

# Need to define if running active_record < 2.1
# http://apidock.com/rails/v2.1.0/ActiveRecord/Base/merge_conditions/class
if !ActiveRecord::Base.respond_to?(:merge_conditions)
  class << ActiveRecord::Base
    def merge_conditions(*conditions)
      segments = []
      
      conditions.each do |condition|
        unless condition.blank?
          sql = sanitize_sql(condition)
          segments << sql unless sql.blank?
        end
      end
      
      "(#{segments.join(') AND (')})" unless segments.empty?
    end
  end
end
