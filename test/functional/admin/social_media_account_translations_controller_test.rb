require "test_helper"

class Admin::SocialMediaAccountTranslationsControllerTest < ActionController::TestCase
  setup do
    login_as :departmental_editor
  end

  should_be_an_admin_controller

  test "create redirects to edit for the chosen language" do
    organisation = create(:organisation)
    social_media_account = create(:social_media_account, socialable: organisation)

    post :create, params: { organisation_id: organisation, social_media_account_id: social_media_account, translation_locale: "fr" }

    assert_redirected_to edit_admin_organisation_social_media_account_translation_path(organisation, social_media_account, id: "fr")
  end

  view_test "edit indicates which language we are adding a translation for" do
    organisation = create(:organisation)
    social_media_account = create(:social_media_account, socialable: organisation, title: "english-title")

    get :edit, params: { organisation_id: organisation, social_media_account_id: social_media_account, id: "fr" }

    assert_select "h1", text: "Edit ‘Français (French)’ translation for: english-title"
  end

  view_test "edit displays translation boxes for social media accounts" do
    organisation = create(:organisation)
    social_media_account = create(:social_media_account, socialable: organisation, title: "english-title")

    get :edit, params: { organisation_id: organisation, social_media_account_id: social_media_account, id: "fr" }

    assert_select "input", value: "http://foo"
  end

  test "update updates translation and redirects back to social media accounts list" do
    organisation = create(:organisation)
    social_media_account = create(:social_media_account, socialable: organisation, title: "english-title")

    put :update,
        params: { organisation_id: organisation,
                  social_media_account_id: social_media_account,
                  id: "fr",
                  social_media_account: {
                    title: "Afrolasie Bureau",
                    url: "http://foo",
                  } }

    social_media_account.reload

    with_locale :fr do
      assert_equal "Afrolasie Bureau", social_media_account.title
      assert_equal "http://foo", social_media_account.url
    end

    assert_redirected_to admin_organisation_social_media_accounts_path(organisation)
  end

  test "destroy removes translation and redirects to contacts list" do
    organisation = create(:organisation)
    social_media_account = create(:social_media_account, socialable: organisation, translated_into: [:fr])

    delete :destroy, params: { organisation_id: organisation, social_media_account_id: social_media_account, id: "fr" }

    social_media_account.reload
    assert_not social_media_account.translated_locales.include?(:fr)
    assert_redirected_to admin_organisation_social_media_accounts_path(organisation)
  end
end
