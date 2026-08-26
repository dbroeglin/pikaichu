require "test_helper"
require "caxlsx"
require "minitest/mock"
require "rack/test"
require "tempfile"

class ParticipantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:jean_bon)
    @taikai = taikais(:individual_dist_12_kinteki)
    @participating_dojo = participating_dojos(:participating_dojo1_individual_dist_12_kinteki)
    @participant = @participating_dojo.participants.first
  end

  test "should get new" do
    get new_taikai_participating_dojo_participant_url @taikai, @participating_dojo
    assert_response :success
  end

  test "should post create" do
    assert_difference "@participating_dojo.participants.count" do
      post taikai_participating_dojo_participants_url @taikai, @participating_dojo, params: {
        participant: {
          firstname: "Dan",
          lastname: "Brown"
        }
      }
    end
    assert_redirected_to edit_taikai_participating_dojo_url @taikai, @participating_dojo
  end

  test "should not allow an unaffiliated user to create a participant" do
    sign_in users(:marie_tournelle)

    assert_no_difference "@participating_dojo.participants.count" do
      post taikai_participating_dojo_participants_url(@taikai, @participating_dojo),
           params: { participant: { firstname: "Mallory", lastname: "Unauthorized" } }
    end

    assert_unauthorized
  end

  test "should get edit" do
    get edit_taikai_participating_dojo_participant_url @taikai, @participating_dojo, @participant
    assert_response :success
  end

  test "should patch update" do
    patch taikai_participating_dojo_participant_url @taikai, @participating_dojo, @participant,
                                                    params: { participant: @participant.attributes }
    assert_redirected_to edit_taikai_participating_dojo_url @taikai, @participating_dojo
  end

  test "should ignore attempts to move a participant to another participating dojo" do
    target_dojo = @taikai.participating_dojos.second
    sign_in users(:alain_terieur)

    patch taikai_participating_dojo_participant_url(@taikai, @participating_dojo, @participant),
          params: {
            participant: {
              firstname: @participant.firstname,
              lastname: @participant.lastname,
              participating_dojo_id: target_dojo.id
            }
          }

    assert_redirected_to edit_taikai_participating_dojo_url @taikai, @participating_dojo
    assert_equal @participating_dojo, @participant.reload.participating_dojo
  end

  test "should get destroy" do
    delete taikai_participating_dojo_participant_url @taikai, @participating_dojo, @participant
    assert_redirected_to edit_taikai_participating_dojo_url @taikai, @participating_dojo
  end

  test "should reject a URL as an import upload without opening it" do
    opener = lambda do |*|
      flunk "Roo must not open a user-supplied URL"
    end

    Roo::Spreadsheet.stub(:open, opener) do
      assert_no_difference "@participating_dojo.participants.count" do
        post import_taikai_participating_dojo_participants_url(@taikai, @participating_dojo),
             params: { excel: "http://127.0.0.1:3000/internal.xlsx" }
      end
    end

    assert_redirected_to edit_taikai_participating_dojo_url @taikai, @participating_dojo
  end

  test "should reject malformed content named as an xlsx file" do
    with_uploaded_file(filename: "participants.xlsx", contents: "not an xlsx") do |upload|
      assert_no_difference "@participating_dojo.participants.count" do
        post import_taikai_participating_dojo_participants_url(@taikai, @participating_dojo),
             params: { excel: upload }
      end
    end

    assert_redirected_to edit_taikai_participating_dojo_url @taikai, @participating_dojo
    assert_equal I18n.t(:invalid_file), flash[:alert]
  end

  test "should reject oversized xlsx uploads" do
    with_uploaded_file(
      filename: "participants.xlsx",
      size: ParticipantsController::MAX_IMPORT_SIZE + 1
    ) do |upload|
      assert_no_difference "@participating_dojo.participants.count" do
        post import_taikai_participating_dojo_participants_url(@taikai, @participating_dojo),
             params: { excel: upload }
      end
    end

    assert_redirected_to edit_taikai_participating_dojo_url @taikai, @participating_dojo
    assert_equal I18n.t(:invalid_file), flash[:alert]
  end

  test "should import a valid xlsx upload" do
    participant_count = @participating_dojo.participants.count

    with_participants_xlsx do |upload|
      post import_taikai_participating_dojo_participants_url(@taikai, @participating_dojo),
           params: { excel: upload }
    end

    assert_equal participant_count + 1, @participating_dojo.participants.count
    participant = @participating_dojo.participants.find_by!(firstname: "Alice", lastname: "Archer")
    assert_equal "Test Club", participant.club
  end

  private

  def with_uploaded_file(filename:, contents: nil, size: nil)
    Tempfile.create([ "participants", ".xlsx" ]) do |file|
      file.binmode
      size ? file.truncate(size) : file.write(contents)
      file.flush

      yield Rack::Test::UploadedFile.new(
        file.path,
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        true,
        original_filename: filename
      )
    end
  end

  def with_participants_xlsx
    Tempfile.create([ "participants", ".xlsx" ]) do |file|
      path = file.path
      file.close
      package = Axlsx::Package.new
      package.workbook.add_worksheet do |sheet|
        sheet.add_row [ "Prénom", "Nom", "Club" ]
        sheet.add_row [ "Alice", "Archer", "Test Club" ]
      end
      package.serialize(path)

      yield Rack::Test::UploadedFile.new(
        path,
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        true,
        original_filename: "participants.xlsx"
      )
    end
  end
end
