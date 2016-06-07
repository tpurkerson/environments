require 'spec_helper_acceptance'
require 'securerandom'

host = find_only_one("sql_host")

describe "Test sqlserver::database", :node => host do

  def ensure_sqlserver_database(host, pp)
    apply_manifest_on(host, pp) do |r|
      expect(r.stderr).not_to match(/Error/i)
    end
  end

  #Return options for run_sql_query
  def run_sql_query_opts (query, expected_row_count)
    run_sql_query_opt = {
        :query => query,
        :sql_admin_user => 'sa',
        :sql_admin_pass => 'Pupp3t1@',
        :expected_row_count => expected_row_count,
    }
  end

  context "Start testing...", {:testrail => ['89019', '89076', '89077', '89078', '89079', '89080', '89081']} do

    before(:each) do
      @db_name = ("DB" + SecureRandom.hex(4)).upcase
      @table_name = 'Tables_' + SecureRandom.hex(3)
    end

    after(:each) do

      # delete created database:

      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
        }
        sqlserver::database{'#{@db_name}':
          ensure  => 'absent',
        }
      MANIFEST
      #comment out the below line because of ticket MODULES-2554.
      #ensure_sqlserver_database(host, pp)
    end

    it "Test Case C89019: Create a database" do
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
        }
        sqlserver::database{'#{@db_name}':
        }
        sqlserver_tsql{'testsqlserver_tsql':
          instance => 'MSSQLSERVER',
          database => '#{@db_name}',
          command => "CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
          require => Sqlserver::Database['#{@db_name}'],
        }
      MANIFEST
      ensure_sqlserver_database(host, pp)

      puts "Validate the Database '#{@db_name}' and table '#{@table_name}' are successfully created:"
      query = "USE #{@db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"
      run_sql_query(host, run_sql_query_opts(query, 1))
    end

    it "Test Case C89076: Create database with optional collation_name" do
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
        }
        sqlserver::database{'#{@db_name}':
          collation_name => 'SQL_Estonian_CP1257_CS_AS',
        }
        sqlserver_tsql{'testsqlserver_tsql':
          instance => 'MSSQLSERVER',
          database => '#{@db_name}',
          command => "CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
          require => Sqlserver::Database['#{@db_name}'],
        }
      MANIFEST
      ensure_sqlserver_database(host, pp)

      puts "Validate that a table can be created in the database:"
      query = "USE #{@db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"
      run_sql_query(host, run_sql_query_opts(query, 1))

      puts "validate the Database '#{@db_name}' has correct collation name:"
      query = "SELECT name AS Database_Name, collation_name
                FROM sys.databases
                WHERE name = '#{@db_name}'
                AND collation_name = 'SQL_Estonian_CP1257_CS_AS';"

      run_sql_query(host, run_sql_query_opts(query, 1))
    end

    it "Test Case C89077: Create database with optional compatibility" do
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
        }
        sqlserver::database{'#{@db_name}':
          compatibility => 100,
        }
        sqlserver_tsql{'testsqlserver_tsql':
          instance => 'MSSQLSERVER',
          database => '#{@db_name}',
          command => "CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
          require => Sqlserver::Database['#{@db_name}'],
        }
      MANIFEST
      ensure_sqlserver_database(host, pp)

      puts "Validate that a table can be created in the database:"
      query = "USE #{@db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"
      run_sql_query(host, run_sql_query_opts(query, 1))

      puts "validate the Database '#{@db_name}' has correct compatibility level:"
      query = "SELECT name AS Database_Name, compatibility_level
                FROM sys.databases
                WHERE name = '#{@db_name}'
                AND compatibility_level = '100';"

      run_sql_query(host, run_sql_query_opts(query, 1))
    end

    it "Test Case C89078: Create database with optional containment" do
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user   => 'sa',
          admin_pass   => 'Pupp3t1@',
        }
        sqlserver::sp_configure{ 'sp_config4db':
          config_name   => 'contained database authentication',
          value         => 1,
          reconfigure   => true,
          instance      => 'MSSQLSERVER',
        }
        sqlserver::database{ '#{@db_name}':
          containment => 'PARTIAL',
          require     => Sqlserver::Sp_configure['sp_config4db']
        }
        sqlserver_tsql{'testsqlserver_tsql':
            instance => 'MSSQLSERVER',
            database => '#{@db_name}',
            command => "CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
            require => Sqlserver::Database['#{@db_name}'],
        }
      MANIFEST
      ensure_sqlserver_database(host, pp)

      puts "Validate that a table can be created in the database:"
      query = "USE #{@db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"
      run_sql_query(host, run_sql_query_opts(query, 1))

      puts "validate the Database '#{@db_name}' has correct containment:"
      query = "SELECT name AS Database_Name, containment_desc
                FROM sys.databases
                WHERE name = '#{@db_name}'
                AND containment_desc = 'PARTIAL';"

      run_sql_query(host, run_sql_query_opts(query, 1))
    end

    it "Test Case C89079: Create database with optional db_chaining" do
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user   => 'sa',
          admin_pass   => 'Pupp3t1@',
        }
        sqlserver::sp_configure{ 'sp_config4db':
          config_name   => 'contained database authentication',
          value         => 1,
          reconfigure   => true,
          instance      => 'MSSQLSERVER',
        }
        sqlserver::database{ '#{@db_name}':
          containment => 'PARTIAL',
          db_chaining => 'ON',
          require     => Sqlserver::Sp_configure['sp_config4db']
        }
        sqlserver_tsql{'testsqlserver_tsql':
            instance => 'MSSQLSERVER',
            database => '#{@db_name}',
            command => "CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
            require => Sqlserver::Database['#{@db_name}'],
        }
      MANIFEST
      ensure_sqlserver_database(host, pp)

      puts "Validate that a table can be created in the database:"
      query = "USE #{@db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"
      run_sql_query(host, run_sql_query_opts(query, 1))

      puts "validate the Database '#{@db_name}' has correct db_chaing setting:"
      query = "SELECT name AS Database_Name, is_db_chaining_on
                FROM sys.databases
                WHERE name = '#{@db_name}'
                AND is_db_chaining_on = '1';"

      run_sql_query(host, run_sql_query_opts(query, 1))
    end

    it "Test Case C89080: Create database with optional default_fulltext_language" do
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user   => 'sa',
          admin_pass   => 'Pupp3t1@',
        }
        sqlserver::sp_configure{ 'sp_config4db':
          config_name   => 'contained database authentication',
          value         => 1,
          reconfigure   => true,
          instance      => 'MSSQLSERVER',
        }
        sqlserver::database{ '#{@db_name}':
          containment                 => 'PARTIAL',
          default_fulltext_language   => 'Japanese',
          require                     => Sqlserver::Sp_configure['sp_config4db']
        }
        sqlserver_tsql{'testsqlserver_tsql':
            instance => 'MSSQLSERVER',
            database => '#{@db_name}',
            command => "CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
            require => Sqlserver::Database['#{@db_name}'],
        }
      MANIFEST
      ensure_sqlserver_database(host, pp)

      puts "Validate that a table can be created in the database:"
      query = "USE #{@db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"
      run_sql_query(host, run_sql_query_opts(query, 1))

      puts "validate the Database '#{@db_name}' has correct default_fulltext_language_name setting:"
      query = "SELECT name AS Database_Name, default_fulltext_language_name
                FROM sys.databases
                WHERE name = '#{@db_name}'
                AND default_fulltext_language_name = 'Japanese';"

      run_sql_query(host, run_sql_query_opts(query, 1))
    end

    it "Test Case C89081: Create database with optional default_language" do
      pp = <<-MANIFEST
        sqlserver::config{'MSSQLSERVER':
          admin_user   => 'sa',
          admin_pass   => 'Pupp3t1@',
        }
        sqlserver::sp_configure{ 'sp_config4db':
          config_name   => 'contained database authentication',
          value         => 1,
          reconfigure   => true,
          instance      => 'MSSQLSERVER',
        }
        sqlserver::database{ '#{@db_name}':
          containment        => 'PARTIAL',
          default_language   => 'Traditional Chinese',
          require            => Sqlserver::Sp_configure['sp_config4db']
        }
        sqlserver_tsql{'testsqlserver_tsql':
            instance => 'MSSQLSERVER',
            database => '#{@db_name}',
            command => "CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
            require => Sqlserver::Database['#{@db_name}'],
        }
      MANIFEST
      ensure_sqlserver_database(host, pp)

      puts "Validate that a table can be created in the database:"
      query = "USE #{@db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"
      run_sql_query(host, run_sql_query_opts(query, 1))

      puts "validate the Database '#{@db_name}' has correct default_language setting:"
      query = "SELECT name AS Database_Name, default_language_name
                FROM sys.databases
                WHERE name = '#{@db_name}'
                AND default_language_lcid = '1028';"

      run_sql_query(host, run_sql_query_opts(query, 1))
    end
  end
end
