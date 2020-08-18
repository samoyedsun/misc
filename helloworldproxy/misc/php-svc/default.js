function checkUser() {
    var userName = document.getElementById("user_inp").value;
    if (userName.length <= 0 || userName == "账号") {
        msgBox("用户名不能为空！");
        return false;
    }
    var passWord = document.getElementById("pass_inp").value;
    if (passWord.length <= 0 || passWord == "密码") {
        msgBox("密码不能为空！");
        return false;
    }
    return true;
}

function msgBox(msg) {
    layer.msg(msg);
}

function subPage(url) {
	var index = layer.open({
		  type: 2,
		  area: ['500px', '500px'],
		  skin: 'demo-class',
		  title: '配置信息',
		  content: url 
	});
	layer.full(index);
}

function create() {
    if (checkUser() == false) return;
    var userName = document.getElementById("user_inp").value;
    var passWord = document.getElementById("pass_inp").value;
    var reg = new RegExp(/^[a-zA-Z]{1}\w*$/);  
    if(!reg.test(userName)){
        msgBox("账号必须是以字母开头，且由字母、数字、下划线组成!");
        return 
    } 
    if(!reg.test(passWord)){
        msgBox("密码必须是以字母开头，且由字母、数字、下划线组成!");
        return
    }
    $.ajax({  
        type: 'POST',  
        url: 'create.php',  
        data:{  
            "username": userName,  
            "password": passWord
        },  
        success: function (data) {  
            var msg = JSON.parse(data);
            if (msg.code == 200)
                msgBox("注册成功!")
            else if (msg.code == 201)
                msgBox("用户已存在!")
            else
                msgBox("未知错误!");
        }  
    });
}

function jointCookie(p) {
    var s = "secret=" + window.btoa(p);
    var Days = 30;
    var exp = new Date(); 
    exp.setTime(exp.getTime() + Days*24*60*60*1000);
    return s + ";" + "expires=" + exp.toGMTString();
}

function setCookie(t) {
    var p = ""
    for (k in t)
        p = p + k + "=" + t[k] + "&";
    if (p.length > 0)
        p = p.substring(0, p.length - 1);
    document.cookie = jointCookie(p);
}

function filterCookie(c) {
    var start = c.search(/=/) + 1;
    var c = c.substring(start, c.length);
    var start = c.search(/;/);
    if (start < 0)
        return window.atob(c);
    var p = c.substring(start, 0);
    return window.atob(p);
}

function getCookie(){
    var s = filterCookie(document.cookie);
    var t = {}
    while(s.length > 0){
        var n = s.indexOf("&")
        if (n == -1)
            n = s.length
        var subs = s.substring(0, n);
        if (n == s.length)
            s = s.substring(n, s.length);
        else
            s = s.substring(n + 1, s.length);
        var n = subs.indexOf("=");
        var k = subs.substring(0, n);
        var v = subs.substring(n + 1, subs.length)
        t[k] = v
    }
    return t
}

function entry() {
    if (checkUser() == false) return;
    var userName = document.getElementById("user_inp").value;
    var passWord = document.getElementById("pass_inp").value;
    $.ajax({
        type: 'POST',
        url: 'entry.php',
        data:{
            "username": userName,
            "password": passWord
        },
        success: function (data) {
            var msg = JSON.parse(data);
            if (msg.code == 200) {
                msgBox("登陆成功!")
            }
            else if (msg.code == 202) {
                msgBox("用户不存在!")
                return
            }
            else if (msg.code == 203) {
                msgBox("密码错误!")
                return
            }
            else {
                msgBox("未知错误!")
                return
            }
            setCookie({
                "username": userName,
                "password": passWord
            });
            window.location.href = 'home.html';
        }
    });
}