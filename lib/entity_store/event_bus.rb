module EntityStore
  class EventBus
    include Logging

    ALL_METHOD = :all_events

    def initialize(event_subscribers = nil)
      @_event_subscribers = event_subscribers if event_subscribers
    end

    def event_subscribers
      @_event_subscribers || EntityStore::Config.event_subscribers
    end

    def publish(entity_type, event)
      publish_to_feed(entity_type, event)

      subscribers_to(event.receiver_name).each { |s| send_to_subscriber(s, event.receiver_name, event) }
      subscribers_to_all.each { |s| send_to_subscriber(s, ALL_METHOD, event) }
    end

    def send_to_subscriber subscriber, receiver_name, event
      subscriber.new.send(receiver_name, event)
      log_debug { "called #{subscriber.name}##{receiver_name} with #{event.inspect}" }
    rescue => e
      log_error "#{e.message} when calling #{subscriber.name}##{receiver_name} with #{event.inspect}", e
    end

    def subscribers_to(event_name)
      subscriber_lookup[event_name.to_sym].dup
    end

    def subscribers_to_all
      subscribers_to(ALL_METHOD)
    end

    def subscriber_lookup_cache
      @@lookup_cache ||= Hash.new
    end

    def subscriber_lookup
      return generate_subscriber_lookup unless EntityStore::Config.cache_event_subscribers

      @lookup ||= begin
        lookup_cache_key = event_subscribers.map(&:to_s).join

        if subscriber_lookup_cache[lookup_cache_key]
          subscriber_lookup_cache[lookup_cache_key]
        else
          subscriber_lookup_cache[lookup_cache_key] = generate_subscriber_lookup
        end
      end
    end

    def generate_subscriber_lookup
      lookup = Hash.new { |h, k| h[k] = Array.new }

      subscribers.each do |s|
        s.instance_methods.each do |m|
          lookup[m] << s
        end
      end

      lookup
    end

    def subscribers
      event_subscribers.map do |subscriber|
        case subscriber
        when String
          EntityStore::Config.load_type(subscriber)
        else
          subscriber
        end
      end
    end

    def publish_to_feed(entity_type, event)
      feed_store.add_event(entity_type, event) if feed_store
    end

    def feed_store
      EntityStore::Config.feed_store
    end

    # Public - replay events of a given type to a given subscriber
    #
    # since             - Time reference point
    # type              - String type name of event
    # subscriber        - Class of the subscriber to replay events to
    #
    # Returns nothing
    def replay(since, type, subscriber)
      max_items = 100
      event_data_objects = feed_store.get_events(since, type, max_items)

      while event_data_objects.count > 0 do
        event_data_objects.each do |event_data_object|
          begin
            event = EntityStore::Config.load_type(event_data_object.type).new(event_data_object.attrs)
            subscriber.new.send(event.receiver_name, event)
            log_info { "replayed #{event.inspect} to #{subscriber.name}##{event.receiver_name}" }
          rescue => e
            log_error "#{e.message} when replaying #{event_data_object.inspect} to #{subscriber}", e
          end
        end
        event_data_objects = feed_store.get_events(event_data_objects.last.id, type, max_items)
      end
    end
  end
end
