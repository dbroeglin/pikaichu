require 'test_helper'

class TaikaisControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:jean_bon)
    @taikai = taikais(:taikai_1)
    @other_taikai = taikais(:taikai_2)
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
      post taikais_url @taikai,
                       params: {
                         'taikai' => {
                           'shortname' => 'taikai-to-create',
                           'name' => 'Taikai to be created',
                           'description' => "Let's create a new taikai",
                           'start_date' => '2022-01-06',
                           'end_date' => '2022-01-07',
                           'individual' => 'true',
                           'distributed' => 'true',
                         },
                       }
    end
    assert_redirected_to taikais_url
  end

  test 'should get edit' do
    get edit_taikai_url @taikai
    assert_response :success
  end

  test 'should patch update' do
    patch taikai_url @taikai, params: { taikai: @taikai.attributes }
    assert_redirected_to taikais_url
  end

  test 'should not be able to update taikai he is not admin of' do
    patch taikai_url @other_taikai, params: { taikai: @other_taikai.attributes }
    assert_unauthorized
  end

  test 'should get destroy' do
    delete taikai_url @taikai
    assert_redirected_to taikais_url
  end

  test 'should not be able to delete taikai he is not admin of' do
    delete taikai_url @other_taikai
    assert_unauthorized
  end
end
