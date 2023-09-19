Exe = nil

local M = {}

function M.get_exe()
    if Exe == nil then
        Exe = vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end
    return Exe
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
    programmer = {}
}


ST_config = default_config

function M.setup(config)
    print('setup')
    ST_config = vim.tbl_deep_extend("keep", config or {}, default_config)
    print(vim.inspect(config), vim.inspect(ST_config))
    require('stm32.debug').setup(ST_config.stlink_gdb_server, ST_config.dap)
end

function M.get_config()
    return ST_config
end

M.setup({dap = nil})

return M
