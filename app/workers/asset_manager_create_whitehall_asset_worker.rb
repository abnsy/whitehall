class AssetManagerCreateWhitehallAssetWorker < WorkerBase
  include AssetManagerWorkerHelper

  sidekiq_options queue: 'asset_manager'

  def perform(file_path, legacy_url_path, draft = false, model_class = nil, model_id = nil)
    return unless File.exist?(file_path)

    file = File.open(file_path)
    asset_options = { file: file, legacy_url_path: legacy_url_path }
    asset_options[:draft] = true if draft

    if model_class && model_id
      model = model_class.constantize.find(model_id)
      if model.respond_to?(:access_limited?)
        if model.access_limited?
          authorised_user_uids = AssetManagerAccessLimitation.for(model)
          asset_options[:access_limited] = authorised_user_uids
        end
      end
    end

    asset_manager.create_whitehall_asset(asset_options)

    if model
      # sadly we can't just search for url, because it's a magic
      # carrierwave thing not in our model
      Attachment.where(attachable: model.attachables).where.not(attachment_data: nil).find_each do |attachment|
        # 'attachment.attachment_data' can still be nil even with the
        # check above, because if the 'attachment_data_id' is non-nil
        # but invalid, the 'attachment_data' will be nil - and the
        # generated SQL only checks if the 'attachment_data_id' is
        # nil.
        if attachment.attachment_data && attachment.attachment_data.url == legacy_url_path
          attachment.attachment_data.uploaded_to_asset_manager!
        end
      end
    end

    FileUtils.rm(file)
    FileUtils.rmdir(File.dirname(file))
  end
end
