require 'test_helper'

class TaikaisControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:jean_bon)
    @taikai1 = taikais(:taikai1)
    @other_taikai = taikais(:taikai2)

    @generic_params = {
      'shortname' => 'taikai-to-create',
      'name' => 'Taikai to be created',
      'description' => "Let's create a new taikai",
      'start_date' => '2022-01-06',
      'end_date' => '2022-01-07',
      'individual' => 'true',
      'distributed' => 'true',
    }
  end

  test 'should get index' do
    get taikais_url
    assert_response :success
  end

  test 'should get new' do
    get new_taikai_url
    assert_response :success
  end

  test 'should post create' do
    assert_difference 'Taikai.count' do
      post taikais_url,
           params: {
             'taikai' => @generic_params,
           }
    end
    assert_redirected_to taikais_url
  end

  test 'should validate target/arrow/tachi sizes' do
    assert_no_changes 'Taikai.count' do
      post taikais_url @taikai1, params: {
        'taikai' => @generic_params.merge(total_num_arrows: 13, num_targets: 7, tachi_size: 3)
      }
    end
    assert taikai.errors.where(:total_num_arrows).any?
    assert taikai.errors.where(:num_targets).any?
    assert_empty taikai.errors.where(:tachi_size)
    assert_response :unprocessable_entity
  end

  test 'should get edit' do
    get edit_taikai_url @taikai1
    assert_response :success
  end

  test 'should patch update' do
    patch taikai_url @taikai1, params: { taikai: @taikai1.attributes }
    assert_redirected_to taikais_url
  end

  test 'should not be able to update taikai he is not admin of' do
    patch taikai_url @other_taikai, params: { taikai: @other_taikai.attributes }
    assert_unauthorized
  end

  test 'should get destroy' do
    delete taikai_url @taikai1
    assert_redirected_to taikais_url
  end

  test 'should not be able to delete taikai he is not admin of' do
    delete taikai_url @other_taikai
    assert_unauthorized
  end

  def taikai
    @controller.instance_variable_get :@taikai
  end
end
