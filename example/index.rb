require 'sinatra/base'
require 'erb'

require './lib/message.rb'
require './lib/message_manager.rb'

class App < Sinatra::Base
  # 在这里新建实例变量，可以在程序运行期间保持
  configure do
    set :msg, MessageManager.new('./datas')
  end
  # 然后每次运行前让@msg指向它就可以了
  before do
    @msg = settings.msg
  end
  get '/' do
    query = {}
    if params[:id] && !params[:id].empty?
      query[:id] = params[:id].to_i
    end
    if params[:author] && !params[:author].empty?
      query[:author] = params[:author]
    end
    if params[:created_at] && !params[:created_at].empty?
      query[:created_at] = params[:created_at]
    end

    @msg_list = @msg.query(query)

    erb :index
  end

  get '/add' do
    # 这是个偷懒的写法，最好应该是判断url来决定Tab的活动状态
    @active_nav = 'add'
    erb :add
  end

  post '/add' do
    @active_nav = 'add'
    # 添加过程中可能抛出异常
    begin
      @msg.add(params[:author], params[:message])
      redirect to('/')
    rescue Exception => e
      @message = {status: 'danger', desc: e.message}
      erb :add
    end

  end

  get '/:id/edit' do
    @item = @msg.query({id: params[:id].to_i})[0]
    erb :edit
  end

  post '/edit' do
    begin
      @msg.edit(params[:id], author: params[:author], message: params[:message])
      redirect to('/')
    rescue Exception => e
      @item = @msg.query({id: params[:id].to_i})[0]
      @message = {status: 'danger', desc: e.message}
      erb :edit
    end

  end

  get '/:id/delete' do
    id = params[:id].to_i
    @msg.delete(id)
    redirect to('/')
  end
  run!
end