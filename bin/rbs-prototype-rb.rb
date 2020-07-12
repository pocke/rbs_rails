#!ruby

require 'rbs'
require 'rbs/cli'


module PrototypeExt
  def process(...)
    process_class_methods(...) || super
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
end

RBS::Prototype::RB.prepend PrototypeExt

RBS::CLI.new(stdout: STDOUT, stderr: STDERR).run(ARGV.dup)
