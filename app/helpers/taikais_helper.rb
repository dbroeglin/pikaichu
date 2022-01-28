# rubocop:disable all
module TaikaisHelper
  def result_mark(result)
    if result.final?
      case result.status
      when 'hit'
        'O'
      when 'miss'
        'X'
      else
        ''
      end
    else
      ''
    end
  end

  def export_summary_sheet (xlsx_package)
    xlsx_package.workbook.add_worksheet(name: t('.summary')) do |sheet|
      sheet.column_widths 20, 50
      sheet.page_setup.set paper_width: "210mm", paper_size: 10, paper_height: "297mm", orientation: :portrait
      sheet.add_row [t('.infos'), ""], style: [@header_row_style, @header_row_style], height: 30
      sheet.merge_cells('A1:B1')

      sheet.add_row [Taikai.human_attribute_name(:shortname), @taikai.shortname],
                    style: [@info_label_cell_style, @info_data_cell_style], height: 20
      sheet.add_row [Taikai.human_attribute_name(:name), @taikai.name],
                    style: [@info_label_cell_style, @info_data_cell_style], height: 20
      sheet.add_row [Taikai.human_attribute_name(:start_date), @taikai.start_date],
                    style: [@info_label_cell_style, @date_style], height: 20
      sheet.add_row [Taikai.human_attribute_name(:end_date), @taikai.end_date],
                    style: [@info_label_cell_style, @date_style], height: 20
      sheet.add_row [Taikai.human_attribute_name(:description), @taikai.description],
                    style: [@info_label_cell_style, @description_style], height: 60
      sheet.add_row [
        Taikai.human_attribute_name(:type),
        "#{@taikai.form_individual? ? t('.individual.true') : t('.individual.false')}#{" (#{t('.distributed')})" if @taikai.distributed? }"
      ], style: [@info_label_cell_style, @info_data_cell_style], height: 20
      sheet.add_row [Taikai.human_attribute_name(:total_num_arrows), @taikai.total_num_arrows],
                    style: [@info_label_cell_style, @info_data_cell_style], height: 20
      sheet.add_row [Taikai.human_attribute_name(:tachi_size), @taikai.tachi_size],
                    style: [@info_label_cell_style, @info_data_cell_style], height: 20

      sheet.add_row []
      sheet.add_row []
      sheet.add_row []

      # line 10

      sheet.add_row [ParticipatingDojo.model_name.human(count: 2), " "],
                    style: [@header_row_style, @header_row_style], height: 30
      sheet.merge_cells('A12:B12')

      @taikai.participating_dojos.each do |participating_dojo|
        dojo = participating_dojo.dojo
        sheet.add_row [participating_dojo.display_name, "#{dojo.shortname} (#{dojo.name})#{dojo.city.blank? ? '' : ", #{dojo.city}"}, #{dojo.country_name}"],
                      style: [@info_label_cell_style, @description_style], height: 20
      end
    end
  end

  def export_staff_sheet(xlsx_package)
    xlsx_package.workbook.add_worksheet(name: t('.staff.title')) do |sheet|
      sheet.column_widths 23, 20, 20, 17

      sheet.add_row [
        t('.staff.lastname'),
        t('.staff.firstname'),
        t('.staff.role'),
        t('.staff.participating_dojo'),
      ], style: @header_row_style

      @taikai.staffs.each do |staff|
        row = [
          staff.lastname,
          staff.firstname,
          staff.role.label,
          staff.participating_dojo.nil? ? "" : "#{staff.participating_dojo.display_name} (#{staff.participating_dojo.dojo.shortname})"
        ]

        sheet.add_row row, style: [@table_cell_style, @table_cell_style, @table_cell_style, @table_cell_style]
      end
      sheet.page_setup.set paper_width: "210mm", paper_size: 10, paper_height: "297mm", orientation: :portrait
    end
  end

  def export_participants_sheet(xlsx_package)
    if @taikai.form_individual?
      xlsx_package.workbook.add_worksheet(name: t('.participants.title')) do |sheet|
        sheet.column_widths 20, 4, 40, 12

        sheet.add_row [
          t('.participants.participating_dojo'),
          t('.participants.index'),
          t('.participants.display_name'),
          t('.participants.club'),
          ], style: @header_row_style

        dojo_start_line = 2
        @taikai.participating_dojos.each do |participating_dojo|
          participating_dojo.participants.each do |participant|
            row = [
              "#{participating_dojo.display_name} (#{participating_dojo.dojo.shortname})",
              participant.index,
              participant.display_name,
              participant.club,
            ]

            sheet.add_row row, style: [@table_cell_style] * row.size
          end
          line = dojo_start_line + participating_dojo.participants.size - 1
          sheet.merge_cells("A#{dojo_start_line}:A#{line}")
          dojo_start_line = line + 1
        end
        sheet.page_setup.set paper_width: "210mm", paper_size: 10, paper_height: "297mm", orientation: :portrait
      end
    else
      # Team Taikai Participants
      xlsx_package.workbook.add_worksheet(name: t('.participants.title')) do |sheet|
        sheet.column_widths 20, 4, 20, 40, 12

        sheet.add_row [
          t('.participants.participating_dojo'),
          t('.participants.index'),
          t('.participants.team'),
          t('.participants.display_name'),
          t('.participants.club'),
        ], style: @header_row_style

        dojo_start_line = 2
        team_start_line = 2
        @taikai.participating_dojos.each do |participating_dojo|
          participating_dojo.teams.each_with_index do |team, team_index|
            team.participants.each_with_index do |participant, participant_index|
              row = [
                "#{participating_dojo.display_name} (#{participating_dojo.dojo.shortname})",
                team.index,
                team.shortname,
                participant.display_name,
                participant.club,
              ]

              sheet.add_row row, style: [@table_cell_style] * row.size

              if participant_index.zero?
                line = team_start_line + team.participants.size - 1
                sheet.merge_cells("B#{team_start_line}:B#{line}")
                sheet.merge_cells("C#{team_start_line}:C#{line}")
                team_start_line = line + 1
              end

              next unless team_index.zero?

              line = dojo_start_line + participating_dojo.participants.size - 1
              sheet.merge_cells("A#{dojo_start_line}:A#{line}")
              dojo_start_line = line + 1
            end
          end
        end

        sheet.page_setup.set paper_width: "210mm", paper_size: 10, paper_height: "297mm", orientation: :portrait
      end
    end
  end

  def export_results_sheet(xlsx_package)
    if @taikai.form_individual?
      row_styles = [@table_cell_style, @table_cell_style, @table_cell_style, @table_cell_style] +
                   [@result_cell_style] * @taikai.total_num_arrows +
                   [@total_cell_style]

      xlsx_package.workbook.add_worksheet(name: t('.results.title')) do |sheet|
        sheet.add_row [
          t('.results.rank'),
          t('.results.index'),
          @taikai.distributed? ? t('.results.participating_dojo') : t('.results.club'),
          t('.results.display_name')
        ] + (
          (1..(@taikai.num_rounds)).map do |index|
            [t('.results.round', count: index), '', '', '']
          end
        ).flatten + [
          t('.results.score'),
        ], style: [@vert_header_row_style] + [@header_row_style] * (3 + @taikai.total_num_arrows) + [@vert_header_row_style], height: 50
        sheet.column_widths(*([5, 5, 20, 25] + [4] * @taikai.total_num_arrows + [8]))

        columns = ('E'..'Z').to_a # TODO: this does not work for more than 20 arrows!!!
        @taikai.num_rounds.times do |index|
          sheet.merge_cells("#{columns[4 * index]}1:#{columns[4 * index + 3]}1")
        end
        last_column = columns[@taikai.total_num_arrows]

        # Order participants by reverse score and index
        participants = @taikai
          .participating_dojos
          .map(&:participants).flatten
          .sort_by { |participant| [-participant.score, participant.index]}

        current_rank = rank = 1
        exaequo_start_line = current_line = 2
        previous_score = participants.first&.score
        rows = participants.map do |participant|
          if previous_score != participant.score
            previous_score = participant.score
            current_rank = rank

            sheet.merge_cells("A#{exaequo_start_line}:A#{current_line - 1}")
            sheet.merge_cells("#{last_column}#{exaequo_start_line}:#{last_column}#{current_line - 1}")
            exaequo_start_line = current_line
          end
          rank += 1
          current_line += 1

          [
            current_rank,
            participant.index,
            @taikai.distributed? ? participant.participating_dojo.display_name : participant.club,
            participant.display_name,
          ] + (participant.results.map do |result|
            result_mark(result)
          end + [participant.score || 0])
        end
        sheet.merge_cells("A#{exaequo_start_line}:A#{current_line - 1}")
        sheet.merge_cells("#{last_column}#{exaequo_start_line}:#{last_column}#{current_line - 1}")

        rows.each do |row|
          sheet.add_row row, style: row_styles
        end

        sheet.page_setup.set paper_width: "210mm", paper_size: 10, paper_height: "297mm", orientation: :landscape
      end
    else
      row_styles = [@total_cell_style] +
                   [@table_cell_style] * 4 +
                   [@result_cell_style] * @taikai.total_num_arrows +
                   [@total_cell_style, @total_cell_style]

      xlsx_package.workbook.add_worksheet(name: t('.results.title')) do |sheet|
        sheet.add_row [
          t('.results.rank'),
          t('.results.index'),
          t('.results.team'),
          @taikai.distributed? ? t('.results.participating_dojo') : t('.results.club'),
          t('.results.display_name'),
        ] + (
          (1..(@taikai.num_rounds)).map do |index|
            [t('.results.round', count: index), '', '', '']
          end
        ).flatten + [
          t('.results.score'),
          t('.results.team_score'),
        ], style: [@vert_header_row_style] + [@header_row_style] * (4 + @taikai.total_num_arrows) +
                  [@vert_header_row_style, @vert_header_row_style], height: 50
        sheet.column_widths(*([3, 3, 15, 15, 25] + [4] * @taikai.total_num_arrows + [4, 4]))

        columns = ('F'..'Z').to_a + ['AA'] # TODO: this does not work for more than 20 arrows!!!
        @taikai.num_rounds.times do |index|
          sheet.merge_cells("#{columns[4 * index]}1:#{columns[4 * index + 3]}1")
        end
        last_column = columns[@taikai.total_num_arrows + 1]

        # Order teams by reverse score and index
        teams = @taikai
          .participating_dojos
          .map(&:teams).flatten
          .sort_by { |participant| [-participant.score, participant.index]}

        current_rank = rank = 1
        team_start_line = exaequo_start_line = current_line = 2
        previous_score = teams.first&.score
        rows = teams.map do |team|
          # merge team cells
          line = team_start_line + team.participants.size - 1
          sheet.merge_cells("B#{team_start_line}:B#{line}")
          sheet.merge_cells("C#{team_start_line}:C#{line}")
          sheet.merge_cells("D#{team_start_line}:D#{line}")
          team_start_line = line + 1

          if previous_score != team.score
            previous_score = team.score
            current_rank = rank

            sheet.merge_cells("A#{exaequo_start_line}:A#{current_line - 1}")
            sheet.merge_cells("#{last_column}#{exaequo_start_line}:#{last_column}#{current_line - 1}")
            exaequo_start_line = current_line
          end
          rank += 1

          team.participants.map do |participant|
            current_line += 1

            [
              current_rank,
              team.index,
              team.shortname,
              @taikai.distributed? ? team.participating_dojo.display_name : participant.club,
              participant.display_name,
            ] + (participant.results.map do |result|
              result_mark(result)
            end + [
              participant.score || 0,
              participant.team.score || 0,
            ])
          end
        end.flatten(1)
        sheet.merge_cells("A#{exaequo_start_line}:A#{current_line - 1}")
        sheet.merge_cells("#{last_column}#{exaequo_start_line}:#{last_column}#{current_line - 1}")

        rows.each do |row|
          sheet.add_row row, style: row_styles
        end

        sheet.page_setup.set paper_width: "210mm", paper_size: 10, paper_height: "297mm", orientation: :landscape
      end
    end
  end
end
