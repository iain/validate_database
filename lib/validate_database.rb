module ValidateDatabase

  @@options = {
    :exclude => [:id, :created_at, :updated_at]
  }
  mattr_reader :options

  def self.included(base)
    base.extend ValidateDatabase::ClassMethods
    base.send(:include, ValidateDatabase::InstanceMethods)
  end

  module ClassMethods

    # Add validations according to your database, checking for type, limit and null.
    # Specify specific columns to validate only them, or use the :all, :except way
    # to exclude just some of them.
    #
    #   class Post < ActiveRecord::Base
    #     validates_according_to_database :all, :except => :person_id
    #   end
    #
    #   class User < ActiveRecord::Base
    #     validates_according_to_database :birthday
    #   end
    #
    # Note: id, created_at and updated_at are automatically excluded from any
    # validation, because that will break Rails.
    def validates_according_to_database(*args)
      send(:validate, :database_validation) unless registered_database_validations
      register_database_validations(args)
    end

    def register_database_validations(args)
      @registered_database_validations = args 
    end

    def registered_database_validations
      @registered_database_validations
    end

  end

  module InstanceMethods

    def database_validation
      database_validation_columns.each do |column|
        validate_presence(column) unless column.null
        may_allow_blank(column) do |value|
          validate_limit(column, value)         if column.limit
          validate_numericality(column, value)  if column.number?
          validate_date(column, value)          if column.type == :date
          validate_datetime(column, value)      if column.type == :datetime
          validate_time(column, value)          if column.type == :time
        end
      end
    end

    def database_validation_columns
      columns = self.class.registered_database_validations
      config = {}
      config = columns.last if columns.last.is_a?(Hash)
      if columns.first == :all
        method = :reject
        source = [*config[:except]].map(&:to_s)
      else
        method = :select
        source = columns.map(&:to_s)
      end
      default_excludes = ValidateDatabase.options[:exclude].map(&:to_s)
      self.class.columns.send(method) do |column|
        source.include?(column.name)
      end.reject do |column|
        default_excludes.include?(column.name)
      end
    end

    def validate_presence(column)
      errors.add(column.name, :blank) if send(column.name.to_sym).blank?
    end

    def validate_limit(column, value)
      errors.add(column.name, :too_long, :count => column.limit, :value => value) if value.to_s.size > column.limit
    end

    def validate_numericality(column, value)
      if column.type == :integer
        errors.add(column.name, :not_a_number, :value => value) unless value.to_s =~ /\A[+-]?\d+\Z/
      else
        begin
          Kernel.Float(value)
        rescue ArgumentError, TypeError
          errors.add(column.name, :not_a_number, :value => value)
        end
      end
    end

    def validate_time(column, value)
      value.to_time rescue errors.add(column.name, :not_a_time, :value => value)
    end

    def validate_date(column, value)
      value.to_date rescue errors.add(column.name, :not_a_date, :value => value)
    end

    def validate_datetime(column, value)
      value.to_datetime rescue errors.add(column.name, :not_a_datetime, :value => value)
    end

    def may_allow_blank(column)
      value = send(column.name.to_sym)
      yield(value) unless value.blank? and column.null
    end

  end

end
