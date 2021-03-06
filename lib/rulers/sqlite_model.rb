require "sqlite3"
require "rulers/util"

DB = SQLite3::Database.new "test.db"

module Rulers
  module Model
    def self.find(id)
      row = DB.execute <<SQL
  select #{schema.keys.join ","} from #{table}
  where id = #{id};
  SQL
      data = Hash[schema.keys.zip row [0]]
      self.new data
    end

    def [](name)
      @hash[name.to_s]
    end

    def []=(name, value)
      @hash[name.to_s] = value
    end

    class SQLite
      def intialize(data = nil)
        @hash = data
      end

      def self.to_sql(val)
        case val
        when Numeric
          val.to_s
        when String
          "'#{val}"
        end
      end

      def self.create(values)
        values.delete "id"
        keys = schema.keys - ["id"]
        vals = keys.map do |key|
          values[key] ? to_sql(values[key]) :
            "null"
        end

        DB.excute <<SQL
    INSERT INTO #{table} (#{keys.join ","})
      VALUES (#{vals.join ","});
    SQL
        data = Hash[keys.zip vals]
        sql = "SELECT last_insert_rowid();"
        data["id"] = DB.execute(sql)[0][0]
        self.new data
      end

      def self.count
        DB.execute(<<SQL)[0][0]
    SELECT COUNT(*) FROM #{table}
    SQL
      end


      def self.table
        Rulers.to_underscore name
      end

      def self.schema
        return @schema if @schema
        @schema = {}
        DB.table_info(table) do |row|
          @schema[row["name"]] = row["type"]
        end
        @schema
      end

      def save!
        unless @hash["id"]
          self.class.create
          return true
        end

        fields = @hash.map do |k, v|
          "#{k}=#{self.class.to_sql(v)}"
        end.join ","

        DB.execute <<SQL
    UPDATE #{self.class.table}
    SET #{fields}
    WHERE id = #{@hash["id"]}
    SQL
          true
        end

        def save
          self.save! rescue false
        end
      end
    end
  end
end
