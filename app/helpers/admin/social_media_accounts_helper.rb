module Admin::SocialMediaAccountsHelper
  def social_media_account_translation_css_class(translated_contact)
    c = %w[social_media_account-translation]
    c << "right-to-left" if translated_contact.translation_locale.rtl?
    c.join(" ")
  end
end
