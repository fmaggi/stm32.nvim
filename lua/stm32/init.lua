local Path = require('plenary.path')

local M = {}

Exe = nil

function M.get_exe()
    if Exe == nil then
        M.set_exe()
    end
    return Exe
end

function M.set_exe()
    Exe = vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
end

local default_config = {
    stlink_gdb_server = {
        server = vim.fn.expand('~') .. '/.local/stm32/STLINKgdbServer/ST-LINK_gdbserver',
        halt = false,
        config_file = nil,
        log_level = 1,
        log_file = nil,
        port = 61234,
        verbose = false,
        refresh_delay = nil,
        verify = true,
        persistant = false,
        swd = {
            port = 61235,
            cpu_clock = nil,
            swo_clock_divider = nil
        },
        init_under_reset = true,
        st_serial_number = nil,
        max_frequency = nil,
        core = 0,
        attach_to_running_target = false,
        shared = false,
        erase_all_memories = false,
        memory_map = nil,
        external_memory_loader = nil,
        external_init = false, -- requires external_memory_loader
        cube_programmer_path = nil,
        max_time_to_halt = nil,
        temp_path = nil,
        preserve_temps = false,
    },
    dap = {
        name = 'Debug STM32',
        gdb_path = 'arm-none-eabi-gdb',
        server_url = 'localhost', -- it uses the stlink_gdb_server port
        program = M.get_exe,
        stopAtEntry = false,
        languages = { 'c', 'cpp', 'rust', 'zig' }
    },
    stm32_programmer = {
        programmer = vim.fn.expand('~') .. '/.local/stm32/STM32CubeProgrammer/bin/STM32_Programmer_CLI',
        connect = {
            port = 'SWD',
            mode = 'UR',
            reset = 'HWrst'
        },
        write = {
            file = M.get_exe,
            address = nil,
            reset = true,
            verify = true,
        },
    }
}

ST_config = default_config

function M.setup(config)
    ST_config = vim.tbl_deep_extend("keep", config or {}, default_config)

    local server_path = Path:new(ST_config.stlink_gdb_server.server):absolute()
    ST_config.stlink_gdb_server.server = server_path

    local prog_path = Path:new(ST_config.stm32_programmer.programmer):absolute()
    ST_config.stm32_programmer.programmer = prog_path

    if ST_config.stlink_gdb_server.cube_programmer_path == nil then
        local path = Path:new(prog_path):parent()
        if path == nil then
            local s_path = Path:new(server_path):parent():joinpath('/STM32CubeProgrammer/bin/')
            if s_path == nil then
                vim.notify('STM32: path to STM32_Cube_Programmer_CLI not found. Server will not be able to run',
                    vim.log.levels.ERROR)
                return
            end
            path = s_path
        end
        ST_config.stlink_gdb_server.cube_programmer_path = path.filename
    end

    require('stm32.debugger').setup(ST_config.dap, ST_config.stlink_gdb_server.port)
end

function M.get_server_config()
    return ST_config.stlink_gdb_server
end

function M.get_dap_config()
    return ST_config.dap
end

function M.get_programmer_config()
    return ST_config.stm32_programmer
end

M.setup({ dap = false })

return M
