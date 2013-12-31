module Ohm
  # Provides support for soft deletion.
  #
  #   class Post < Ohm::Model
  #     include Ohm::SoftDelete
  #
  #     attribute :title
  #     index :title
  #   end
  #
  #   post = Post.create(title: 'Title')
  #
  #   post.deleted?
  #   # => false
  #
  #   post.delete
  #
  #   post.deleted?
  #   # => true
  #
  #   Post.all.empty?
  #   # => true
  #
  #   Post.find(title: 'Title').include?(post)
  #   # => true
  #
  #   Post.exists?(post.id)
  #   # => true
  #
  #   post = Post[post.id]
  #
  #   post.deleted?
  #   # => true
  #
  module SoftDelete
    DELETED_FLAG = "1"

    def self.included(model)
      model.attribute :deleted

      model.extend ClassMethods
    end

    def delete
      redis.queue("MULTI")
      redis.queue("SREM", model.all.key, id)
      redis.queue("SADD", model.deleted.key, id)
      redis.queue("HSET", key, :deleted, DELETED_FLAG)
      redis.queue("EXEC")
      redis.commit

      self.deleted = DELETED_FLAG

      self
    end

    def restore
      redis.queue("MULTI")
      redis.queue("SADD", model.all.key, id)
      redis.queue("SREM", model.deleted.key, id)
      redis.queue("HDEL", key, :deleted)
      redis.queue("EXEC")
      redis.commit

      self.deleted = nil

      self
    end

    def deleted?
      deleted == DELETED_FLAG
    end

    module ClassMethods
      def deleted
        Set.new(key[:deleted], key, self)
      end

      def exists?(id)
        super || deleted.exists?(id)
      end
    end
  end
end
