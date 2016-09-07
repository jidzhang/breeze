<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="java.util.*"%>
<%@ page import="java.io.*"%>
<%@page import="com.breeze.framwork.databus.BreezeContext"%>
<%@page import="com.breezefw.service.cms.CmsIniter"%>
<%@page import="com.breeze.framwork.netserver.tool.ContextMgr"%>
<%@page import="com.breeze.support.tools.*"%>
<%@page import="com.breeze.support.cfg.*"%>
<%@page import="java.util.regex.*"%>
<%@ page import="java.util.*"%>
<%
	BreezeContext password4tools = ContextMgr.global.getContextByPath(CmsIniter.CMSPARAMPRIFIX);
	String rightkey = "1qaz@WSX";
	
	if(password4tools != null && !password4tools.isNull() && password4tools.getContext("password4tools")!=null && !password4tools.getContext("password4tools").isNull()){
		if(!password4tools.getContext("password4tools").getData().toString().equals("--")){
			rightkey = password4tools.getContext("password4tools").getData().toString();	
		}
	}

	boolean needLogin = true;
	if (session.getAttribute("login") != null) {
		needLogin = false;
	} else {
		String password = request.getParameter("password");
		if (rightkey.equals(password)) {
			session.setAttribute("login", true);
			needLogin = false;
		}else{
			session.removeAttribute("login");
		}
	}
%>
<%  if (needLogin){ %>
	<form method="post">
		请输入密码<input name="password" type="password"><br /> <input
			type="submit" value="ok">
	</form>
<%
      return;
    }
    //如果有url则直接返回
    Object backurl = session.getAttribute("backurl");
    if (backurl != null){
    	response.sendRedirect(backurl.toString());
    	session.removeAttribute("backurl");
    	return;
    }

%>
<%
    response.sendRedirect("./page/framework/main.jsp");
%>