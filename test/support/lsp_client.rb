require 'open3'
require 'json'
require 'pathname'

# Helper class for LSP Server communication in tests
class LSPClient
  attr_reader :verbose

  def initialize(command:, working_dir:, verbose: false)
    @request_id = 0
    @verbose = verbose

    Dir.chdir(working_dir) do
      Bundler.with_unbundled_env do
        @stdin, @stdout, @stderr, @wait_thread = Open3.popen3(*command)
      end
    end

    # Print stderr output from the LSP server for debugging
    @stderr_watcher = Thread.new do
      while line = @stderr.gets rescue nil
        puts "[LSP Server STDERR]: #{line.chomp}"
      end
    end
  end

  def initialize_server(root_uri)
    initialize_request = {
      jsonrpc: "2.0",
      id: next_request_id,
      method: "initialize",
      params: {
        processId: Process.pid,
        rootUri: "file://#{root_uri}",
        capabilities: {}
      }
    }

    send_message(initialize_request)

    response = wait_for_response
    if response
      puts "Initialize response received: #{response['result']&.keys || 'no result'}" if verbose
    else
      raise "No initialize response received from LSP server"
    end

    # initialized通知を送信
    initialized_notification = {
      jsonrpc: "2.0",
      method: "initialized",
      params: {}
    }
    send_message(initialized_notification)
  end

  def send_did_save_notification(file_uri)
    puts "Sending didSave notification for: #{file_uri}" if verbose
    did_save_notification = {
      jsonrpc: "2.0",
      method: "textDocument/didSave",
      params: {
        textDocument: { uri: file_uri }
      }
    }
    send_message(did_save_notification)
  end

  def send_did_change_watched_files_notification(changes)
    puts "Sending didChangeWatchedFiles notification with #{changes.length} changes" if verbose
    did_change_notification = {
      jsonrpc: "2.0",
      method: "workspace/didChangeWatchedFiles",
      params: {
        changes: changes
      }
    }
    send_message(did_change_notification)
  end

  def wait_for_response(timeout: 5)
    start_time = Time.now
    while Time.now - start_time < timeout
      if IO.select([@stdout], nil, nil, 0.1)
        return recv_message
      end
    end
    nil
  end

  def shutdown
    shutdown_request = {
      jsonrpc: "2.0",
      id: next_request_id,
      method: "shutdown",
      params: nil
    }
    send_message(shutdown_request)

    response = wait_for_response(timeout: 5)
    puts "Shutdown response: #{response ? 'received' : 'timeout'}" if verbose

    exit_notification = {
      jsonrpc: "2.0",
      method: "exit",
      params: nil
    }
    send_message(exit_notification)

    close_streams
    @stderr_watcher.join(1)
    @wait_thread.join(5)
  rescue => e
    warn "LSP shutdown failed: #{e.message}"
    force_kill
  end

  def force_kill
    return unless @wait_thread&.alive?

    Process.kill("TERM", @wait_thread.pid) rescue nil
    sleep 0.1
    Process.kill("KILL", @wait_thread.pid) rescue nil
    @wait_thread.join(1)
  end

  def server_running?
    @wait_thread&.alive?
  end

  private

  def next_request_id
    @request_id += 1
  end

  def send_message(message)
    json = JSON.generate(message)
    content = "Content-Length: #{json.bytesize}\r\n\r\n#{json}"
    @stdin.write(content)
    @stdin.flush
  end

  def recv_message
    header_line = @stdout.gets
    return nil unless header_line

    content_length = header_line.match(/Content-Length: (\d+)/)[1].to_i

    # Skip a leading empty line
    @stdout.gets

    content = @stdout.read(content_length)
    JSON.parse(content)
  rescue => e
    puts "Failed to read message: #{e.message}"
    nil
  end

  def close_streams
    @stdin.close unless @stdin.closed?
    @stdout.close unless @stdout.closed?
    @stderr.close unless @stderr.closed?
  end
end
