Gem::Specification.new do |s|
  s.name = 'polyrex-objects'
  s.version = '1.0.2'
  s.summary = 'Polyrex-objects automically builds objects from a Polyrex schema'
  s.authors = ['James Robertson']
  s.files = Dir['lib/polyrex-objects.rb']
  s.add_runtime_dependency('polyrex-createobject', '~> 0.7', '>=0.7.0') 
  s.signing_key = '../privatekeys/polyrex-objects.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/polyrex-objects'
  s.required_ruby_version = '>= 2.1.0'
end
