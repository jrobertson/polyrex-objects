Gem::Specification.new do |s|
  s.name = 'polyrex-objects'
  s.version = '0.6.13'
  s.summary = 'polyrex-objects'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.add_dependency('polyrex-createobject') 
  s.signing_key = '../privatekeys/polyrex-objects.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/polyrex-objects'
end
