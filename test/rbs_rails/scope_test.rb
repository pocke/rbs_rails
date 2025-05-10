require 'test_helper'
require 'active_record'

class ScopeTest < Minitest::Test
  def test_scope
    model = Class.new(ActiveRecord::Base) do
      extend RbsRails::ActiveRecord::Scope

      scope :all_kind_args, -> (type, m = 1, n = 1, *rest, x, k: 1,**untyped, &blk)  { all }
      scope :no_arg, -> ()  { all }
    end

    assert_equal [:all_kind_args, :no_arg], model.scope_definitions.keys
    assert_equal model.scope_definitions[:all_kind_args].parameters, [[:req, :type], [:opt, :m], [:opt, :n], [:rest, :rest], [:req, :x], [:key, :k], [:keyrest, :untyped], [:block, :blk]]
    assert_equal model.scope_definitions[:no_arg].parameters, []
  end
end
