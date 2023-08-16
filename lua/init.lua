local this = {
    ---Default options for logging
    default = {
        ---Name to be logged with whole message in logs
        name = "consolelog",

        ---Default level to be used if not specified
        level = "info",

        ---Various levels
        levels = {
            trace = { priority = 100, hl = "Comment" },
            debug = { priority = 90, hl = "Comment" },
            info = { priority = 80, hl = "None" },
            warn = { priority = 70, hl = "WarningMsg" },
            error = { priority = 60, hl = "ErrorMsg" },
            fatal = { priority = 50, hl = "ErrorMsg" }
        }
    }
}

--[[
Initialise the module with provided options
@param opts table
@see :h consolelog.default
--]]
this.setup = function(opts)
    this.default = vim.tbl_deep_extend("force", this.default, opts)

    local config = this.default
    local msg_creator = function(...)
        local temp = {}
        for i = 1, select('#', ...) do
            local x = select(i, ...)
            temp[#temp + 1] = x
        end
        return table.concat(temp, " ")
    end

    local _log = function(lvl, ...)
        local src_info = debug.getinfo(2, "Sl")
        local code_line = src_info.short_src .. ":" .. src_info.currentline
        local msg = msg_creator(...)
        local log_line = string.format("[%-6s%s] %s : %s",
            lvl:upper(),
            os.date("%Y-%m-%d %H:%M:%S"),
            code_line,
            msg
        )

        vim.cmd(string.format("echohl %s", config.levels[lvl].hl))
        ---If message is multi line, then split the message by \n
        ---and log individually
        local log_line_parts = vim.split(log_line, "\n")
        for _, v in pairs(log_line_parts) do
            vim.cmd(string.format([[ echom "[%s] %s" ]], config.name, vim.fn.escape(v, '"')))
        end
    end

    local format = function(args)
        local temp = vim.split(args[1], "\n")
        local str_s = {}
        local pattern = "<>"
        local j = 2
        for i, v in pairs(temp) do
            local iter = string.gmatch(v, pattern)
            local sub_s = v
            while (true) do
                local match = iter()
                if match == nil then
                    break
                end
                ---If there are not element in rest to sub
                if j > #args then
                    return nil, "Invaid no of arguments!"
                end

                local arg = args[j]
                sub_s = string.gsub(sub_s, pattern, vim.inspect(arg), 1)
                j = j + 1
            end
            str_s[i] = sub_s
        end
        return table.concat(str_s, "\n"), nil
    end

    local cur_l = config.levels[config.level].priority
    for k, v in pairs(this.default.levels) do
        this[k] = function(...)
            local fn_l = this.default.levels[k].priority
            if fn_l <= cur_l then
                _log(k, ...)
            end
        end
        this["f" .. k] = function(...)
            local fn_l = this.default.levels[k].priority
            if fn_l <= cur_l then
                local args = {}
                for i = 1, select("#", ...) do
                    local x = select(i, ...)
                    args[i] = x
                end
                local msg, err = format(args)
                if err ~= nil then
                    _log("error", err)
                else
                    _log(k, msg)
                end
            end
        end
    end

    return this
end

return this
