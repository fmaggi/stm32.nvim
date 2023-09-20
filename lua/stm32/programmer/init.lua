local Job = require('plenary.job')

local M = {}

Programmer = {}

local function parse_connect_args(opts)
    local args = {}
    if opts.port == nil then
        vim.notify('STM32: Missing programmer port name', vim.log.levels.ERROR)
        return {}
    end
    table.insert(args, '-c')
    table.insert(args, 'port=' .. opts.port)

    if opts.port == 'SWD' then
        if opts.mode ~= nil then
            table.insert(args, 'mode=' .. opts.mode)
        end

        if opts.reset ~= nil then
            table.insert(args, 'reset=' .. opts.reset)
        end
    end
    return args
end

local function parse_write_args(opts)
    local args = {}
    local file
    if type(opts.file) == 'function' then
        file = opts.file()
    elseif type(opts.file) == 'string' then
        file = opts.file
    else
        vim.notify('STM32: unsupported file type', vim.log.levels.ERROR)
        return {}
    end

    if file == nil then
        vim.notify('STM32: no file', vim.log.levels.ERROR)
        return {}
    end

    table.insert(args, '-w')
    table.insert(args, file)

    if opts.address ~= nil then
        if vim.endswith(file, '.elf') then
            vim.notify('STM32: address is unused for elf files', vim.log.levels.WARN)
        else
            table.insert(args, opts.address)
        end
    end

    if opts.reset then
        table.insert(args, '-rst')
    end

    if opts.verify then
        table.insert(args, '--verify')
    end

    return args
end

local function parse_args(opts)
    local args = {}
    if opts.connect ~= nil then
        vim.list_extend(args, parse_connect_args(opts.connect))
    end

    if opts.write ~= nil then
        vim.list_extend(args, parse_write_args(opts.write))
    end

    return args
end

-- NOTE: I should probably remove this?
function M.setup(_)
end

function M.flash(on_success, config)
    local c = vim.tbl_deep_extend('keep', config or {}, require('stm32').get_programmer_config())
    local args = parse_args(c)
    Programmer.instance = Job:new({
        command = c.programmer,
        args = args,
        on_exit = function(j, return_val)
            Programmer.instance = nil
            if return_val == 0 then
                if on_success ~= nil then
                    vim.schedule(on_success)
                end
            else
                vim.schedule(function()
                    vim.notify(string.format('STM32_Cube_Programmer_CLI: %d, %s', return_val, vim.inspect(j:result())),
                        vim.log.levels.ERROR)
                end)
            end
        end,
    })

    Programmer.instance:start()
end

function M.is_running()
    return Programmer.instance ~= nil
end

function Programmer.terminate()
end

return M
