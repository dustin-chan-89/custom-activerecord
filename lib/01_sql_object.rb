require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    query = DBConnection.execute2(<<-SQL)
      SELECT *
      FROM #{self.table_name}
    SQL

    query.first.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |column|
      define_method(column) do
        attributes[column]
      end

      define_method("#{column}=") do |value|
        attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    return "#{self}".tableize if @table_name.nil?
    @table_name
  end

  def self.all
    query = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{self.table_name}
    SQL

    query.map do |obj|
      self.new(obj)
    end
  end

  def self.parse_all(results)
    results.map do |obj|
      self.new(obj)
    end
  end

  def self.find(id)
    all[id - 1]
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      if !self.class::columns.include?(attr_name.to_sym)
        raise "unknown attribute '#{attr_name}'"
      else
        self.send "#{attr_name}=".to_sym, value
      end
    end
  end


  def attributes
    @attributes ||= {}
  end

  def attribute_values
    values = []
    self.class::columns.each do |col|
       values << (self.send "#{col}".to_sym)
    end
    values
  end

  def insert

    col_names = self.class.columns[1..-1].join(', ')
    question_marks = []
    (self.class.columns.size-1).times do
      question_marks << '?'
    end

    question_marks = question_marks.join(', ')
    args = attribute_values[1..-1]
    query = DBConnection.execute(<<-SQL, *args)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    set = self.class.columns[1..-1].map do |col|
      col = "#{col} = ?"
    end
    set = set.join(', ')

    DBConnection.execute(<<-SQL, *attribute_values[1..-1])
      UPDATE
        #{self.class.table_name}
      SET
        #{set}
      WHERE
        id = #{self.id}
    SQL
  end

  def save
    if id.nil?
      insert
    else
      update
    end
  end
end
