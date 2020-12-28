module RbsRails
  module Util
    MODULE_NAME = Module.instance_method(:name)

    extend self

    def module_name(mod)
      # HACK: RBS doesn't have UnboundMethod#bind_call
      (_ = MODULE_NAME).bind_call(mod)
    end

    def format_rbs(rbs)
      decls = RBS::Parser.parse_signature(rbs)
      StringIO.new.tap do |io|
        RBS::Writer.new(out: io).write(decls)
      end.string
    end
  end
end
