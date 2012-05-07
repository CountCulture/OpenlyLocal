module RakeUtilities
  module UploadDataDumps
    # require File.join(RAILS_ROOT, 'config', 'authentication_details')
    require 'zip/zipfilesystem'
    require 'net/scp'
    
    # zip_and_upload_data_dump('kula_charities', :ftp_path => '/home/kula_user/downloads')
    def zip_and_upload_data_dump(file_name, params={})
      upload_host = params[:upload_host] || SCP_DEST
      upload_user = params[:upload_user] || SCP_USER
      upload_password = params[:upload_password] || SCP_PASSWORD

      tmp_file = File.join(RAILS_ROOT, 'tmp', "#{file_name}.csv")
      Zip::ZipFile.open(File.join(RAILS_ROOT, 'tmp', "#{file_name}.new.zip"), Zip::ZipFile::CREATE) { |zipfile|
        zipfile.add("#{file_name}.csv", tmp_file)
      }
      File.delete(tmp_file)
      FileUtils.mv File.join(RAILS_ROOT, 'tmp', "#{file_name}.new.zip"), File.join(RAILS_ROOT, 'tmp', "#{file_name}.zip"), :force => true
      FileUtils.chmod_R 0644, File.join(RAILS_ROOT, 'tmp', "#{file_name}.zip")
      Net::SCP.start(upload_host, upload_user, :port => 7012, :password => upload_password ) do |scp|
        scp.upload!(File.join(RAILS_ROOT, 'tmp', "#{file_name}.zip"), params[:upload_path])
      end

    end
  end
end