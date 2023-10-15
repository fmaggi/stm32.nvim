local Job = require('plenary.job')
local Server = {}

local function parse_args(config)
    local args = {}
    if config.halt then
        table.insert(args, '--halt')
    end

    if config.config_file ~= nil then
        table.insert(args, '-c')
        table.insert(args, config.config_file)
    end

    -- log_level
    table.insert(args, '-l')
    table.insert(args, config.log_level)

    if config.log_file ~= nil then
        table.insert(args, '-f')
        table.insert(args, config.log_file)
    end

    -- port
    table.insert(args, '-p')
    table.insert(args, config.port)

    if config.verbose then
        table.insert(args, '-v')
    end

    if config.refresh_delay ~= nil then
        table.insert(args, '-r')
        table.insert(args, config.refresh_delay)
    end

    if config.verify then
        table.insert(args, '-s')
    end

    if config.persistant then
        table.insert(args, '-e')
    end

    if config.swd ~= false then
        table.insert(args, '-d')
        if config.swd.port ~= nil then
            table.insert(args, '-z')
            table.insert(args, config.swd.port)
        end

        if config.swd.cpu_clock ~= nil then
            table.insert(args, '-a')
            table.insert(args, config.swd.cpu_clock)
        end

        if config.swd.clock_divider ~= nil then
            table.insert(args, '-b')
            table.insert(args, config.swd.clock_divider)
        end
    end

    if config.init_under_reset then
        table.insert(args, '-k')
    end

    if config.st_serial_number ~= nil then
        table.insert(args, '-i')
        table.insert(args, config.st_serial_number)
    end

    if config.max_frequency ~= nil then
        table.insert(args, '--frequency')
        table.insert(args, config.max_frequency)
    end

    if config.core ~= nil then
        table.insert(args, '-m')
        table.insert(args, config.core)
    end

    if config.attach_to_running_target then
        table.insert(args, '--attach')
    end

    if config.shared then
        table.insert(args, '-t')
    end

    if config.erase_all_memories then
        table.insert(args, '--erase-all')
    end

    if config.memory_map ~= nil then
        table.insert(args, '--memory-map')
        table.insert(args, config.memory_map)
    end

    if config.external_init then
        if config.external_memory_loader ~= nil then
            table.insert(args, '--external_init')
            table.insert(args, '-el')
            table.insert(args, config.external_memory_loader)
        else
            vim.notify('STM32: External init requires and external memory loader')
        end
    end

    if config.cube_programmer_path ~= nil then
        table.insert(args, '-cp')
        table.insert(args, config.cube_programmer_path)
    end

    if config.max_time_to_halt ~= nil then
        table.insert(args, '--pend-halt-timeout')
        table.insert(args, config.max_time_to_halt)
    end

    if config.temp_path ~= nil then
        table.insert(args, '--temp-path')
        table.insert(args, config.temp_path)
    end

    if config.preserve_temps then
        table.insert(args, '--preserve-temps')
    end

    return args
end

function Server.start(on_ready, on_success, config)
    if Server.is_running() then
        if on_ready ~= nil and Server.ready then
            on_ready()
        end
        vim.notify('STM32: Server is already running', vim.log.levels.WARN)
        return
    end

    Server.ready = false
    local args = parse_args(config)

    Server.instance = Job:new({
        command = config.server,
        args = args,
        on_stdout = function(_, message, _)
            if not Server.ready and message:find('^Waiting for debugger connection') then
                Server.ready = true
                if on_ready ~= nil then
                    vim.schedule(on_ready)
                else
                    vim.schedule(function()
                        vim.notify('STM32: Server ready', vim.log.levels.INFO)
                    end)
                end
            end
        end,
        on_exit = function(_, return_val)
            Server.ready = false
            Server.instance = nil
            if return_val == 0 then
                if on_success ~= nil then
                    vim.schedule(on_success)
                end
            else
                vim.schedule(function()
                    vim.notify(string.format('STM32: ST-LINK_gdbserver exited with error code %d', return_val),
                        vim.log.levels.ERROR)
                end)
            end
        end,
    })

    Server.instance:start()
end

-- NOTE: I tried letting cpptools handle starting the server
--       as well but for some reason it never closed it quite right
--       so I decided to start the server my self
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

function Server.is_running()
    return Server.instance ~= nil
end

function Server.terminate()
    kill_server()
end

return Server
