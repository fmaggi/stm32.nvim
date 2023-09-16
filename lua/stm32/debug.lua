local Job = require('plenary.job')
local dap = require('dap')

local Debugger = {}

Server = {
    instance = nil,
    path = nil,
    args = nil
}

local function get_path(str)
    return str:match("(.*[/\\])")
end

local function parse_args(opts)
    local args = {}
    if opts.halt then
        table.insert(args, '--halt')
    end

    if opts.config_file ~= nil then
        table.insert(args, '-c')
        table.insert(args, opts.config_file)
    end

    -- log_level
    table.insert(args, '-l')
    table.insert(args, opts.log_level)

    if opts.log_file ~= nil then
        table.insert(args, '-f')
        table.insert(args, opts.log_file)
    end

    -- port
    table.insert(args, '-p')
    table.insert(args, opts.port)

    if opts.verbose then
        table.insert(args, '-v')
    end

    if opts.refresh_delay ~= nil then
        table.insert(args, '-r')
        table.insert(args, opts.refresh_delay)
    end

    if opts.verify then
        table.insert(args, '-s')
    end

    if opts.persistant then
        table.insert(args, '-e')
    end

    if opts.swd ~= nil then
        table.insert(args, '-d')
        if opts.swd.port ~= nil then
            table.insert(args, '-z')
            table.insert(args, opts.swd.port)
        end

        if opts.swd.cpu_clock ~= nil then
            table.insert(args, '-a')
            table.insert(args, opts.swd.cpu_clock)
        end

        if opts.swd.clock_divider ~= nil then
            table.insert(args, '-b')
            table.insert(args, opts.swd.clock_divider)
        end
    end

    if opts.init_under_reset then
        table.insert(args, '-k')
    end

    if opts.st_serial_number ~= nil then
        table.insert(args, '-i')
        table.insert(args, opts.st_serial_number)
    end

    if opts.max_frequency ~= nil then
        table.insert(args, '--frequency')
        table.insert(args, opts.max_frequency)
    end

    if opts.core ~= nil then
        table.insert(args, '-m')
        table.insert(args, opts.core)
    end

    if opts.attach_to_running_target then
        table.insert(args, '--attach')
    end

    if opts.shared then
        table.insert(args, '-t')
    end

    if opts.erase_all_memories then
        table.insert(args, '--erase-all')
    end

    if opts.memory_map ~= nil then
        table.insert(args, '--memory-map')
        table.insert(args, opts.memory_map)
    end

    if opts.external_init then
        if opts.external_memory_loader ~= nil then
            table.insert(args, '--external_init')
            table.insert(args, '-el')
            table.insert(args, opts.external_memory_loader)
        else
            vim.notify('STM32: External init requires and external memory loader')
        end
    end

    if opts.cube_programmer_path ~= nil then
        table.insert(args, '-cp')
        table.insert(args, opts.cube_programmer_path)
    end

    if opts.max_time_to_halt ~= nil then
        table.insert(args, '--pend-halt-timeout')
        table.insert(args, opts.max_time_to_halt)
    end

    if opts.temp_path ~= nil then
        table.insert(args, '--temp-path')
        table.insert(args, opts.temp_path)
    end

    if opts.preserve_temps then
        table.insert(args, '--preserve-temps')
    end

    return args
end

local function config_dap(opts)
    local config = {
        name = opts.name,
        type = 'cppdbg',
        request = 'launch',
        MIMode = 'gdb',
        miDebuggerPath = opts.gdb_path,
        miDebuggerServerAddress = string.format('%s:%d', opts.server_url, opts.port),
        cwd = '${workspaceFolder}',
        program = opts.program,
        stopAtEntry = opts.stopAtEntry
    }

    for _, lang in pairs(opts.languages) do
        lang = vim.split(lang, '@')[1]
        if dap.configurations[lang] == nil then
            dap.configurations[lang] = { config }
        else
            table.insert(dap.configurations[lang], config)
        end
    end
end

function Debugger.setup(stlink_gdb_server_opts, dap_opts)
    Server.path = stlink_gdb_server_opts.server
    Server.args = parse_args(stlink_gdb_server_opts)

    if dap_opts ~= nil then
        dap_opts.port = stlink_gdb_server_opts.port
        config_dap(dap_opts)
    end
end

-- NOTE: I tried letting cpptools handle starting the server
--       as well but for some reason it never closed it quite right
--       so I decided to start the server my self
function Debugger.debug(start_dap)
    if Server.args == nil or Server.path == nil then
        local config = require('stm32').get_config()
        Server.args = parse_args(config.stlink_gdb_server_opts)
        Server.path = get_path(config.stlink_gdb_server_opts.server)
    end
    if Debugger.is_running() then
        vim.notify('STM32: Server is already running', vim.log.levels.WARN)
        return
    end

    Server.instance = Job:new({
        command = Server.path,
        args = Server.args,
        cwd = get_path(Server.path),
        on_stdout = function(_, message, _)
            if start_dap and next(dap.sessions()) == nil and message:find('^Waiting for debugger connection') then
                vim.schedule(function()
                    dap.continue()
                end)
            end
        end,
        on_exit = function(j, return_val)
            Server.instance = nil
            if return_val ~= 0 then
                vim.notify(string.format('ST-LINK_gdbserver error: %d, %s', return_val, vim.inspect(j:result())), vim.log.levels.ERROR)
            end
        end,
    })

    Server.instance:start()
end

local function kill_server()
    if Server.instance ~= nil then
        local _handle = io.popen("kill " .. Server.instance.pid)
        if _handle ~= nil then
            _handle:close()
        end
    end
end

-- HACK: the server isn't stopped if neovim quits
vim.api.nvim_create_autocmd("VimLeavePre", { callback = kill_server })

function Debugger.is_running()
    return Server.instance ~= nil
end

function Debugger.terminate()
    kill_server()
end

return Debugger
