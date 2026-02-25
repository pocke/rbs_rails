require 'test_helper'

class PostgreSQLArrayColumnTest < Minitest::Test
  def test_column_type_to_class_returns_array_type_for_postgresql_varchar_array_column
    # Simulates a PostgreSQL varchar[] column - col.type is :string, col.array? is true
    array_column = create_mock_column(name: 'tags', type: :string, null: true, array: true)

    generator = RbsRails::ActiveRecord::Generator.allocate
    result = generator.send(:column_type_to_class, array_column)

    assert_equal '::Array[::String]', result
  end

  def test_column_type_to_class_returns_array_type_for_integer_array
    array_column = create_mock_column(name: 'ids', type: :integer, null: false, array: true)

    generator = RbsRails::ActiveRecord::Generator.allocate
    result = generator.send(:column_type_to_class, array_column)

    assert_equal '::Array[::Integer]', result
  end

  def test_column_type_to_class_returns_simple_type_for_non_array_column
    column = create_mock_column(name: 'name', type: :string, null: true, array: false)

    generator = RbsRails::ActiveRecord::Generator.allocate
    result = generator.send(:column_type_to_class, column)

    assert_equal '::String', result
  end

  def test_column_array_type_detection
    array_column = create_mock_column(name: 'tags', type: :string, null: true, array: true)
    regular_column = create_mock_column(name: 'name', type: :string, null: true, array: false)

    generator = RbsRails::ActiveRecord::Generator.allocate

    assert generator.send(:column_array_type?, array_column)
    refute generator.send(:column_array_type?, regular_column)
  end

  def test_generated_rbs_lists_array_column_as_array_type
    # Full integration test: when a model has a PostgreSQL array column,
    # the generated RBS should declare that column as array type (e.g. ::Array[::String])
    # This test verifies the logic by testing the column_type_to_class output
    # which is what gets embedded in the RBS for array columns.
    array_column = create_mock_column(name: 'tags', type: :string, null: true, array: true)

    generator = RbsRails::ActiveRecord::Generator.allocate
    rbs_type = generator.send(:column_type_to_class, array_column)

    assert_equal '::Array[::String]', rbs_type,
      'PostgreSQL varchar[] column must generate ::Array[::String] in RBS, not ::String'
  end

  private

  def create_mock_column(name:, type:, null:, array:)
    col = Object.new
    col.define_singleton_method(:name) { name }
    col.define_singleton_method(:type) { type }
    col.define_singleton_method(:null) { null }
    col.define_singleton_method(:array?) { array }
    col
  end
end
