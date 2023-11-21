# spec/support/fixture_builder.rb
require_relative 'create_fixtures'

FixtureBuilder.configure do |fbuilder|
  # rebuild fixtures automatically when these files change:
  fbuilder.files_to_check += Dir[
    "test/factories/*.rb",
    "test/helper/fixture_builder.rb",
    "test/helper/create_fixtures.rb",
  ]
  fbuilder.skip_tables = %w[audits ar_internal_metadata schema_migrations]

  # now declare objects
  fbuilder.factory do
    CreateFixtures.new(fbuilder).create_all
  end
end

# Have factory bot generate non-colliding sequences starting at 1000 for data created after the fixtures
# FactoryBot.sequences.each do |seq|
#  seq.instance_variable_set(:@value, FactoryBot::Sequence::EnumeratorAdapter.new(1000))
# end