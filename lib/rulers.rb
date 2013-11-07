require "rulers/version"
require "rulers/routing"
require "rulers/util"
require "rulers/dependencies"
require "rulers/controller"
require "rulers/file_model"

module Rulers
  class Application
    def call(env)
      if env['PATH_INFO'] == '/favicon.ico'
        return [404,
          {'Content-Type' => 'text/html'}, []]
      end
      if env['PATH_INFO'] == '/'
        return [300, {"Location" => '/home/index'}, []]

      klass, act = get_controller_and_action(env)
      controller = klass.new(env)
      begin
        text = controller.send(act)
      rescue Exception => e
        text = e
      end
      [200, {'Content-Type' => 'text/html'},
        [text]]
      end
    end
  end
end
