local dap = require('dap')
local Server = require('stm32.debugger.server')
local Programmer = require('stm32.programmer')

local Debugger = {}

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

function Debugger.setup(dap_opts, port)
    if dap_opts ~= false then
        dap_opts.port = port
        config_dap(dap_opts)
    end
end

function Debugger.start_server(on_ready, on_success, config)
    local server_config = vim.tbl_deep_extend('keep', config or {}, require('stm32').get_server_config())
    Server.start(on_ready, on_success, server_config)
end

function Debugger.debug(config)
    local function start_debug()
        vim.notify('STM32: flashing successful, starting debug server', vim.log.levels.INFO)
        Debugger.start_server(dap.continue, config)
    end
    Programmer.flash(start_debug)
end

function Debugger.terminate()
    dap.terminate()
    Server.terminate()
end

return Debugger
