require 'moebius_interval'

module ChinasaurLi
  module Acts
    module NestedMoebius
      
      
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      
      module ClassMethods
        
        DEFAULT_OPTIONS = {
          :a => 'nm_a',
          :b => 'nm_b',
          :c => 'nm_c',
          :d => 'nm_d',
          :p => 'parent_id',
          :mprefix => ''
        }
        def acts_as_nested_moebius(opts={})
          cattr_accessor :acts_as_nested_moebius_options
          opts = DEFAULT_OPTIONS.merge(opts)
          self.acts_as_nested_moebius_options = opts
          
          include(InstanceMethods)
          extend(SingletonMethods)
        end
        
        module SingletonMethods
        end
        
        module InstanceMethods
          
          def acts_as_nested_moebius_options
            self.class.acts_as_nested_moebius_options
          end
          
          # Define reader/writer for compound variable moebius_interval
          def moebius_interval(reload=false)
            return @moebius_interval if @moebius_interval and reload == false
            
            opts = acts_as_nested_moebius_options
            array = [ self[opts[:a]], self[opts[:b]], self[opts[:c]], self[opts[:d]] ]
            @moebius_interval = MoebiusInterval.new(*array) if MoebiusInterval.mi_array?(array)
          end
          
          def moebius_interval=(arg)
            if arg.is_a?(Array) and MoebiusInterval.mi_array?(arg)
              a, b, c, d = arg
              mi = MoebiusInterval.new(a, b, c, d)
            elsif arg.is_a?(MoebiusInterval)
              mi = arg
              a, b, c, d = mi.to_a
            else
              raise ArgumentError
            end
            
            opts = acts_as_nested_moebius_options
            self[opts[:a]], self[opts[:b]], self[opts[:c]], self[opts[:d]] = a, b, c, d
            @moebius_interval = mi
          end
          
          def nm_materialized_path(reload=false)
            return @nm_materialized_path if @nm_materialized_path and reload == false
            
            mi = moebius_interval(reload)
            @nm_materialized_path = mi.materialized_path if mi
          end
          
          def nm_materialized_path=(args)
            if args.is_a?(Array) and args.all?{|arg|arg.is_a?(Integer)}
              mp = args
            elsif args.is_a?(Array) and args.size == 2 and args.all?{|arg|arg.is_a?(String)}
              mp = MoebiusInterval.string_to_path(*args)
            elsif args.is_a?(String)
              mp = MoebiusInterval.string_to_path(args)
            else
              raise ArgumentError
            end
            
            @moebius_interval = MoebiusInterval.from_materialized_path(mp)
            @nm_materialized_path = mp
          end
          
          def self.included(base)
            base.class_eval do
              mprefix = acts_as_nested_moebius_options[:mprefix]
              
              unless mprefix == 'nm_'
                alias_method "#{mprefix}materialized_path", :nm_materialized_path
                alias_method "#{mprefix}materialized_path=", :nm_materialized_path=
              end
              
              # Delegate these to MI, if it exists
              ['root?', 'level', 'child_index'].each do |mname|
                define_method("#{mprefix}#{mname}") do |*args|
                  return nil unless mi = moebius_interval
                  mi.send(mname, *args)
                end
              end
              
              # Delegate these to MI, after some argument checks.
              ['child_of?', 'parent_of?', 'sibling_of?', 'descendent_of?', 'ancestor_of?'].each do |mname|
                define_method("#{mprefix}#{mname}") do |other|
                  raise ArgumentError unless other.is_a?(self.class) and other_mi = other.moebius_interval and mi = moebius_interval
                  mi.send(mname, other_mi)
                end
              end
              
            end
          end
          
        end # InstanceMethods
        
      end # AR::B ClassMethods
      
      
    end
  end
end
