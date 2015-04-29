# Install gems for all appraisal definitions:
#
#     $ appraisal install
#
# To run tests on different versions:
#
#     $ appraisal activerecord_x.x rspec spec

[
  [ '3.2', '~> 3.2.0' ],
  [ '4.0', '~> 4.0.0' ],
  [ '4.1', '~> 4.1.0' ],
  [ '4.2', '~> 4.2.0' ],
].each do |ver_name, ver_req|
  # Note: for the rake task to work, these definition names must be the same as the corresponding
  # filename produced in "gemfiles/", i.e. all characters must be in this set: [A-Za-z0-9_.]
  appraise "rails_#{ver_name}" do
    gem 'actionpack', ver_req
  end
end
