require 'rbs'
rbs = ARGF.read

decls = RBS::Parser.parse_signature(rbs)
decl_map = {}
decls.each do |decl|
  if d = decl_map[decl.name]
    # TODO: Is it right for decl is not a class / module?
    c = RBS::AST::Declarations::Class
    m = RBS::AST::Declarations::Module
    e = RBS::AST::Declarations::Extension
    raise 'class mismatch' if d.class != decl.class
    raise 'class mismatch' unless [c,m,e].include?(d.class)

    d.members.concat decl.members
    d.members.uniq! { if _1.is_a?(RBS::AST::Members::MethodDefinition) then [_1.name, _1.singleton?] else _1 end}
    case d
    when c
      decl_map[decl.name] = c.new(name: d.name, type_params: d.type_params, super_class: d.super_class || decl.super_class, members: d.members, annotations: d.annotations, location: d.location, comment: d.comment)
    when m
      decl_map[decl.name] = m.new(name: d.name, type_params: d.type_params, members: d.members, self_type: d.self_type, annotations: d.annotations, location: d.location, comment: d.comment)
    when e
      decl_map[decl.name] = e.new(name: d.name, type_params: d.type_params, extension_name: d.extension_name, members: d.members, annotations: d.annotations, location: d.location, comment: d.comment)
    end
  else
    decl_map[decl.name] = decl
  end
end

puts RBS::Writer.new(out: $stdout).write(decl_map.values)
