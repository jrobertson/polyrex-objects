Gem::Specification.new do |s|
  s.name = 'polyrex-objects'
  s.version = '0.8.0'
  s.summary = 'polyrex-objects'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.add_runtime_dependency('polyrex-createobject', '~> 0.5', '>=0.5.2') 
  s.signing_key = '../privatekeys/polyrex-objects.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/polyrex-objects'
  s.required_ruby_version = '>= 2.1.0'
end
