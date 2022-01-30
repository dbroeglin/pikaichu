require "test_helper"

class TeamingControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:jean_bon)

    @taikai = taikais(:'2in112')
    @participating_dojo = participating_dojos(:fr_2in112)
    @team_a = teams(:a_fr_2in112)
    @team_b = teams(:b_fr_2in112) # empty

    # team a:
    @participant1 = participants(:p1_fr_2in112)
    @participant2 = participants(:p2_fr_2in112)
    @participant3 = participants(:p3_fr_2in112)

    # non assigned
    @participant4 = participants(:p4_fr_2in112)
    @participant5 = participants(:p5_fr_2in112)
    @participant6 = participants(:p6_fr_2in112)
  end

  test "add participant in empty team" do
    patch teaming_move_taikai_participating_dojo_path @taikai, @participating_dojo, params: {
      participant_id: @participant4.id,
      team_id: @team_b.id,
      index: 1,
    }
    assert_response :success

    @participant4.reload

    assert_equal 1, @participant4.index_in_team
    assert_equal @team_b.id, @participant4.team_id
  end

  test "remove participant from team" do
    patch teaming_move_taikai_participating_dojo_path @taikai, @participating_dojo, params: {
      participant_id: @participant1.id
    }
    assert_response :success

    @participant1.reload

    assert_nil @participant1.index_in_team
    assert_nil @participant1.team_id
  end

  test "move participant from team to empty team" do
    patch teaming_move_taikai_participating_dojo_path @taikai, @participating_dojo, params: {
      participant_id: @participant1.id,
      team_id: @team_b.id,
      index: 1,
    }
    assert_response :success

    @participant1.reload
    @team_a.reload
    @team_b.reload

    assert_equal 1, @participant1.index_in_team
    assert_equal @team_b.id, @participant1.team_id
    assert_equal 2, @team_a.participants.size
  end

  test "move participant from team to full team" do
    patch teaming_move_taikai_participating_dojo_path @taikai, @participating_dojo, params: {
      participant_id: @participant4.id,
      team_id: @team_b.id,
      index: 1,
    }
    assert_response :success

    patch teaming_move_taikai_participating_dojo_path @taikai, @participating_dojo, params: {
      participant_id: @participant4.id,
      team_id: @team_a.id,
      index: 2,
    }
    assert_response :success

    @participant4.reload
    @team_a.reload
    @team_b.reload

    assert_equal 2, @participant4.index_in_team
    assert_equal @team_a.id, @participant4.team_id
    assert_equal 4, @team_a.participants.size
    assert_equal 0, @team_b.participants.size
  end

  test "reorder 2 -> 1" do
    patch teaming_move_taikai_participating_dojo_path @taikai, @participating_dojo, params: {
      participant_id: @participant2.id,
      team_id: @team_a.id,
      index: 1,
    }
    assert_response :success

    @participant2.reload
    @team_a.reload

    assert_equal 1, @participant2.index_in_team
    assert_equal @team_a.id, @participant2.team_id
    assert_equal 3, @team_a.participants.size
  end

  test "reorder 1 -> 2" do
    patch teaming_move_taikai_participating_dojo_path @taikai, @participating_dojo, params: {
      participant_id: @participant1.id,
      team_id: @team_a.id,
      index: 2,
    }
    assert_response :success

    @participant1.reload
    @team_a.reload

    assert_equal 2, @participant1.index_in_team
    assert_equal @team_a.id, @participant1.team_id
    assert_equal 3, @team_a.participants.size
  end

  test "reorder 3 -> 1" do
    patch teaming_move_taikai_participating_dojo_path @taikai, @participating_dojo, params: {
      participant_id: @participant3.id,
      team_id: @team_a.id,
      index: 1,
    }
    assert_response :success

    @participant3.reload
    @team_a.reload

    assert_equal 1, @participant3.index_in_team
    assert_equal @team_a.id, @participant3.team_id
    assert_equal 3, @team_a.participants.size
  end

  test "add a team" do
    assert_difference '@participating_dojo.teams.count', 1 do
      post teaming_create_team_taikai_participating_dojo_path @taikai, @participating_dojo, params: {
        shortname: "New Team"
      }
    end
    assert_redirected_to teaming_edit_taikai_participating_dojo_url @taikai, @participating_dojo
    @participating_dojo.reload

    assert_not_nil @participating_dojo.teams.find_by(shortname: "New Team")
  end

  test "cannot add a team with empty name" do
    assert_no_difference '@participating_dojo.teams.count' do
      post teaming_create_team_taikai_participating_dojo_path @taikai, @participating_dojo, params: {
        shortname: ""
      }
    end
    assert_redirected_to teaming_edit_taikai_participating_dojo_url @taikai, @participating_dojo
    assert @controller.instance_variable_get(:@team).errors.of_kind? :shortname, :blank
    assert_equal "Le nom d'une équipe ne peut pas être vide.", flash[:alert]
  end

  test "cannot add team with same name" do
    assert_no_difference '@participating_dojo.teams.count' do
      post teaming_create_team_taikai_participating_dojo_path @taikai, @participating_dojo, params: {
        shortname: @team_a.shortname
      }
    end
    assert_redirected_to teaming_edit_taikai_participating_dojo_url @taikai, @participating_dojo
    assert @controller.instance_variable_get(:@team).errors.of_kind? :shortname, :taken
    assert_equal "Une équipe avec le nom '#{@team_a.shortname}' existe déjà.", flash[:alert]
  end
end
