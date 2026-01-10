# rubocop:disable Rails/HelperInstanceVariable, Metrics/ModuleLength

module AxlsxExportHelpers
  def taikai_form_icon(taikai)
    title = Taikai.human_enum_value :form, taikai.form
    icon = case taikai.form
    when "individual"
             "fas fa-user"
    when "team"
             "fas fa-users"
    when "2in1"
             "fas fa-code-branch"
    when "matches"
             "fas fa-users"
    else
             raise "Unknown Taikai Form: '#{taikai.form}'"
    end
    %(<span class="icon is-small" title="#{title}"><i class="#{icon}"></i></span>).html_safe
  end

  def result_mark(result)
    if result.final?
      result.value || case result.status
                      when "hit"
                        "O"
                      when "miss"
                        "X"
                      else
                        ""
                      end
    else
      ""
    end
  end

  def export_summary_sheet(xlsx_package)
    xlsx_package.workbook.add_worksheet(name: t(".summary")) do |sheet|
      sheet.column_widths 20, 60
      sheet.page_setup.set paper_width: "210mm", paper_size: 10, paper_height: "297mm", orientation: :portrait
      sheet.add_row [ t(".infos"), "" ], style: [ @header_row_style, @header_row_style ], height: 30
      sheet.merge_cells("A1:B1")

      sheet.add_row [ Taikai.human_attribute_name(:shortname), @taikai.shortname ],
                    style: [ @info_label_cell_style, @info_data_cell_style ], height: 20
      sheet.add_row [ Taikai.human_attribute_name(:name), @taikai.name ],
                    style: [ @info_label_cell_style, @info_data_cell_style ], height: 20
      sheet.add_row [ Taikai.human_attribute_name(:start_date), @taikai.start_date ],
                    style: [ @info_label_cell_style, @date_style ], height: 20
      sheet.add_row [ Taikai.human_attribute_name(:end_date), @taikai.end_date ],
                    style: [ @info_label_cell_style, @date_style ], height: 20
      sheet.add_row [ Taikai.human_attribute_name(:description), @taikai.description ],
                    style: [ @info_label_cell_style, @description_style ], height: 60
      sheet.add_row [
        t(".type"),
        "#{@taikai.human_form} - #{@taikai.human_scoring}#{" (#{t('.distributed')})" if @taikai.distributed?}"
      ], style: [ @info_label_cell_style, @info_data_cell_style ], height: 20
      sheet.add_row [ Taikai.human_attribute_name(:total_num_arrows), @taikai.total_num_arrows ],
                    style: [ @info_label_cell_style, @info_data_cell_style ], height: 20
      sheet.add_row [ Taikai.human_attribute_name(:tachi_size), @taikai.tachi_size ],
                    style: [ @info_label_cell_style, @info_data_cell_style ], height: 20

      sheet.add_row []
      sheet.add_row []
      sheet.add_row []

      # line 10

      sheet.add_row [ ParticipatingDojo.model_name.human(count: 2), " " ],
                    style: [ @header_row_style, @header_row_style ], height: 30
      sheet.merge_cells("A13:B13")

      @taikai.participating_dojos.each do |participating_dojo|
        dojo = participating_dojo.dojo
        sheet.add_row [
          participating_dojo.display_name,
          "#{dojo.shortname} (#{dojo.name})#{dojo.city.blank? ? '' : ", #{dojo.city}"}, #{dojo.country_name}"
        ],
                      style: [ @info_label_cell_style, @description_style ], height: 20
      end
    end
  end

  def export_staff_sheet(xlsx_package)
    xlsx_package.workbook.add_worksheet(name: t(".staff.title")) do |sheet|
      sheet.column_widths 23, 20, 20, 17

      sheet.add_row [
        t(".staff.lastname"),
        t(".staff.firstname"),
        t(".staff.role"),
        t(".staff.participating_dojo")
      ], style: @header_row_style

      @taikai.staffs.each do |staff|
        row = [
          staff.lastname,
          staff.firstname,
          staff.role.label,
          if staff.participating_dojo.nil?
            ""
          else
            "#{staff.participating_dojo.display_name} (#{staff.participating_dojo.dojo.shortname})"
          end
        ]

        sheet.add_row row, style: [ @table_cell_style, @table_cell_style, @table_cell_style, @table_cell_style ]
      end
      sheet.page_setup.set paper_width: "210mm", paper_size: 10, paper_height: "297mm", orientation: :portrait
    end
  end

  def export_participants_sheet(xlsx_package)
    if @taikai.form_individual?
      xlsx_package.workbook.add_worksheet(name: t(".participants.title")) do |sheet|
        sheet.column_widths 20, 4, 40, 12

        sheet.add_row [
          t(".participants.participating_dojo"),
          t(".participants.index"),
          t(".participants.display_name"),
          t(".participants.club")
        ], style: @header_row_style

        dojo_start_line = 2
        @taikai.participating_dojos.each do |participating_dojo|
          next if participating_dojo.participants.empty? # TODO: maybe still display the dojo but with empty line?

          participating_dojo.participants.each do |participant|
            row = [
              "#{participating_dojo.display_name} (#{participating_dojo.dojo.shortname})",
              participant.index,
              participant.display_name,
              participant.club
            ]

            sheet.add_row row, style: [ @table_cell_style ] * row.size
          end
          line = dojo_start_line + participating_dojo.participants.size - 1
          sheet.merge_cells("A#{dojo_start_line}:A#{line}")
          dojo_start_line = line + 1
        end
        sheet.page_setup.set paper_width: "210mm", paper_size: 10, paper_height: "297mm", orientation: :portrait
      end
    else
      # Team Taikai Participants
      xlsx_package.workbook.add_worksheet(name: t(".participants.title")) do |sheet|
        sheet.column_widths 20, 4, 20, 40, 12

        sheet.add_row [
          t(".participants.participating_dojo"),
          t(".participants.index"),
          t(".participants.team"),
          t(".participants.display_name"),
          t(".participants.club")
        ], style: @header_row_style

        dojo_start_line = 2
        team_start_line = 2
        @taikai.participating_dojos.each do |participating_dojo|
          next if participating_dojo.participants.empty? # TODO: maybe still display the dojo but with empty line?

          participating_dojo.teams.each_with_index do |team, _team_index|
            team.participants.each_with_index do |participant, participant_index|
              row = [
                "#{participating_dojo.display_name} (#{participating_dojo.dojo.shortname})",
                team.index,
                team.shortname,
                participant.display_name,
                participant.club
              ]

              sheet.add_row row, style: [ @table_cell_style ] * row.size

              next unless participant_index.zero?

              line = team_start_line + team.participants.size - 1
              sheet.merge_cells("B#{team_start_line}:B#{line}")
              sheet.merge_cells("C#{team_start_line}:C#{line}")
              team_start_line = line + 1
            end
          end
          line = dojo_start_line + participating_dojo.teams.map { |team| team.participants.size }.sum - 1
          sheet.merge_cells("A#{dojo_start_line}:A#{line}")
          dojo_start_line = line + 1
        end

        sheet.page_setup.set paper_width: "210mm", paper_size: 10, paper_height: "297mm", orientation: :portrait
      end
    end
  end

  def export_results_sheets(xlsx_package)
    case @taikai.form
    when "individual"
      export_individual_results xlsx_package
    when "team"
      export_team_results xlsx_package
    when "2in1"
      export_individual_results xlsx_package
      export_team_results xlsx_package
    when "matches"
      export_matches_results xlsx_package
    end
  end

  def export_individual_results(xlsx_package)
    xlsx_package.workbook.add_worksheet(name: t(".results.title.individual")) do |sheet|
      sheet.column_widths(*([ 5, 5, 20, 25 ] + [ 4 ] * @taikai.total_num_arrows + [ 8 ]))

      @current_row = 1
      export_individual_results_table sheet

      if @taikai.distributed?
        @taikai.participating_dojos.each do |participating_dojo|
          next if participating_dojo.participants.empty? # TODO: maybe still display the dojo but with empty line?

          @current_row += 2

          sheet.add_row

          export_individual_results_table sheet, [ participating_dojo ]
        end
      end

      sheet.page_setup.set paper_width: "210mm", paper_size: 10, paper_height: "297mm", orientation: :landscape
    end
  end

  def export_individual_results_table(sheet, participating_dojos = nil)
    participating_dojos = @taikai.participating_dojos if participating_dojos.nil?
    row_styles = [ @table_cell_style, @table_cell_style, @table_cell_style, @table_cell_style ] +
                 [ @result_cell_style ] * @taikai.total_num_arrows +
                 [ @total_cell_style, @result_cell_style ]

    col_styles = [ @vert_header_row_style ] +
                 [ @header_row_style ] * (3 + @taikai.total_num_arrows) +
                 [ @vert_header_row_style ]
    sheet.add_row [
      t(".results.rank"),
      t(".results.index"),
      @taikai.distributed? ? t(".results.participating_dojo") : t(".results.club"),
      t(".results.display_name")
    ] + (
      (1..(@taikai.num_rounds)).map do |index|
        [ t(".results.round", count: index), "", "", "" ]
      end
    ).flatten + [
      t(".results.score")
    ],
                  style: col_styles,
                  height: 50

    columns = ("E".."Z").to_a + ("A".."Z").map { |c| "A#{c}" } # TODO: this does not work for more than ~40 arrows!!!
    @taikai.num_rounds.times do |index|
      sheet.merge_cells("#{columns[4 * index]}#{@current_row}:#{columns[4 * index + 3]}#{@current_row}")
    end
    last_column = columns[@taikai.total_num_arrows]

    # Order participants by reverse score and index
    participants = participating_dojos
                   .map(&:participants)
                   .flatten
                   .sort_by { |participant| [ participant.rank, participant.index || 0 ] }

    current_rank = rank = 1
    exaequo_start_line = @current_row + 1
    previous_rank = participants.first&.rank
    rows = participants.map do |participant|
      if previous_rank != participant.rank
        previous_rank = participant.rank
        current_rank = participant.rank

        sheet.merge_cells("A#{exaequo_start_line}:A#{@current_row}")
        sheet.merge_cells("#{last_column}#{exaequo_start_line}:#{last_column}#{@current_row}")

        exaequo_start_line = @current_row + 1
      end
      rank = participant.rank
      @current_row += 1

      [
        current_rank,
        participant.index,
        @taikai.distributed? ? participant.participating_dojo.display_name : participant.club,
        participant.display_name
      ] + (participant.score.results.map do |result|
        result_mark(result)
      end + [ display_score_axlsx(participant.score, @taikai.scoring_enteki?) ])
    end
    sheet.merge_cells("A#{exaequo_start_line}:A#{@current_row}")
    sheet.merge_cells("#{last_column}#{exaequo_start_line}:#{last_column}#{@current_row}")

    rows.each do |row|
      sheet.add_row row, style: row_styles
    end
  end

  def export_team_results(xlsx_package)
    xlsx_package.workbook.add_worksheet(name: t(".results.title.team")) do |sheet|
      @current_row = 1

      sheet.column_widths(*([ 4, 3, 15, 15, 25 ] + [ 4 ] * @taikai.total_num_arrows + [ 4, 4 ]))

      export_team_results_table sheet, @taikai.participating_dojos

      if @taikai.distributed?
        @taikai.participating_dojos.each do |participating_dojo|
          next if participating_dojo.participants.empty? # TODO: maybe still display the dojo but with empty line?

          @current_row += 2

          sheet.add_row

          export_team_results_table sheet, [ participating_dojo ]
        end
      end

      sheet.page_setup.set paper_width: "210mm", paper_size: 10, paper_height: "297mm", orientation: :landscape
    end
  end

  def export_team_results_table(sheet, participating_dojos = nil)
    row_styles = [ @total_cell_style ] +
                 [ @table_cell_style ] * 4 +
                 [ @result_cell_style ] * @taikai.total_num_arrows +
                 [ @total_cell_style, @total_cell_style ]

    sheet.add_row [
      t(".results.rank"),
      t(".results.index"),
      t(".results.team"),
      @taikai.distributed? ? t(".results.participating_dojo") : t(".results.club"),
      t(".results.display_name")
    ] + (
      (1..(@taikai.num_rounds)).map do |index|
        [ t(".results.round", count: index), "", "", "" ]
      end
    ).flatten + [
      t(".results.score"),
      t(".results.team_score")
    ], style: [ @vert_header_row_style ] + [ @header_row_style ] * (4 + @taikai.total_num_arrows) +
              [ @vert_header_row_style, @vert_header_row_style ], height: 50

    columns = ("F".."Z").to_a + ("A".."Z").map { |c| "A#{c}" } # TODO: this does not work for more than ~40 arrows!!!
    @taikai.num_rounds.times do |index|
      sheet.merge_cells("#{columns[4 * index]}#{@current_row}:#{columns[4 * index + 3]}#{@current_row}")
    end
    last_column = columns[@taikai.total_num_arrows + 1]

    # Order teams by reverse score and index
    teams = participating_dojos
            .map(&:teams)
            .flatten
            .sort_by { |participant| [ participant.rank, participant.index || 0 ] }

    current_rank = rank = 1
    team_start_line = exaequo_start_line = @current_row + 1
    previous_rank = teams.first&.rank
    rows = teams.flat_map do |team|
      next if team.participants.empty?

      # merge team cells
      line = team_start_line + team.participants.size - 1
      sheet.merge_cells("B#{team_start_line}:B#{line}")
      sheet.merge_cells("C#{team_start_line}:C#{line}")
      sheet.merge_cells("D#{team_start_line}:D#{line}")
      # logger.info("MERGE B#{team_start_line}:B#{line}")
      # logger.info("MERGE C#{team_start_line}:C#{line}")
      # logger.info("MERGE D#{team_start_line}:D#{line}")
      team_start_line = line + 1

      if previous_rank != team.rank
        previous_rank = team.rank
        current_rank = rank

        sheet.merge_cells("A#{exaequo_start_line}:A#{@current_row}")
        sheet.merge_cells("#{last_column}#{exaequo_start_line}:#{last_column}#{@current_row}")
        # logger.info("MERGE A#{exaequo_start_line}:A#{@current_row}")
        # logger.info("MERGE #{last_column}#{exaequo_start_line}:#{last_column}#{@current_row}")
        exaequo_start_line = @current_row + 1
      end
      rank += 1

      team.participants.map do |participant|
        @current_row += 1
        [
          current_rank,
          team.index,
          team.shortname,
          @taikai.distributed? ? team.participating_dojo.display_name : participant.club,
          participant.display_name
        ] + (
          participant.score.results.map do |result|
            result_mark(result)
          end + [
            display_score_axlsx(participant.score, @taikai.scoring_enteki?),
            display_score_axlsx(participant.team.score, @taikai.scoring_enteki?)
          ]
        )
      end
    end.compact
    sheet.merge_cells("A#{exaequo_start_line}:A#{@current_row}")
    sheet.merge_cells("#{last_column}#{exaequo_start_line}:#{last_column}#{@current_row}")
    # logger.info("MERGE A#{exaequo_start_line}:A#{@current_row}")
    # logger.info("MERGE A#{last_column}#{exaequo_start_line}:#{last_column}#{@current_row}")

    rows.each do |row|
      sheet.add_row row, style: row_styles
    end

    sheet.page_setup.set paper_width: "210mm", paper_size: 10, paper_height: "297mm", orientation: :landscape
  end

  def export_matches_results(xlsx_package)
    xlsx_package.workbook.add_worksheet(name: t(".results.title.matches")) do |sheet|
      @current_row = 1

      sheet.column_widths(*([ 4, 3, 15, 15, 25 ] + [ 4 ] * @taikai.total_num_arrows + [ 4, 4 ]))

      # TODO: should we fix this and display results?
      # export_matches_results_table sheet, @taikai.participating_dojos

      # if @taikai.distributed?
      #   @taikai.participating_dojos.each do |participating_dojo|
      #     next if participating_dojo.participants.empty? # TODO: maybe still display the dojo but with empty line?

      #     @current_row += 2

      #     sheet.add_row

      #     export_team_results_table sheet, [participating_dojo]
      #   end
      # end

      sheet.page_setup.set paper_width: "210mm", paper_size: 10, paper_height: "297mm", orientation: :landscape
    end
  end

  def export_matches_results_table(sheet, _participating_dojos = nil)
    row_styles = [ @total_cell_style ] +
                 [ @table_cell_style ] * 4 +
                 [ @result_cell_style ] * @taikai.total_num_arrows +
                 [ @total_cell_style, @total_cell_style ]

    sheet.add_row [
      t(".results.rank"),
      t(".results.index"),
      t(".results.team"),
      @taikai.distributed? ? t(".results.participating_dojo") : t(".results.club"),
      t(".results.display_name")
    ] + (
      (1..(@taikai.num_rounds)).map do |index|
        [ t(".results.round", count: index), "", "", "" ]
      end
    ).flatten + [
      t(".results.score"),
      t(".results.team_score")
    ], style: [ @vert_header_row_style ] + [ @header_row_style ] * (4 + @taikai.total_num_arrows) +
              [ @vert_header_row_style, @vert_header_row_style ], height: 50

    columns = ("F".."Z").to_a + ("A".."Z").map { |c| "A#{c}" } # TODO: this does not work for more than ~40 arrows!!!
    @taikai.num_rounds.times do |index|
      sheet.merge_cells("#{columns[4 * index]}#{@current_row}:#{columns[4 * index + 3]}#{@current_row}")
    end
    last_column = columns[@taikai.total_num_arrows + 1]

    teams_by_score = Leaderboard.new(taikai_id: @taikai.id, validated: true).compute_matches_leaderboard

    current_rank = rank = 1
    team_start_line = exaequo_start_line = @current_row + 1
    previous_rank = teams_by_score&.first&.first&.rank
    rows = teams_by_score.flat_map do |team, match, _score|
      next if team.participants.empty?

      # merge team cells
      line = team_start_line + team.participants.size - 1
      sheet.merge_cells("B#{team_start_line}:B#{line}")
      sheet.merge_cells("C#{team_start_line}:C#{line}")
      sheet.merge_cells("D#{team_start_line}:D#{line}")
      # logger.info("MERGE B#{team_start_line}:B#{line}")
      # logger.info("MERGE C#{team_start_line}:C#{line}")
      # logger.info("MERGE D#{team_start_line}:D#{line}")
      team_start_line = line + 1

      if previous_rank != team.rank
        previous_rank = team.rank
        current_rank = rank

        sheet.merge_cells("A#{exaequo_start_line}:A#{@current_row}")
        sheet.merge_cells("#{last_column}#{exaequo_start_line}:#{last_column}#{@current_row}")
        # logger.info("MERGE A#{exaequo_start_line}:A#{@current_row}")
        # logger.info("MERGE #{last_column}#{exaequo_start_line}:#{last_column}#{@current_row}")
        exaequo_start_line = @current_row + 1
      end
      rank += 1

      team.participants.map do |participant|
        @current_row += 1
        [
          current_rank,
          team.index,
          team.shortname,
          @taikai.distributed? ? team.participating_dojo.display_name : participant.club,
          participant.display_name
        ] + (
          # TODO: make less brittle, should work here as we are not displaying matches
          participant.score(match.id).results.map do |result|
            result_mark(result)
          end + [
            display_score_axlsx(participant.score(match.id).score_value, @taikai.scoring_enteki?),
            display_score_axlsx(participant.team.score(match.id).score_value, @taikai.scoring_enteki?)
          ]
        )
      end
    end.compact
    sheet.merge_cells("A#{exaequo_start_line}:A#{@current_row}")
    sheet.merge_cells("#{last_column}#{exaequo_start_line}:#{last_column}#{@current_row}")
    # logger.info("MERGE A#{exaequo_start_line}:A#{@current_row}")
    # logger.info("MERGE A#{last_column}#{exaequo_start_line}:#{last_column}#{@current_row}")

    rows.each do |row|
      sheet.add_row row, style: row_styles
    end

    sheet.page_setup.set paper_width: "210mm", paper_size: 10, paper_height: "297mm", orientation: :landscape
  end

  def export_journal_sheet(xlsx_package)
    return unless @taikai.events.any?

    xlsx_package.workbook.add_worksheet(name: t(".journal.title")) do |sheet|
      sheet.column_widths 30, 25, 40, 20

      sheet.add_row [
        t(".journal.time"),
        t(".journal.user"),
        t(".journal.message"),
        t(".journal.category")
      ], style: @header_row_style

      @taikai.events.each do |event|
        sheet.add_row [
          I18n.l(event.created_at),
          event.user&.display_name,
          event.message,
          TaikaiEvent.human_enum_value(:category, event.category)
        ], style: [ @table_cell_style, @table_cell_style, @wrapped_table_cell_style, @table_cell_style ]
      end

      sheet.page_setup.set paper_width: "210mm", paper_size: 10, paper_height: "297mm", orientation: :landscape
    end
  end
end
