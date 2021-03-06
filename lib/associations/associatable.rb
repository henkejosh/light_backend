require_relative 'assoc_options'
require_relative 'belongs_to_options'
require_relative 'has_many_options'
require 'active_support/inflector'

module Associatable
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      options = self.class.assoc_options[name]
      fk_val = self.send(options.foreign_key)

      options.model_class.where(options.primary_key => fk_val).first
    end
  end

  def has_many(name, options = {})
    self.assoc_options[name] =
        HasManyOptions.new(name, self.name, options)

    define_method(name) do
      options = self.class.assoc_options[name]

      fk_val = self.send(options.primary_key)

      options.model_class.where(options.foreign_key => fk_val)
    end
  end

  def assoc_options
    @assoc_options ||= {}
    @assoc_options
  end

  def has_one_through(name, through_name, source_name)

    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      table1 = through_options.table_name
      t1_join_key = source_options.foreign_key

      join_table = source_options.table_name
      jt_join_key = source_options.primary_key

      where_constraint = through_options.primary_key
      where_value = self.send(where_constraint)

      obj = DBConnection.execute(<<-SQL, where_value)
        select
          t2.*

        from
          #{table1} t
        join
          #{join_table} t2
          on t.#{t1_join_key} = t2.#{jt_join_key}

        where
          t.#{where_constraint} = ?
      SQL
      source_options.model_class.parse_all(obj).first
    end
  end
end

# TODO!! -- Extensions
# Extension Ideas
# Write 'where' so that it is lazy and stackable. Implement a Relation class.
# Validation methods/validator class.
# has_many :through
#   This should handle both belongs_to => has_many and has_many => belongs_to.
# Write an includes method that does pre-fetching.
# joins
