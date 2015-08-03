require 'sinatra'
require 'erb'

require './lib/message.rb'
require './lib/message_manager.rb'

class App < Sinatra::Application
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

    p query
    @msg_list = @msg.query(query)

    erb :index
  end

  get '/add' do
    @active_nav = 'add'
    erb :add
  end

  run!
end