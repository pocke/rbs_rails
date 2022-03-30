module RbsRails
  class CallTracer
    class << self
      def trace(target)
        @call_map ||= {}
        TracePoint.new(:call) do |tp|
          called_method = tp.self.method(tp.method_id)
          @call_map[called_method] ||= []
          @call_map[called_method] << {}.tap do |hash|
            tp.parameters.filter_map do |op_name|
              name = op_name[1]
              next unless name
              hash[name] = tp.binding.local_variable_get(name).dup
            end
          end
        end.enable(target: target)
      end

      def result(target)
        @call_map[target] || []
      end
    end
  end
end
