local logger = log4.get_logger("server_common_hotfix_util")

local function update_other_module(shields)
    for name, v in pairs(package.loaded) do
        local path = package.searchpath(name, package.path)
        if path 
            and (not (string.match(path, "/%w+/") == "/cloud/"))
            and (not table.member(shields, name)) then
            package.loaded[name] = dofile(path)
        end
    end
end

local function update_current_module(module_name, old_module)
    local path = package.searchpath(module_name, package.path)
    if not path then 
        logger.error("hotfix fail! module_name:%s", module_name)
    end
    local data = old_module.fetch_module_info()
    local new_module = dofile(path)
    new_module.update_module_info(data)
    package.loaded[module_name] = new_module
end

return {
    update = function(module_name, old_module, shields)
        logger.debug("update %s", module_name)
        if not package.loaded[module_name] then return end

        shields = shields or {}
        table.insert(shields, "hotfix_util")
        table.insert(shields, module_name)

        update_other_module(shields)
        update_current_module(module_name, old_module)
        return require(module_name)
    end
}