class AddUrlToSocialMediaAccountTranslations < ActiveRecord::Migration[6.0]
  def change
    reversible do |dir|
      dir.up do
        SocialMediaAccount.add_translation_fields!({ url: :text }, { migrate_data: true })
      end

      dir.down do
        remove_column :social_media_account_translations, :url
      end
    end
  end
end
