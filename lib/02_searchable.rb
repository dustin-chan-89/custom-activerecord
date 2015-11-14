require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_clause = []
    values = []
    params.each do |column, value|
      where_clause << "#{column} = ?"
      values << value
    end

    if values.size > 1
      hsh = DBConnection.execute(<<-SQL, *values)
        SELECT*
        FROM #{self.table_name}
        WHERE #{where_clause.join(' AND ')}
      SQL
    else

      hsh =DBConnection.execute(<<-SQL, params.values[0])
        SELECT *
        FROM #{self.table_name}
        WHERE #{params.keys[0]} = ?
      SQL
    end
    self.parse_all(hsh)
  end
end

class SQLObject
  extend Searchable
end
