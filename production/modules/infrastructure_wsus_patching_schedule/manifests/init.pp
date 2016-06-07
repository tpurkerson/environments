# Patch Servers Monthly

class infrastructure_wsus_patching_schedule {

  require windows::filesystem::variousdirectories # needs e:\apps

  #node targeting
  $prefix = hiera("packageloc::${::domain}")
  $wsusblacklist = hiera('windows::wsus::blacklist_nodes')

  $wsus_host = downcase($::hostname)
  $wsus_host_length = size($wsus_host)
  $wsus_host_terminal_char = $wsus_host[$wsus_host_length -1, 1]

  #bad named nodes cannot match terminal character in name as even or odd so assign to even
  if($wsus_host_terminal_char !~ /^[0-9]$/)
  {
    $wsus_node_modulo = 0
  }
  else
  {
    $wsus_node_modulo = $wsus_host_terminal_char % 2
  }


  if (hiera('windows::wsus::implemenation::blockodd',false) and $wsus_node_modulo == 1)
  {
    $this_node_blocked = true
  }
  elsif (hiera('windows::wsus::implemenation::blockeven',false) and $wsus_node_modulo == 0)
  {
    $this_node_blocked = true
  }
  elsif (member($wsusblacklist,$::clientcert))
  {
    $this_node_blocked = true
  }
  else
  {
    $this_node_blocked = false
  }

  if($this_node_blocked)
  {
    #remove job - node is blocked
    scheduled_task { 'PUPPET SCHEDULED - Microsoft Patch Installation':
      ensure      => 'absent',
    }
  }
  else
  {
    $hostdept = $wsus_host[0,3]

    $wsus_patch_offset = hiera("windows::wsus::${hostdept}::${wsus_node_modulo}::offset",26)

    #default sunday, day of week 0-6
    $wsus_patch_desired_day = hiera('windows::wsus::desired_day_number',0)

    $target_date_string = windows_patch_target_date($wsus_patch_offset,$wsus_patch_desired_day)

    notify{ "offset from hiera: ${wsus_patch_offset}": }
    notify{ "host deparment: ${hostdept}": }
    notify{ "desired weekday: ${wsus_patch_desired_day}": }
    notify{ "this node blocked? : ${this_node_blocked}": }
    notify{ "function determined start date: ${target_date_string}": }

    file { 'e:\Apps\wsus_patching\patch_server.ps1':
      ensure             => 'file',
      replace            => true,
      source             => "\\\\${prefix}\\scripts\\infrastructure\\wsus\\patch_server.ps1",
      source_permissions => ignore,
      require            => File['e:\Apps\wsus_patching'],
    }

    #need to work on the powershell script, we need a wsus server built and we need the schedule mapped out by naming convention.
    # naming convetion should go in hiera with a variable here.
    scheduled_task { 'PUPPET SCHEDULED - Microsoft Patch Installation':
      ensure      => 'present',
      command     => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe',
      arguments   => "&\'E:\\Apps\\wsus_patching\\patch_server.ps1'",
      working_dir => 'E:\Apps\wsus_patching',
      user        => 'system',
      enabled     => true,
      trigger     => [{
        'every'            => hiera('windows::wsus::schedule_repeat_max_cap',38),
        'schedule'         => 'daily',
        'start_date'       => $target_date_string,
        'start_time'       => hiera('windows::wsus::desired_run_time','08:00'),
      }
      ],
      require     => File['e:\Apps\wsus_patching\patch_server.ps1'],
    }
  }

}

