require "language_server-protocol"
require_relative '../../test_helper'
require_relative '../../support/lsp_client'

require_relative '../../../lib/rbs_rails/cli/server/debouncer'

class LSPServerE2ETest < Minitest::Test
  include Minitest::Hooks
  include LanguageServer::Protocol::Constant

  def before_all
    setup!(rbs_rails: false)
    clean_test_signatures

    @lsp_client = LSPClient.new(
      command: ['bundle', 'exec', 'rbs_rails', 'server'],
      working_dir: app_dir
    )
    @lsp_client.initialize_server(app_dir.to_s)
  end

  def teardown
    sleep RbsRails::CLI::Server::Debouncer::DEBOUNCE_INTERVAL  # Wait for a while to avoid the debounce effect
    clean_test_signatures
  end

  def after_all
    @lsp_client&.shutdown
  end

  def test_did_save_for_schema_rb
    @lsp_client.send_did_save_notification("file://#{app_dir}/db/schema.rb")

    target_files = [Pathname('app/models/user.rbs'),
                    Pathname('packs/blogs/app/models/blog.rbs'),]
    target_files.each do |target_file|
      rbs_path = app_dir / 'sig/rbs_rails' / target_file
      wait_for_file(rbs_path)
      assert rbs_path.exist?, "RBS file should be generated at #{rbs_path}"
    end

    rbs_content = (app_dir / 'sig/rbs_rails/app/models/user.rbs').read
    assert_match(/class ::User/, rbs_content, "RBS should contain ::User class")
  end

  def test_did_save_for_activerecord_model
    target_file = Pathname('app/models/user.rb')

    @lsp_client.send_did_save_notification("file://#{app_dir}/#{target_file}")

    rbs_path = app_dir / 'sig/rbs_rails' / target_file.sub_ext('.rbs')
    wait_for_file(rbs_path)
    assert rbs_path.exist?, "RBS file should be generated at #{rbs_path}"

    rbs_content = rbs_path.read
    assert_match(/class ::User/, rbs_content, "RBS should contain ::User class")
  end

  def test_did_save_for_non_activerecord_model
    target_file = Pathname('app/controllers/application_controller.rb')

    @lsp_client.send_did_save_notification("file://#{app_dir}/#{target_file}")

    rbs_path = app_dir / 'sig/rbs_rails' / target_file.sub_ext('.rbs')
    wait_for_file(rbs_path)
    refute rbs_path.exist?, "RBS should not be generated for non-ActiveRecord files"
  end

  def test_did_save_for_routes
    @lsp_client.send_did_save_notification("file://#{app_dir}/config/routes.rb")

    rbs_path = app_dir / 'sig/rbs_rails/path_helpers.rbs'
    wait_for_file(rbs_path)
    assert rbs_path.exist?, "RBS file should be generated at #{rbs_path}"

    rbs_content = rbs_path.read
    assert_match(/interface ::_RbsRailsPathHelpers/, rbs_content, "RBS should contain ::_RbsRailsPathHelpers interface")
  end

  def test_did_save_for_routes_directory
    @lsp_client.send_did_save_notification("file://#{app_dir}/config/routes/api.rb")

    rbs_path = app_dir / 'sig/rbs_rails/path_helpers.rbs'
    wait_for_file(rbs_path)
    assert rbs_path.exist?, "RBS file should be generated at #{rbs_path}"

    rbs_content = rbs_path.read
    assert_match(/interface ::_RbsRailsPathHelpers/, rbs_content, "RBS should contain ::_RbsRailsPathHelpers interface")
  end

  def test_did_change_watched_files_create
    target_file = Pathname('app/models/user.rb')

    uri = "file://#{app_dir}/#{target_file}"
    @lsp_client.send_did_change_watched_files_notification([ { uri:, type: FileChangeType::CREATED } ])

    rbs_path = app_dir / 'sig/rbs_rails' / target_file.sub_ext('.rbs')
    wait_for_file(rbs_path)
    assert rbs_path.exist?, "RBS file should be generated at #{rbs_path}"

    rbs_content = rbs_path.read
    assert_match(/class ::User/, rbs_content, "RBS should contain ::User class")
  end

  def test_did_change_watched_files_changed
    target_file = Pathname('app/models/user.rb')

    uri = "file://#{app_dir}/#{target_file}"
    @lsp_client.send_did_change_watched_files_notification([{ uri:, type: FileChangeType::CHANGED }])

    rbs_path = app_dir / 'sig/rbs_rails' / target_file.sub_ext('.rbs')
    wait_for_file(rbs_path)
    assert rbs_path.exist?, "RBS file should be generated at #{rbs_path}"

    rbs_content = rbs_path.read
    assert_match(/class ::User/, rbs_content, "RBS should contain ::User class")
  end

  def test_did_change_watched_files_delete
    target_file = Pathname('app/models/user.rb')

    rbs_path = app_dir / 'sig/rbs_rails' / target_file.sub_ext('.rbs')
    rbs_path.write("")

    uri = "file://#{app_dir}/#{target_file}"
    @lsp_client.send_did_change_watched_files_notification([{ uri:, type: FileChangeType::DELETED }])

    wait_for_file_removal(rbs_path)
    refute rbs_path.exist?, "RBS file should not exist at #{rbs_path}"
  end

  private

  def wait_for_file(path, timeout: 1)
    start_time = Time.now
    while !path.exist?
      return :timeout if Time.now - start_time > timeout

      sleep 0.1
    end
  end

  def wait_for_file_removal(path, timeout: 1)
    start_time = Time.now
    while path.exist?
      return :timeout if Time.now - start_time > timeout

      sleep 0.1
    end
  end
end
