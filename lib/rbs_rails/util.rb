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
      decls = RBS::Parser.parse_signature(rbs)
      decls = decls[1] + decls[2] if RBS::VERSION.start_with? '3.'
      StringIO.new.tap do |io|
        RBS::Writer.new(out: io).write(decls)
      end.string
    end
  end
end
