module RbsRails
  module Util
    MODULE_NAME = Module.instance_method(:name)

    extend self

    if '2.7' <= RUBY_VERSION
      def module_name(mod)
        # HACK: RBS doesn't have UnboundMethod#bind_call
        (_ = MODULE_NAME).bind_call(mod)
      end
    else
      def module_name(mod)
        MODULE_NAME.bind(mod).call
      end
    end

    def format_rbs(rbs)
      decls =
        if Gem::Version.new('3') <= Gem::Version.new(RBS::VERSION) 
          # TODO: Remove this type annotation when rbs_rails depends on RBS v3
          # @type var parsed: [RBS::Buffer, untyped, RBS::Declarations::t]
          parsed = _ = RBS::Parser.parse_signature(rbs)
          parsed[1] + parsed[2]
        else
          RBS::Parser.parse_signature(rbs)
        end

      StringIO.new.tap do |io|
        RBS::Writer.new(out: io).write(decls)
      end.string
    end
  end
end
