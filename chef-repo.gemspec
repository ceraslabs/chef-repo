Gem::Specification.new do |s|
  s.name        = "customized-chef-repo"
  s.version     = "0.0.0"
  s.summary     = "This is a customized chef repository dedicating for pattern-deployer"
  s.description = s.summary
  s.authors     = ["Hongbin Lu"]
  s.email       = ["hongbin034@gmail.com"]
  s.homepage    = "https://github.com/ceraslabs/chef-repo.git"
  s.files       = `git ls-files`.split("\n")
end
