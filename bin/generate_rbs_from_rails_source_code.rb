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

def main(rails_code_dir, name)
  files = Pathname(rails_code_dir).join(name, 'lib').glob('**/*.rb').map(&:to_s)
  generated_rbs_path = SIG_DIR.join("#{name}.rbs")
  rbs = sh! 'ruby', bin("rbs-prototype-rb.rb"), 'prototype', 'rb', *files
  generated_rbs_path.write(rbs)

  rbs = sh! 'ruby', bin('add-type-params.rb'), generated_rbs_path.to_s
  generated_rbs_path.write(rbs)

  sh!({ 'ONLY' => name }, 'ruby', bin('postprocess.rb'), '-rlogger', '-rmutex_m', '-Iassets/sig', '-Isig', 'assets/')
end

main(*ARGV)
