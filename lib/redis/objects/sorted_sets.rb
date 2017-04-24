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
              if !block_given?
                instance_variable_get("@#{name}") or
                  instance_variable_set("@#{name}",
                    Redis::SortedSet.new(
                      redis_field_key(name), redis_field_redis(name), redis_options(name)
                    )
                  )
              elsif options[:customize]
                redis = Redis::SortedSet.new(redis_field_key(name) , redis_field_redis(name), redis_options(name))
                yield(send(self.class.redis_id_field)) unless redis.exists?
                redis
              else
                redis = Redis::SortedSet.new(redis_field_key(name) , redis_field_redis(name), redis_options(name))
                unless redis.exists?
                  redis.add(0, 3000000000.0000000)
                  yield(send(self.class.redis_id_field)).each do |ev|
                    redis.add(ev[:member], ev[:score].to_i)
                  end
                end
                redis
              end
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
