class MoveSocialMediaAccountsToSocialMediaAccountTranslations < ActiveRecord::Migration[6.0]
  def up
    SocialMediaAccount.find_each do |account|
      # puts "Account: #{account.id}"
      # puts "Title: #{account.title}"
      # puts "URL: #{account.url}"

      SocialMediaAccountTranslation.create!(
        title: account.title,
        url: account.url,
        social_media_account_id: account.id,
        locale: "en",
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
