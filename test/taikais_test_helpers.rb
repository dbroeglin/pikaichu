module TaikaisTestHelpers
  TAIKAI_DATA = %I(individual team 2in1).map do |form|
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

    assert_selector "h1.title", text: "Liste des Taikai"
  end

  def go_to_taikai(label)
    taikai = taikais(label)

    go_to_taikais

    click_on taikai.name

    assert_selector "p.title.is-4", text: "#{taikai.name} (#{taikai.shortname})"
  end

  def taikai_shortname(form, distributed, total_num_arrows, enteki)
    "#{form}#{distributed ? "-dist" : ""}-#{total_num_arrows}#{enteki ? "-enteki" : ""}"
  end
end