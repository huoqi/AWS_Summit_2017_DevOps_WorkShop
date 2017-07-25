<%@ page import="java.net.InetAddress" %>
<%@page contentType="text/html;charset=utf-8"%>
<html>
<head>
  <title>Hello, AWS 2017 Summit!</title>
</head>
<body>
  <h2>Hello, AWS 2017 Summit!</h2>
  <p>
    <span>Version 2017.07.25-16:18</span>
    <br/>
    <span>Server: <%=InetAddress.getLocalHost().getHostAddress()%></span>
  </p>
</body>
</html>
