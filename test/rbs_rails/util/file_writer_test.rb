require 'test_helper'
require 'tmpdir'
require_relative '../../../lib/rbs_rails/util/file_writer'

class FileWriterTest < Minitest::Test
  def setup
    @temp_dir = Pathname.new(Dir.mktmpdir('file_writer_test'))
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir
  end

  def test_write_on_file_not_found
    file_path = @temp_dir / 'non_existent_file.rbs'
    file_writer = RbsRails::Util::FileWriter.new(file_path)

    file_writer.write("content")

    assert file_path.exist?
    assert_equal "content", file_path.read
  end

  def test_write_on_changed
    file_path = @temp_dir / 'test_file.rbs'
    file_path.write("old content")

    file_writer = RbsRails::Util::FileWriter.new(file_path)

    file_writer.write("new content")

    assert_equal "new content", file_path.read
  end

  def test_write_on_not_changed
    content = "unchanged content"
    mtime = Time.now - 10

    file_path = @temp_dir / 'test_file.rbs'
    file_path.write(content)
    file_path.utime(mtime, mtime)

    file_writer = RbsRails::Util::FileWriter.new(file_path)
    file_writer.write(content)

    assert_equal content, file_path.read
    assert_equal mtime, file_path.mtime
  end
end
