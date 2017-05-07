require 'active_record'

ActiveRecord::Base.establish_connection(
  adapter: ENV['DATABASE_ADAPTER'],
  host: "database_host",
  port: ENV['DATABASE_PORT'],
  username: ENV['DATABASE_USER'],
  password: "database_password"
)

ActiveRecord::Migration.verbose = false

begin
  retries = 0

  if ENV['DATABASE_ADAPTER'] == "mysql2"
    ActiveRecord::Base.connection.execute 'CREATE DATABASE IF NOT EXISTS test;'
    ActiveRecord::Base.connection.execute 'USE test;'
  end

  ActiveRecord::Base.connection.execute 'DROP TABLE IF EXISTS users;'
rescue => e
  if retries < 3
    puts e.message
    sleep 2 ** retries
    retry
  else
    raise
  end
end

ActiveRecord::Schema.define do
  create_table :users do |t|
    t.string :name
  end
end

class User < ActiveRecord::Base
end

User.create!(name: "root")
User.where(name: "root").first!

puts "Successfully used #{ENV['DATABASE_ADAPTER']} database!"
