# Usage
#
#   ruby bin/generate_rbs_from_rails_source_code.rb ../../rails/rails actionpack

require 'bundler/inline'

require 'pathname'
require 'open3'

SIG_DIR = Pathname('assets/sig/generated/')

def bin(c)
  Pathname(__dir__).join(c).to_s
end

def sh!(*cmd, **kwargs)
  puts(cmd.join(' '))
  Open3.capture2(*cmd, **kwargs).then do |out, status|
    raise unless status.success?

    out
  end
end

def patch!(name, rbs)
  case name
  when 'actionpack'
    rbs.gsub!(/(      def _reduce_\d+: \(untyped val, untyped _values\) -> )([A-Z]\w*)/) do
      "#{$~[1]}Nodes::#{$~[2]}"
    end || raise('it looks unnecessary.')

    # XXX: I guess add-type-params.rb resolves this
    rbs.gsub!('-> Parameter', '-> Parameter[untyped]') || raise('it looks unnecessary')
  end
end

def main(rails_code_dir, name)
  files = Pathname(rails_code_dir).join(name, 'lib').glob('**/*.rb').map(&:to_s)
  generated_rbs_path = SIG_DIR.join("#{name}.rbs")

  rbs = sh! 'ruby', bin("rbs-prototype-rb.rb"), 'prototype', 'rb', *files
  rbs.gsub!(/^(?<indent>\s*)class (?<name>\S+) < $/) { "#{$~[:indent]}class #{$~[:name]} # Note: It inherits unnamed class, but omitted" }
  rbs.gsub!(/[^[:ascii:]]+/, '(trim non-ascii characters)')
  patch! name, rbs
  generated_rbs_path.write(rbs)

  rbs = sh! 'ruby', bin('add-type-params.rb'), generated_rbs_path.to_s
  generated_rbs_path.write(rbs)

  sh!({ 'ONLY' => name }, 'ruby', bin('postprocess.rb'), '-rlogger', '-rmutex_m', '-Iassets/sig', '-Isig', 'assets/')
end

main(*ARGV)
