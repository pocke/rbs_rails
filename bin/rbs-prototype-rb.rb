#!ruby

require 'rbs'
require 'rbs/cli'

using Module.new {
  refine(Object) do
    def const_name(node)
      case node.type
      when :CONST
        node.children[0]
      when :COLON2
        base, name = node.children
        base = const_name(base)
        return unless base
        "#{base}::#{name}"
      end
    end
  end
}

module PrototypeExt
  def process(...)
    process_class_methods(...) || super
  end

  def literal_to_type(node)
    class_new_method_to_type(node) || super
  end

  def process_class_methods(node, decls:, comments:, singleton:)
    return false unless node.type == :ITER

    fcall = node.children[0]
    return false unless fcall.children[0] == :class_methods

    name = RBS::TypeName.new(name: :ClassMethods, namespace: RBS::Namespace.empty)
    mod = RBS::AST::Declarations::Module.new(
      name: name,
      type_params: RBS::AST::Declarations::ModuleTypeParams.empty,
      self_types: [],
      members: [],
      annotations: [],
      location: nil,
      comment: comments[node.first_lineno - 1]
    )

    decls.push mod

    each_node [node.children[1]] do |child|
      process child, decls: mod.members, comments: comments, singleton: false
    end

    true
  end

  def class_new_method_to_type(node)
    case node.type
    when :CALL
      recv, name, _args = node.children
      return unless name == :new

      klass = const_name(recv)
      return unless klass

      type_name = RBS::TypeName.new(name: klass, namespace: RBS::Namespace.empty)
      RBS::Types::ClassInstance.new(name: type_name, args: [], location: nil)
    end
  end
end

RBS::Prototype::RB.prepend PrototypeExt

RBS::CLI.new(stdout: STDOUT, stderr: STDERR).run(ARGV.dup)
