require 'json'
class Message
  attr_reader :id, :author, :message, :created_at
  def initialize(attributes)
    # 由于某些时候key可能不是一个符号，所以这里统一转换过去
    attrs = {}
    attributes.each {|k,v| attrs[k.to_sym] = v}

    @id = validate(:id, attrs[:id])
    @author = validate(:author, attrs[:author])
    @message = validate(:message, attrs[:message])
    # 如果传入了created_at参数，就用传入的参数
    if attrs[:created_at]
      @created_at = validate(:created_at, attrs[:created_at])
    else
      @created_at = Time.now
    end
  end

  # 只需要在赋值前用这个函数验证一下就好
  def validate(key, value)
    key = key.to_sym
    case key
    when :id
      raise 'id的值应该为一个正整数' if value.to_i <= 0
      return value.to_i
    when :author
      raise '没有作者名' if value.nil?
      raise '作者的长度至少为2' if value.strip.length < 2
      return value.strip
    when :message
      raise '没有留言内容' if value.nil?
      raise '留言的长度至少为10' if value.strip.length < 10
      return value.strip
    when :created_at
      raise '修改时间的值不合法' if value.class != Time
      return value
    end
  end

  # 转化为json字符串
  def to_json
    obj = {
      id: @id,
      author: @author,
      message: @message,
      created_at: @created_at.to_i  # 因为直接转换过去的话会变成字符串，不太好处理
    }
    JSON.fast_generate(obj,indent: "  ",space: "\t",object_nl: "\n")
  end

  # 从json字符串新建一个message对象
  def self.from_json(json_document)
    obj = JSON.parse(json_document)
    # 必须用Time.at，这样才能正确的把时间戳解析回日期
    obj["created_at"] = Time.at(obj["created_at"])
    self.new(obj)
  end

  def id=(val)
    @id = validate(:id, val)
  end

  def author=(val)
    @author = validate(:author, val)
  end

  def message=(val)
    @message = validate(:message, val)
  end

  def created_at=(val)
    @created_at = validate(:created_at, val)
  end
end