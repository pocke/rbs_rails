module RbsRails
  class CLI
    class Server
      # The Debouncer module provides functionality to debounce RBS generation requests.
      module Debouncer
        DEBOUNCE_INTERVAL = 0.5  # 500ms

        private

        # @rbs @last_generation_time: Hash[String, Time]

        def last_generation_time #: Hash[String, Time]
          @last_generation_time ||= {}
        end

        # @rbs uri: String
        def should_skip_generation?(uri) #: bool
          now = Time.now
          last_time = last_generation_time[uri]

          if last_time && (now - last_time) < DEBOUNCE_INTERVAL
            return true
          end

          last_generation_time[uri] = now
          false
        end
      end
    end
  end
end
