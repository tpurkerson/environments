require 'spec_helper_acceptance'
require 'securerandom'
require 'erb'

host = find_only_one("sql_host")

# database name
db_name   = ("DB" + SecureRandom.hex(4)).upcase

#database user:
DB_LOGIN_USER   = "loginuser" + SecureRandom.hex(2)

describe "sqlserver_tsql test", :node => host do

  def ensure_sqlserver_database(host,db_name, ensure_val = 'present')
    pp = <<-MANIFEST
    sqlserver::config{'MSSQLSERVER':
      admin_user   => 'sa',
      admin_pass   => 'Pupp3t1@',
    }
    sqlserver::database{'#{db_name}':
        instance => 'MSSQLSERVER',
    }
    MANIFEST

    apply_manifest_on(host, pp) do |r|
      expect(r.stderr).not_to match(/Error/i)
    end
  end

  context "Test sqlserver_tsql", {:testrail => ['89024', '89025', '89026', '89068', '89069']} do

    before(:all) do
      # Create new database
      @table_name = 'Tables_' + SecureRandom.hex(3)
      @query = "USE #{db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"

      ensure_sqlserver_database(host, db_name)
    end

    after(:all) do
      # remove the newly created instance
      ensure_sqlserver_database(host, 'absent')
    end

    it "Run a simple tsql command via sqlserver_tsql:" do
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        instance_name => 'MSSQLSERVER',
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver_tsql{'testsqlserver_tsql':
        instance => 'MSSQLSERVER',
        database => '#{db_name}',
        command => "CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
      }
      MANIFEST
      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/Error/i)
      end

      puts "validate the result of tsql command and table #{@table_name} should be created:"
      run_sql_query_opts = {
          :query              => @query,
          :sql_admin_user     => @admin_user,
          :sql_admin_pass     => @admin_pass,
          :expected_row_count => 1,
      }
      run_sql_query(host, run_sql_query_opts)
    end

    it "Run sqlserver_tsql WITH onlyif is true:" do
      #Initilize a new table name:
      @table_name = 'Table_' + SecureRandom.hex(3)
      @query = "USE #{db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
          instance_name => 'MSSQLSERVER',
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
      }
      sqlserver_tsql{'testsqlserver_tsql':
          instance => 'MSSQLSERVER',
          database => '#{db_name}',
          command => "CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
          onlyif => "IF (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES) < 10000"
      }
      MANIFEST

      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/Error/i)
      end

      puts "Validate #{@table_name} is successfully created:"
      run_sql_query_opts = {
          :query              => @query,
          :sql_admin_user     => @admin_user,
          :sql_admin_pass     => @admin_pass,
          :expected_row_count => 1,
      }
      run_sql_query(host, run_sql_query_opts)
    end

    it "Run sqlserver_tsql WITH onlyif is false:" do
      #Initilize a new table name:
      @table_name = 'Table_' + SecureRandom.hex(3)
      @query = "USE #{db_name}; SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{@table_name}';"
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
          instance_name => 'MSSQLSERVER',
          admin_user    => 'sa',
          admin_pass    => 'Pupp3t1@',
      }
      sqlserver_tsql{'testsqlserver_tsql':
          instance => 'MSSQLSERVER',
          database => '#{db_name}',
          command => "CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
          onlyif => "IF (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES) > 10000
          THROW 5300, 'Too many tables', 10"
      }
      MANIFEST

      apply_manifest_on(host, pp) do |r|
        expect(r.stderr).not_to match(/Error/i)
      end

      puts "Validate #{@table_name} is NOT created:"
      run_sql_query_opts = {
          :query              => @query,
          :sql_admin_user     => @admin_user,
          :sql_admin_pass     => @admin_pass,
          :expected_row_count => 0,
      }
      run_sql_query(host, run_sql_query_opts)
    end

    it "Negative test: Run tsql with invalid command:" do
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        instance_name => 'MSSQLSERVER',
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver_tsql{'testsqlserver_tsql':
        instance => 'MSSQLSERVER',
        database => '#{db_name}',
        command => "invalid-tsql-command",
      }
      MANIFEST
      apply_manifest_on(host, pp, {:acceptable_exit_codes => [0,1]}) do |r|
        expect(r.stderr).to match(/Error/i)
      end
    end

    it "Negative test: Run tsql with non-existing database:" do
      @table_name = 'Table_' + SecureRandom.hex(3)
      pp = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        instance_name => 'MSSQLSERVER',
        admin_user    => 'sa',
        admin_pass    => 'Pupp3t1@',
      }
      sqlserver_tsql{'testsqlserver_tsql':
        instance => 'MSSQLSERVER',
        database => 'Non-Existing-Database',
        command => "CREATE TABLE #{@table_name} (id INT, name VARCHAR(20), email VARCHAR(20));",
      }
      MANIFEST
      apply_manifest_on(host, pp, {:acceptable_exit_codes => [0,1]}) do |r|
        expect(r.stderr).to match(/Error/i)
      end
    end
  end
end
