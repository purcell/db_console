namespace :db do
  def find_cmd(*commands)
    commands.detect do |cmd|
      ENV['PATH'].split(File::PATH_SEPARATOR).detect do |path|
        File.executable? File.join(path, cmd)
      end
    end || raise("couldn't find matching executable: #{commands.join(', ')}")
  end

  namespace :console do
    YAML::load(File.read(RAILS_ROOT + "/config/database.yml")).each do |env, config|
      desc "Connect to the '#{env}' DB using a console tool"
      task env.to_sym do
        case config["adapter"]
        when "mysql"
          system(find_cmd(*%w(mysql5 mysql)),
                 '-u', config["username"],
                 "-p#{config["password"]}",
                 '-h', config["host"],
                 '--default-character-set', config["encoding"],
                 '-D', config["database"])
        when "postgresql"
          ENV['PGHOST']     = config["host"] if config["host"]
          ENV['PGPORT']     = config["port"].to_s if config["port"]
          ENV['PGPASSWORD'] = config["password"].to_s if config["password"]
          system(find_cmd('psql'), '-U', config["username"], config["database"])
        when "sqlite"
          system(find_cmd('sqlite'), config["dbfile"])
        when "sqlite3"
          system(find_cmd('sqlite3'), config["dbfile"])
        else raise "not supported for this database type"
        end
      end
    end
  end

  task :console do
    Rake::Task["db:console:" + (ENV['DB'] || RAILS_ENV || 'development')].invoke
  end
end
