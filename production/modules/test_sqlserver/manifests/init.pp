class test_sqlserver {

# sqlserver::login{'PE-201612-AGENT\Administrator':
#   instance    => 'SQLEXPRESS',
#   login_type  => 'WINDOWS_LOGIN',
# }

sqlserver::config { 'SQLEXPRESS' :
#   admin_pass     =>  'Qu@lity!',
   admin_pass     =>  'Password123',
#   admin_user     =>  'Administrator',
   admin_user     =>  'sa',
#   require        => Sqlserver_instance[ 'SQLEXPRESS' ],
  }
# create database
sqlserver::database { 'mydatabase':
    instance   => 'SQLEXPRESS',
    db_name    => 'mydatabase',
  }
}
