local skynet = require "skynet"

local logpath = skynet.getenv("logpath")
local logmode = skynet.getenv("logmode")
local target_type_console = "console"
local target_type_date_file = "date_file"
local parse_type = "pattern"
local parse_statement = "[%d] [%p] [%c] %i %m%n"

local appenders = {}
local append_to_appenders = function(type, category, name)
    if type == target_type_console then
        table.insert(appenders, {
            type = target_type_console,
            category = category,
            level = logmode,
            layout = { type = parse_type, pattern = parse_statement }
        })
    else
        table.insert(appenders, {
            type = target_type_date_file,
            category = category,
            pattern = logpath .. (name or category) .. "-%Y-%m-%d.log",
            level = logmode,
            layout = { type = parse_type, pattern = parse_statement }
        })
    end
end

append_to_appenders(target_type_console, ".*")
append_to_appenders(target_type_date_file, "srv_web_agent")
append_to_appenders(target_type_date_file, "srv_redis_sup")
append_to_appenders(target_type_date_file, "srv_register")
append_to_appenders(target_type_date_file, "srv_mysql_sup")
append_to_appenders(target_type_date_file, "srv_redis")
append_to_appenders(target_type_date_file, "srv_socket")
append_to_appenders(target_type_date_file, "srv_mysql")
append_to_appenders(target_type_date_file, "srv_socket_agent")

append_to_appenders(target_type_date_file, "server_lualib_state_machine")
append_to_appenders(target_type_date_file, "server_lualib_seat_mgr")
append_to_appenders(target_type_date_file, "server_lualib_room")
append_to_appenders(target_type_date_file, "server_lualib_room_helper")
append_to_appenders(target_type_date_file, "server_lualib_logon_helper")
append_to_appenders(target_type_date_file, "server_lualib_club_helper")
append_to_appenders(target_type_date_file, "server_lualib_block_helper")
append_to_appenders(target_type_date_file, "server_lualib_misc_helper")
append_to_appenders(target_type_date_file, "server_frontend_request_socket_user")
append_to_appenders(target_type_date_file, "server_frontend_request_socket_room")
append_to_appenders(target_type_date_file, "server_frontend_request_socket_game")
append_to_appenders(target_type_date_file, "server_frontend_request_socket_club")
append_to_appenders(target_type_date_file, "server_frontend_request_web_user")
append_to_appenders(target_type_date_file, "server_frontend_request_web_gate")
append_to_appenders(target_type_date_file, "server_frontend_request_web_game")
append_to_appenders(target_type_date_file, "server_frontend_socketapp")
append_to_appenders(target_type_date_file, "server_frontend_socketproto")
append_to_appenders(target_type_date_file, "server_frontend_webapp")
append_to_appenders(target_type_date_file, "server_frontend_wsapp")

append_to_appenders(target_type_date_file, "server_backend_webapp")
append_to_appenders(target_type_date_file, "server_backend_request_web_room")
append_to_appenders(target_type_date_file, "server_backend_request_web_gate")

append_to_appenders(target_type_date_file, "server_common_wechat_tokens_db")
append_to_appenders(target_type_date_file, "server_common_init_db")
append_to_appenders(target_type_date_file, "server_common_http_util")
append_to_appenders(target_type_date_file, "server_common_hotfix_util")
append_to_appenders(target_type_date_file, "server_common_game_users_db")
append_to_appenders(target_type_date_file, "server_common_game_rooms_db")
append_to_appenders(target_type_date_file, "server_common_game_clubs_db")
append_to_appenders(target_type_date_file, "server_common_game_db")
append_to_appenders(target_type_date_file, "server_common_common_db")

local configure = {
    appenders = appenders
}

return configure