module TaikaisTestHelpers
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
end