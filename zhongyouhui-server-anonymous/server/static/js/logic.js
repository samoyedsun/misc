var GAMESERVERHOST = window.location.host;
var banker_uid = 0;

function get_room_number(){
    
    var room_number = document.getElementById("room_number").value;
    if(!/^[0-9]*$/.test(room_number)){
        document.getElementById("field_recv").value = new Date().getTime() + "\n" + "format error:" + 1;
        return "";
    }
    if(room_number.length != 6){
        document.getElementById("field_recv").value = new Date().getTime() + "\n" + "format error:" + 2;
        return "";
    }
    return room_number;
}

function get_bet_slot_detail_list_by_bet_type(bet_detail_list, bet_type){
    for (var i = 0; i < bet_detail_list.length; i++){  
        if (bet_detail_list[i].bet_type == bet_type){
            return bet_detail_list[i].bet_slot_detail_list
        }
    }
}

function get_bet_slot_amount(bet_slot_detail_list, slot){
    for (var i = 0; i < bet_slot_detail_list.length; i++){
        if (bet_slot_detail_list[i].slot_list[0] == slot){
            return bet_slot_detail_list[i].amount;
        }
    }
    return 0;
}

function fill_tbody(room_bet_detail_list){
    var objtable=document.getElementById("bet_detail_list");
    var row_num=objtable.rows.length;
    for (i=0;i<row_num;i++)
    {
        objtable.deleteRow(i);
        row_num=row_num-1;
        i=i-1;
    }
    room_bet_detail_list.forEach(v=>{  
        var uid = v.uid;
        var total_score = v.total_score;
        var nick_name = v.nick_name;
        var bet_detail_list = v.bet_detail_list;
        var bet_slot_detail_list = get_bet_slot_detail_list_by_bet_type(bet_detail_list, 1);

        var td_uid=document.createElement("td");
        td_uid.innerText= "" + uid;
        var td_total_score=document.createElement("td");
        td_total_score.innerText= "" + total_score;
        var td_nick_name=document.createElement("td");
        td_nick_name.innerText= "" + nick_name;
        var td_bet_slot_1=document.createElement("td");
        td_bet_slot_1.innerText= get_bet_slot_amount(bet_slot_detail_list, 1);
        var td_bet_slot_2=document.createElement("td");
        td_bet_slot_2.innerText= get_bet_slot_amount(bet_slot_detail_list, 2);
        var td_bet_slot_3=document.createElement("td");
        td_bet_slot_3.innerText= get_bet_slot_amount(bet_slot_detail_list, 3);
        var td_bet_slot_4=document.createElement("td");
        td_bet_slot_4.innerText= get_bet_slot_amount(bet_slot_detail_list, 4);
        var td_bet_slot_5=document.createElement("td");
        td_bet_slot_5.innerText= get_bet_slot_amount(bet_slot_detail_list, 5);
        var td_bet_slot_6=document.createElement("td");
        td_bet_slot_6.innerText= get_bet_slot_amount(bet_slot_detail_list, 6);
        

        var tr=document.createElement("tr");

        tr.appendChild(td_uid);
        tr.appendChild(td_total_score);
        tr.appendChild(td_nick_name);
        tr.appendChild(td_bet_slot_1);
        tr.appendChild(td_bet_slot_2);
        tr.appendChild(td_bet_slot_3);
        tr.appendChild(td_bet_slot_4);
        tr.appendChild(td_bet_slot_5);
        tr.appendChild(td_bet_slot_6);
        
        objtable.appendChild(tr);
    });
}

function anonymous(w){

    if (banker_uid == 0){
        document.getElementById("field_recv").value = new Date().getTime() + "\n" + "operate error";
        return 0;
    }

    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if ( xhr.readyState == 4 ){
            if ( ( xhr.status >= 200 && xhr.status < 300 ) || xhr.status == 304 ) {
                document.getElementById("field_recv").value = new Date().getTime() + "\n" + xhr.responseText;
            } else {
                document.getElementById("field_recv").value = new Date().getTime() + "\n" + "network error!";
            }
        }
    }
    xhr.open('POST', "http://" + GAMESERVERHOST + "/game/anonymous", true );
    var data = JSON.stringify({
        uid : banker_uid,
        words : w
    });
    xhr.send(data);
}

var socket;

function start_monitor(){
    var room_number = get_room_number();
    if (room_number == ""){
        return 0;
    }

    socket = new Socket();
    socket.connect("ws://" + GAMESERVERHOST + "/ws");
    socket.on("onopen", function () {
        socket.request("user_auth", {
            uid : 10000000,
            token : "76491a8d530c11f397789e45bb7c5237a67f185e",
            platform : "website"
        }, function (args) {
            document.getElementById("field_recv").value = JSON.stringify(args);
            socket.request("room_anonymous_monitor", {
                room_number : room_number
            }, function (args) {
                if (args.code == 20000){
                    banker_uid = args.data.banker_uid;
                    var room_bet_detail_list = args.data.room_bet_detail_list;
                    var round_amount = args.data.round_amount;
                    var round_limit = args.data.round_limit;
                    fill_tbody(room_bet_detail_list)
                    document.getElementById("round_limit").innerText= round_limit;
                    document.getElementById("round_amount").innerText= round_amount;
                    document.getElementById("field_recv").value = "更新数据成功!";
                } else {
                    document.getElementById("field_recv").value = JSON.stringify(args);
                }
            });
        });
    });
    socket.on("on_room_anonymous_monitor", function (data) {
        var room_bet_detail_list = data.room_bet_detail_list;
        var round_amount = data.round_amount;
        var round_limit = data.round_limit;
        fill_tbody(room_bet_detail_list)
        document.getElementById("round_limit").innerText= round_limit;
        document.getElementById("round_amount").innerText= round_amount;
    });
}

function close_monitor(){
    socket.close()
    document.getElementById("field_recv").value = "监控通道已关闭!";
}