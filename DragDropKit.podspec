Pod::Spec.new do |s|

  s.name = 'DragDropKit'
  s.version = '0.1'
  s.summary = 'DragDropKit'

  s.homepage = 'https://github.com/Jiar/DragDropKit'
  s.license = { :type => "Apache-2.0", :file => "LICENSE" }

  s.author = { "Jiar" => "jiar.world@gmail.com" }

  s.ios.deployment_target = '8.0'

  s.source = { :git => "https://github.com/Jiar/DragDropKit.git", :tag => "#{s.version}" }
  s.source_files = 'DragDropKit/*.swift'

  s.module_name = 'DragDropKit'
  s.requires_arc = true

  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.0' }
  s.static_framework = true
  
end
