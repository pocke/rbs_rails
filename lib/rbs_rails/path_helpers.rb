module RbsRails
  class PathHelpers
    def self.generate(routes: Rails.application.routes)
      # Since Rails 8.0, route drawing has been deferred to the first request.
      # This forcedly loads routes before generating path_helpers.
      Rails.application.routes.eager_load!

      new(routes: Rails.application.routes).generate
    end

    def initialize(routes:)
      @routes = routes
    end

    def generate
      methods = helpers.map do |helper|
        # TODO: More restrict argument types
        "def #{helper}: (*untyped) -> ::String"
      end

      <<~RBS
        # resolve-type-names: false

        interface ::_RbsRailsPathHelpers
        #{methods.join("\n").indent(2)}
        end

        module ::ActionController
          class ::ActionController::Base
            include ::_RbsRailsPathHelpers
          end
        end
      RBS
    end

    private def helpers
      routes.named_routes.helper_names
    end

    private
    # @dynamic routes
    attr_reader :routes
  end
end
