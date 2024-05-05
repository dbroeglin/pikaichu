# Changing an already started taikai from 12 arrows to 20 arrows

/!\ Works for this commit: 2023-11-21 5dfaec7, _be careful if you try it on a more recent one_!

```ruby
taikai = Taikai.find(177)

taikai.update_attribute(:total_num_arrows, 20)
taikai.participating_dojos.first.participants.each do |participant|
  now = DateTime.now
  participant.score.results.insert_all(
    (4..5).map do |round_index|
      (1..4).map do |index|
        {
          match_id: nil,
          score_id: participant.score.id,
          round: round_index,
          index: index,
          created_at: now,
          updated_at: now,
        }
      end
    end.flatten)
end
```

# Reseting all users' passwords

/!\ This will reset ALL passwords!!!

```ruby
User.all.each { |u| u.update(encrypted_password: User.new.send(:password_digest, 'password')) }
```
