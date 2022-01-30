require 'test_helper'

class TaikaisControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:alex_terieur)
    @individual12 = taikais(:individual12)
    @other_taikai = taikais(:team12)
    @attributes = @individual12.attributes.delete_if { |key| key =~ /^(id|.*_date|.*_at|.*_by)$/ }
    @other_attributes = @other_taikai.attributes.delete_if { |key| key =~ /^(id|.*_at|.*_by)$/ }

    @generic_params = {
      'shortname' => 'taikai-to-create',
      'name' => 'Taikai to be created',
      'description' => "Let's create a new taikai",
      'start_date' => '2022-01-06',
      'end_date' => '2022-01-07',
      'form' => 'individual',
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
      post taikais_url @individual12, params: {
        'taikai' => @generic_params.merge(total_num_arrows: 13, num_targets: 7, tachi_size: 3)
      }
    end
    assert taikai.errors.where(:total_num_arrows).any?
    assert taikai.errors.where(:num_targets).any?
    assert_empty taikai.errors.where(:tachi_size)
    assert_response :unprocessable_entity
  end

  test 'should get edit' do
    get edit_taikai_url @individual12
    assert_response :success
  end

  test 'should patch update' do
    patch taikai_url @individual12, params: { taikai: @attributes }
    assert_redirected_to taikais_url
  end

  test 'should not be able to update taikai he is not admin of' do
    patch taikai_url @other_taikai, params: { taikai: @other_attributes }
    assert_unauthorized
  end

  test 'should get destroy' do
    delete taikai_url @individual12
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
