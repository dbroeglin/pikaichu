module TaikaisTestHelpers
  TAIKAI_DATA = %I[individual team 2in1].map do |form|
    [false, true].map do |distributed|
      [12, 20].map do |total_num_arrows|
        [false, true].map do |enteki|
          [form, distributed, total_num_arrows, enteki]
        end
      end
    end
  end.flatten 3

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

  def taikai_shortname(form, distributed, total_num_arrows, enteki)
    "#{form}-#{distributed ? 'dist' : 'local'}-#{total_num_arrows}-#{enteki ? 'enteki' : 'kinteki'}"
  end

  def find_test_taikai(*data)
    begin
      Taikai.find_by!(shortname: taikai_shortname(*data))
    rescue ActiveRecord::RecordNotFound
      raise "Taikai #{taikai_shortname(*data)} not found in test database"
    end
  end

  def assert_taikai_title(name)
    assert_selector 'p.title.is-4', text: name
  end
end