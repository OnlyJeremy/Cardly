Pod::Spec.new do |s|
  s.name             = 'Cardly'
  s.version          = '1.0.0'
  s.summary          = '高性能卡片堆叠容器 UI 组件'

  s.description      = <<-DESC
    Cardly 是一个高性能的卡片堆叠容器视图，
    灵感来自 Tinder 和 Koloda。

    特性：
    - 流畅的手势拖拽交互
    - 可配置的动画参数
    - 支持自定义 Overlay（LIKE/NOPE 效果）
    - 预加载和批量操作支持
    - 零第三方库依赖
  DESC

  s.homepage         = 'https://github.com/your-org/Cardly-iOS'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Your Organization' => 'contact@example.com' }
  s.source           = { :git => 'https://github.com/your-org/Cardly-iOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '14.0'
  s.swift_version = '5.0'

  s.source_files = 'Pod/Classes/**/*.swift'
end
