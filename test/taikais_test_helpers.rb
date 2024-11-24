module TaikaisTestHelpers
  TAIKAI_DATA = %I[individual team 2in1].map do |form|
    [false, true].map do |distributed|
      [12, 20].map do |total_num_arrows|
        [:enteki, :kinteki].map do |scoring|
          [form, distributed, total_num_arrows, scoring]
        end
      end
    end
  end.concat(%I[matches].map do |form|
    [false, true].map do |distributed|
      [4].map do |total_num_arrows|
        [:enteki, :kinteki].map do |scoring|
          [form, distributed, total_num_arrows, scoring]
        end
      end
    end
  end).flatten 3

  def go_to_taikais
    visit taikais_url(per: 50)

    assert_selector 'h1.title', text: 'Liste des Taikai'
  end

  def go_to_taikai(label)
    taikai = taikais(label)

    go_to_taikais

    click_on taikai.name

    assert_selector 'p.subtitle.is-5 b', text: taikai.shortname
    assert_taikai_title taikai.name
  end

  def taikai_shortname(form, distributed, total_num_arrows, scoring)
    "#{form}-#{distributed ? 'dist' : 'local'}-#{total_num_arrows}-#{scoring}"
  end

  def find_test_taikai(*data)
    Taikai.find_by!(shortname: taikai_shortname(*data))
  rescue ActiveRecord::RecordNotFound
    raise "Taikai #{taikai_shortname(*data)} not found in test database"
  end

  def assert_taikai_title(name)
    assert_selector 'p.title.is-4', text: name
  end

  def generate_taikai_results(taikai)
    scope = Result.joins(score: { participant: :taikai }).where('taikais.id = ?', taikai.id)
    if taikai.scoring == 'kinteki'
      scope.update_all(status: :hit, final: true)
    elsif taikai.scoring == 'enteki'
      scope.update_all(status: :hit, value: 3, final: true)
    end
  end

  def transition_taikai_to(taikai, state)
    raise "Taikai current_user must be set before transitions" unless taikai.current_user

    if taikai.in_state? :new
      taikai.transition_to!(:registration)
      return if state == :registration
    end

    if taikai.in_state? :registration
      taikai.participating_dojos.each(&:draw)
      taikai.transition_to!(:marking)
      return if state == :marking
    end

    if taikai.in_state? :marking
      generate_taikai_results(@taikai)
      taikai.transition_to!(:tie_break)
      return if state == :tie_break
    end

    return unless taikai.in_state? :tie_break

    taikai.transition_to!(:done)
  end
end
