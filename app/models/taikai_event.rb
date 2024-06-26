class TaikaiEvent < ApplicationRecord
  belongs_to :taikai
  belongs_to :user

  def self.rectification(taikai:, user:, result:, previous_status:, previous_value: nil)
    data = {
      taikai: {
        id: taikai.id,
        name: taikai.name
      },
      user: {
        id: user.id,
        display_name: user.display_name
      },
      result: {
        id: result.id,
        round: result.round,
        index: result.index,
        status: result.status,
        previous_status: previous_status,
      },
    }

    if taikai.scoring_enteki?
      data[:result][:value] = result.value
      data[:result][:previous_value] = previous_value
      message = I18n.t(
        'templates.taikai_event.rectification.enteki',
        user: user.display_name, taikai: taikai.name,
        round: result.round,
        index: result.index,
        status: Result.human_enum_value(:status, result.status),
        value: result.value,
        previous_status: Result.human_enum_value(:status, previous_status),
        previous_value: previous_value,
        participant: result.score.participant.display_name
      )
    else
      message = I18n.t(
        'templates.taikai_event.rectification.kinteki',
        user: user.display_name, taikai: taikai.name,
        round: result.round,
        index: result.index,
        status: Result.human_enum_value(:status, result.status),
        previous_status: Result.human_enum_value(:status, previous_status),
        participant: result.score.participant.display_name
      )
    end

    TaikaiEvent.create!(
      taikai: taikai,
      user: user,
      category: :rectification,
      message: message,
      data: data
    )
  end

  def self.state_transition(taikai:, user:, from:, to:)
    message = I18n.t(
      "state_transition.#{from}_#{to}",
      user: user.display_name,
      taikai: taikai.name,
      from: from,
      to: to,
      scope: [:templates, :taikai_event]
    )
    data = {
      taikai: {
        id: taikai.id,
        name: taikai.name
      },
      user: {
        id: user.id,
        display_name: user.display_name
      },
      from: from,
      to: to
    }

    TaikaiEvent.create!(
      taikai: taikai,
      user: user,
      category: :state_transition,
      message: message,
      data: data
    )
  end

  def self.tie_break(taikai:, user:, rankable:)
    message = I18n.t(
      "tie_break.#{rankable.class.name.downcase}",
      user: user.display_name,
      taikai: taikai.name,
      "#{rankable.class.name.downcase}": rankable.display_name,
      intermediate_rank: rankable.intermediate_rank,
      rank: rankable.rank,
      scope: [:templates, :taikai_event]
    )
    data = {
      taikai: {
        id: taikai.id,
        name: taikai.name
      },
      user: {
        id: user.id,
        display_name: user.display_name
      },
      "#{rankable.class.name.downcase}": {
        id: rankable.id,
        display_name: rankable.display_name
      },
      intermediate_rank: rankable.intermediate_rank,
      rank: rankable.rank,
    }

    TaikaiEvent.create!(
      taikai: taikai,
      user: user,
      category: :tie_break,
      message: message,
      data: data
    )
  end
end
