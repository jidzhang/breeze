# 一个为后端程序员度身定制的前端webMVC框架，只为后端程序员用的顺手
Breezejs是一个轻量级的前端MVC框架，其特点：
1.前后端分离彻底，采用seajs，一个模块一个文件，模块划分清晰，非常便于维护
2.和其他模型不同，BreezeJs模拟后端的面向对象的结构，有类(gadget)有实例(app)，公有方法，私有方法。这使得
  从后端转入前端的人用起来，得心应手。
# 资源
本组件由深圳市众联无限技术有限公司提供。
详细的资料参见：http://www.joinlinking.com/page/product/list.jsp?type=BreezeJs#
# 其他
Breeze由众联无限技术有限公司提供完整版本，框架是包含了后端BreezeJs还有基于BreezeJs以及BreezeJava的一个数据管理框架BreezeCMS。
欢迎到http://www.joinlinking.com/page/product/list.jsp?type=BreezeJs#上下载使用。
而，由此平台，我们构建了一个项目众包平台，我们的项目众包非常特殊，通过框架将项目拆分成小任务，然后再分发。
所以，众包都是3到4天的小任务，想做就做，也欢迎大家注册加入
http://weima.joinlinking.com/page/stylepc/frontcms/index.jsp
我们的官方qq群是：437239918
有如果发现问题，请联系我logan@joinlinking.com或在git上提问
#修订记录
2016-09-18
版本1.56
修复lang去form表单的功能，可以支持无限极表达。另外show方法支持第四个参数，即jquery的显示特效
这是一个激动人心的版本，show方法的特效使得页面的显示效果越来越好
2016-08-09
修改了threadSignal的日志模式条件
2016-09-18
增加了向后台发送模拟消息的方法，类似可以从客户端提交日志到服务端
2016-08-27 v1.50
修改Breeze中的蒙板层实现，使其可以有默认的高度，并且去掉waiting的鼠标指针模式
2016-08-18 v1.49
修改模板函数${xxx}的一个bug，能在{}中使用有()的表达式了
