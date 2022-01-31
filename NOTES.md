Useful notes
============

Commands
--------

Automatically generate random results for all participants in a Taikai:

    Taikai.find_by(shortname: 'foobar')
      .participants.map(&:results).flatten
      .each { |r|
        r.status = ['hit', 'miss'].sample
        r.final = true
        r.save
      }