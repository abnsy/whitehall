class ChangeSocialMediaAccountUrlToText < ActiveRecord::Migration[6.0]
  def up
    change_column :social_media_accounts, :url, :text
  end

  def down
    change_column :social_media_accounts, :url, :string
  end
end
