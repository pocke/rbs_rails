class Book
  class Money
    attr_reader :price, :currency_code

    def initialize(price, currency_code)
      @price = price
      @currency_code = currency_code
    end

    def ==(other)
      price == other.price && currency_code == other.currency_code
    end

    alias to_i price

    CURRENCIES = {
      'jpy' => '¥',
      'usd' => '$',
      'eur' => '€'
    }.freeze

    def to_s
      "#{CURRENCIES.fetch(currency_code)}#{price}"
    end
  end
end
