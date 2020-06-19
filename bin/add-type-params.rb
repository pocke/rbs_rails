require 'rbs'
rbs = ARGF.read
decls = RBS::Parser.parse_signature(rbs)

def args(n)
  (:T..).take(n)
end

def env
  @env ||= RBS::Environment.new.tap do |env|
    loader = RBS::EnvironmentLoader.new()
    loader.load(env: env)
  end
end

def apply_to_superclass(decl)
  return unless decl.super_class

  name = decl.super_class.name
  type = env.find_class(name) || env.find_class(name.absolute!)
  return unless type
  return if type.type_params.empty?

  args = args(type.type_params.size)
  decl.super_class.instance_variable_set(:@args, args)
  type_params = RBS::AST::Declarations::ModuleTypeParams.new.tap do |tp|
    args.each do |a|
      tp.add RBS::AST::Declarations::ModuleTypeParams::TypeParam.new(name: a)
    end
  end

  decl.instance_variable_set(:@type_params, type_params)
end

def apply_to_includes(decl)
  decl.members.each do |member|
    next unless member.is_a?(RBS::AST::Members::Mixin)

    name = member.name
    type = env.find_class(name) || env.find_class(name.absolute!)
    next unless type
    next if type.type_params.empty?

    args = type.type_params.size.times.map { :untyped }
    member.instance_variable_set(:@args, args)
  end
end

decls.each do |decl|
  case decl
  when RBS::AST::Declarations::Class
    apply_to_superclass(decl)
    apply_to_includes(decl)
  when RBS::AST::Declarations::Module, RBS::AST::Declarations::Interface, RBS::AST::Declarations::Extension
    apply_to_includes(decl)
  end
end

puts RBS::Writer.new(out: $stdout).write(decls)
