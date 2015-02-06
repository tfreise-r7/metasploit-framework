# -*- coding: binary -*-

require 'shellwords'

module Msf
module Sessions
module MeterpreterOptions

  def initialize(info = {})
    super(info)

    register_advanced_options(
      [
        OptBool.new('AutoLoadStdapi', [true, "Automatically load the Stdapi extension", true]),
        OptString.new('InitialAutoRunScript', [false, "An initial script to run on session creation (before AutoRunScript)", '']),
        OptString.new('AutoRunScript', [false, "A script to run automatically on session creation.", '']),
        OptBool.new('AutoSystemInfo', [true, "Automatically capture system information on initialization.", true]),
        OptBool.new('EnableUnicodeEncoding', [true, "Automatically encode UTF-8 strings as hexadecimal", true]),
        OptPath.new('HandlerSSLCert', [false, "Path to a SSL certificate in unified PEM format, ignored for HTTP transports"])
      ], self.class)
  end

  #
  # Once a session is created, automatically load the stdapi extension if the
  # advanced option is set to true.
  #
  def on_session(session)
    super

    # Hand off to SessionManager, so that UI remains responsive
    Celluloid::Actor[:msf_session_manager_initializer_pool].async.start_session(
        auto_load_android: !!datastore['AutoLoadAndroid'],
        auto_load_stdapi: !!datastore['AutoLoadStdapi'],
        auto_run_script: datastore['AutoRunScript'],
        auto_system_info: !!datastore['AutoSystemInfo'],
        enable_unicode_encoding: !!datastore['EnableUnicodeEncoding'],
        initial_auto_run_script: datastore['InitialAutoRunScript'],
        session: session,
        user_input: user_input,
        user_output: user_output
    )
  end

end
end
end

