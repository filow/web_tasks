require './lib/message.rb'

class MessageManager
  # 接受一个传入的目录参数，会把数据放在目录里面
  def initialize(dir)
    # 初始化一个信息列表
    @list = []
    @id = 0
    @dir = dir
    if Dir.exist?(dir)
      Dir.glob("#{dir}/*.json").each do |file|
        # 保证单个文件的损坏不会影响整体
        begin
          f = File.open(file)
          content = f.read
          msg = Message.from_json(content)
          if msg.id > @id
            @id = msg.id
          end
          # 用id作为键来存储，可以保证在访问时可以获得O(1)的访问效率，同时其他操作也都很方便
          @list[msg.id] = msg
        rescue Exception => e
          puts "文件#{file}的数据有误： #{e.message}"
        ensure
          # 要保证把文件关闭掉
          f.close
        end
      end
    else
      # 目录不存在的话就建立一个
      Dir.mkdir(dir)
    end

  end

  def add(author, message)
    msg = Message.new(id: @id+1, author: author.strip, message: message.strip)
    if @list[@id]
      if @list[@id].author == msg.author && @list[@id].message == msg.message
        raise "不能重复提交留言！"
      end
    end
    # 保证插入在前面，这样就不用重新排序了
    @list[msg.id] = msg
    # 要在实例化之后才能给@id+1,因为实例化可能失败
    @id += 1
    # 保存文件
    single_save(msg)
    # 最好返回这个实例，因为可能调用者会用到
    msg
  end

  # 保存单个message文件，以保证在服务器异常退出时主要数据不丢失
  def single_save(msg)
    File.open("#{@dir}/#{msg.id}.json", "w") do |f|
      f.print msg.to_json
    end
  end
  
  # 根据id来删除留言
  def delete(id)
    # 如果存在留言就删掉
    if @list[id]
      @list[id] = nil
      File.delete("#{@dir}/#{id}.json")
      return 1
    else
      return 0
    end
  end

  # 修改留言内容
  def edit(id, props={})
    id = id.to_i
    raise "id为#{id}的留言不存在！" if @list[id].nil?
    props.each do |k,v|
      if [:author, :message, :created_at].include?(k.to_sym)
        # 这里是动态调用属性赋值方法, 例如author=()
        key = k.to_s + '='
        @list[id].send(key.to_sym, v)
      end
    end
    # 有修改就赶紧保存
    single_save(@list[id])
    @list[id]
  end

  # 查询数据，会对多个条件做与操作
  def query(filter={})
    f = {}
    filter.each{|k,v| f[k.to_sym] = v}
    result = @list.reject do |x|
      # 因为是通过@list[id]来赋值的，所以可能会有一些nil值
      if x
        result = true
        # id必须完全匹配
        if f[:id]
          result &=  x.id == f[:id]
        end

        if f[:author]
          result &=  x.author.include?(f[:author])
        end

        # 包含字串就认为是真的
        if f[:message]
          result &=  x.message.include?(f[:message])
        end

        if f[:created_at]
          # 要接收一个2014-02-01这样的日期字符串
          time = x.created_at.strftime('%Y-%m-%d')
          result &=  f[:created_at] == time
        end
        # 因为用的是reject，所以要取反
        !result
      else
        !false
      end
    end
    # 这里没有优化排序这个行为
    result.reverse
  end

  # 快捷方法
  def all
    query({})
  end
end