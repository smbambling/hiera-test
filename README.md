# Testing Command

bundle install --path vendor --without system_tests
bundle exec puppet apply --certname=test.example.dev --hiera_config=hiera.yaml test.pp
