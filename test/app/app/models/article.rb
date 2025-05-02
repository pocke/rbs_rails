class Article
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :blog_id, :integer
  attribute :title, :string
  attribute :body, :string
end
