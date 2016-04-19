# This is the class loader, for use as "include Redis::Objects::Sets"
# For the object itself, see "Redis::Set"
require 'redis/sorted_set'
class Redis
  module Objects
    module SortedSets
      def self.included(klass)
        klass.send :include, InstanceMethods
        klass.extend ClassMethods
      end

      # Class methods that appear in your class when you include Redis::Objects.
      module ClassMethods
        # Define a new list.  It will function like a regular instance
        # method, so it can be used alongside ActiveRecord, DataMapper, etc.
        def sorted_set(name, options={})
          redis_objects[name.to_sym] = options.merge(:type => :sorted_set)
          mod = Module.new do
            define_method(name) do
              redis = Redis::SortedSet.new(redis_field_key(name) , redis_field_redis(name), redis_options(name))
              key = redis_field_key(name)
              unless redis.exists?
                yield(send(self.class.redis_id_field)).each do |ev|
                  redis.add(ev.id, ev.created_at.to_i)
                end
              end
              redis
            end
          end

          if options[:global]
            extend mod

            # dispatch to class methods
            define_method(name) do
              self.class.public_send(name)
            end
          else
            include mod
          end
        end
      end

      # Instance methods that appear in your class when you include Redis::Objects.
      module InstanceMethods
      end
    end
  end
end
