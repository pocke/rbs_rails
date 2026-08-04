class User
  class PopularQuery
    class << self
      delegate :call, to: :new
    end

    def initialize(relation = User.all)
      @relation = relation
    end

    def call
      @relation.where(popular: true)
    end
  end
end
