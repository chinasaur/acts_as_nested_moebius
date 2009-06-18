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
        
        def find_ancestors(find_opts={})
          fs_cond = "NOT (#{ar_b}=#{b} AND #{ar_d}=#{d})"
          
          # Direction of intervals reverses at each level!
          forward_cond = "(#{ar_a}*#{ar_d} < #{ar_b}*#{ar_c}) AND ( #{ar_a}         *#{c} <  #{a}* #{ar_c})          AND (#{a}*(#{ar_c}+#{ar_d}) <= (#{ar_a}+#{ar_b})*#{c})"
          reverse_cond = "(#{ar_a}*#{ar_d} > #{ar_b}*#{ar_c}) AND ((#{ar_a}+#{ar_b})*#{c} <= #{a}*(#{ar_c}+#{ar_d})) AND (#{a}* #{ar_c}          <   #{ar_a}         *#{c})"
          interval_cond = "(#{forward_cond}) OR (#{reverse_cond})"
          
          find_opts[:conditions] = ar_class.merge_conditions(find_opts[:conditions], interval_cond, fs_cond)
          find_opts[:order] ||= "#{ar_a} DESC"
          ar_class.find(:all, find_opts)
        end
        
        # Includes self
        def find_siblings(find_opts={})
          sib_cond = "#{ar_b}=#{b} AND #{ar_d}=#{d}"
          find_opts[:conditions] = ar_class.merge_conditions(find_opts[:conditions], sib_cond)
          find_opts[:order] ||= ar_a
          ar_class.find(:all, find_opts)
        end
        
        # Moves current node to new position, bringing along entire descendent tree.
        # The new position can be specified in any way that MoebiusInterval.new()
        # accepts.
        def move_to(new_position)
          raise ArgumentError unless ar_object
          
          new_mi = MoebiusInterval.new(new_position)
          raise ArgumentError if new_mi.descendent_of?(self)
          
          move_matrix = MoebiusInterval.mmult(new_mi.to_a, self.inverse)
          subtree = [ar_object] + find_descendents
          subtree.each do |to_move|
            moved_a = MoebiusInterval.mmult(move_matrix, to_move.moebius_interval.to_a)
            to_move.moebius_interval = MoebiusInterval.new(moved_a)
            to_move.save!
          end
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
