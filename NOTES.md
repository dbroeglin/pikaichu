Useful notes
============

Commands
--------

Automatically generate random results for all participants in a Taikai:

    Taikai.find_by(shortname: 'individual-12')
      .participants.map(&:results).flatten
      .each { |r|
        r.status = ['hit', 'miss'].sample
        r.final = true
        r.save
      }

    Taikai.find_by(shortname: '2in1-test')
      .participants.map(&:results).flatten
      .each { |r|
        r.status = ['hit', 'miss'].sample
        r.final = true
        r.save
      }

Only generate results for first round:

    Taikai.find_by(shortname: '2in1-test')
      .participants.map(&:results).flatten
      .filter { |result| result.round == 1 }
      .each { |r|
        r.status = ['hit', 'miss'].sample
        r.final = true
        r.save
      }

Automatically generate random results for a specific match in a Taikai:

    Taikai.find_by(shortname: '2in1-p2')
      .matches.where(level: 1, index: 1).map(&:results).flatten
      .each { |r|
        r.status = ['hit', 'miss'].sample
        r.final = true
        r.save
      }

Reset all results in a Taikai:

     Taikai.find_by(shortname: '2in1-test')
       .participants.map(&:results).flatten.select { |r| r.round == 1 }
       .each { |r|
         r.status = nil
         r.final = false
         r.save(validate:false)
       }

Manually add a result for a tie-break:

    Taikai.find_by(shortname: "2in1-test").participants.find_by(lastname: "LASTNAME").results.create(round: 4, index:1, round_type: 'tie_break', status: 'hit')