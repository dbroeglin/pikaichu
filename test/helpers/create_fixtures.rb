# spec/support/create_fixtures.rb

require 'factory_bot_rails'

class CreateFixtures
  include FactoryBot::Syntax::Methods

  attr_accessor :fbuilder, :models, :fixed_time

  def initialize(fbuilder)
    @fbuilder = fbuilder
    @models = {}.with_indifferent_access
    @fixed_time = Time.utc(2023, 3, 14, 9, 2, 6)

    fbuilder.name_model_with(User) do |record|
      ActiveSupport::Inflector.parameterize("#{record['firstname']}.#{record['lastname']}", separator: '_')
    end
    fbuilder.name_model_with(StaffRole) do |record|
      record['code']
    end
    fbuilder.name_model_with(ParticipatingDojo) do |record|
      ActiveSupport::Inflector.parameterize(record['display_name'], separator: '_')
    end
  end

  def create_all
    reset_pk_sequences
    create_users
    create_staff_roles
    create_dojos
    create_taikais
    reset_pk_sequences
  end

  private

  def reset_pk_sequences
    puts 'Resetting Primary Key sequences'
    ActiveRecord::Base.connection.tables.each do |t|
      ActiveRecord::Base.connection.reset_pk_sequence!(t)
    end
  end


  def create_dojos
    create :dojo,
      name: 'dojo_fr',
      city: 'Montpelier',
      country_code: 'FR'
    create :dojo,
      name: 'dojo_hk',
      city: 'Hong-Kong',
      country_code: 'HK'
    create :dojo,
      name: 'dojo_jp',
      city: 'Kyoto',
      country_code: 'JP'
    create :dojo,
      name: 'Dojo To Delete',
      city: 'Kyoto',
      country_code: 'JP'
  end

  def create_users
    models[:users] = {}.with_indifferent_access

    # Jean is the administrator of the application. He has full access to all the data and users.
    models[:users]['jean_bon'] = create(:user, firstname: 'Jean', lastname: 'Bon', admin: true)

    # Marc is a Taikai admin. He knows the application well and understands Taikai organization and rules.
    models[:users]['marc_o_polo'] = create(:user, firstname: 'Marc', lastname: "O'Polo")

    # Alain is a participating dojo administrator
    models[:users]['alain_terieur'] = create(:user, firstname: 'Alain', lastname: 'Terieur')

    # Alex is a Taikai participant she accesses the application to visualize her results.
    models[:users]['alex_terieur'] = create(:user, firstname: 'Alex', lastname: 'Terieur')

    # Pat is a federation official, her role is to validate (homologates) Taikais and results.
    models[:users]['pat_ronat'] = create(:user, firstname: 'Pat', lastname: 'Ronat')

    # Vince is a Taikai chairman. He does not know the application as well as Marc but can use it.
    models[:users]['vince_santo'] = create(:user, firstname: 'Vince', lastname: 'Santo')

    # Marie is a Kyudo fan, she follows Taikais and the championship. She might be a participant at times.
    models[:users]['marie_tournelle'] = create(:user, firstname: 'Marie', lastname: 'Tournelle')
  end

  def create_staff_roles
    models[:staff_roles] = {}.with_indifferent_access

    %w(taikai_admin dojo_admin chairman marking_referee shajo_referee target_referee yatori operations_chairman).each do |code|
      models[:staff_roles][code] = create(:staff_role, code: code)
    end
  end


  def create_taikais
    %w(kinteki enteki).each do |scoring|
      [true, false].each do |distributed|
        create :taikai_with_participating_dojo,
          user: models[:users]['marc_o_polo'],
          form: 'matches',
          distributed: distributed,
          total_num_arrows: 4,
          scoring: scoring

        [12, 20].each do |total_num_arrows|
          create :taikai_with_participating_dojo,
            form: '2in1',
            user: models[:users]['marc_o_polo'],
            distributed: distributed,
            total_num_arrows: total_num_arrows,
            scoring: scoring

          create :taikai_with_participating_dojo,
            form: 'individual',
            user: models[:users]['marc_o_polo'],
            distributed: distributed,
            total_num_arrows: total_num_arrows,
            scoring: scoring

          create :taikai_with_participating_dojo,
            form: 'team',
            user: models[:users]['marc_o_polo'],
            distributed: distributed,
            total_num_arrows: total_num_arrows,
            scoring: scoring
        end
      end
    end
  end

  # other creation and helper methods to abstract common logic, e.g.
  # * custom naming rules via #name_model_with
  # * set up associations by storing created model records in a hash so you can retrieve them
  # etc... (hopefully some of these helper patterns can be standardized and included in the gem in the future)
 end