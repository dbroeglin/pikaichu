# Useful notes

## Commands

Automatically generate random results for all participants in a Taikai:

    Taikai.find_by(shortname: 'individual-12')
      .participants.map {|participant| participant.score.results }.flatten
      .each { |r|
        r.status = ['hit', 'miss'].sample
        r.final = true
        r.save!
      }

    Taikai.find_by(shortname: '2in1-test')
      .participants.map(&:results).flatten
      .each { |r|
        r.status = ['hit', 'miss'].sample
        r.final = true
        r.save!
      }

Only generate results for first round:

    Taikai.find_by(shortname: '2in1-test')
      .participants.map(&:results).flatten
      .filter { |result| result.round == 1 }
      .each { |r|
        r.status = ['hit', 'miss'].sample
        r.final = true
        r.save!
      }

Automatically generate random results for a specific match in a Taikai:

    Taikai.find_by(shortname: '2in1-p2')
      .matches.where(level: 1, index: 1).map(&:results).flatten
      .each { |r|
        r.status = ['hit', 'miss'].sample
        r.final = true
        r.save!
      }

Reset all results in a Taikai:

     Taikai.find_by(shortname: '2in1-test')
       .participants.map(&:results).flatten.select { |r| r.round == 1 }
       .each { |r|
         r.status = nil
         r.final = false
         r.save(validate:false)
       }

Generate results for an Enteki Taikai:

    Taikai.find_by(shortname: '2in1-20-enteki')
      .participants.map(&:results).flatten
      .each { |r|
        r.value = [0, 3, 5, 7, 9, 10].sample
        r.status = r.value == 0 ? 'miss' : 'hit'
        r.final = true
        r.save!
      }

Reset all passwords (Rails 8 authentication with has_secure_password):

    User.all.each { |u| u.update(password: 'password', password_confirmation: 'password') }

Rebuild fixtures:

    rake spec:fixture_builder:rebuild
    RAILS_ENV=test rake db:fixtures:load
