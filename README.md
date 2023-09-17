
# STM32 neovim integration

## WHY
I used the STM32CubeIDE for a while but I hated it. First I tried to use OpenOCD
but that was a complete failure (probably a skill issue). So I checked how it programmed 
and debug the boards and decided to integrate it with neovim

## WIP
This is very very new. I use it for my personal projects. If you find any issue, 
or have some idea about how to improve it, feel free to open an issue or clone the
repo and open a pull request

## External Dependencies

* [cpptools](https://github.com/microsoft/vscode-cpptools/releases) (which can also be installed via mason)

you need to configure nvim-dap to use cpptools

* [STM32CubeProgrammerCLI](https://www.st.com/en/development-tools/stm32cubeprog.html)
* ST-LINK_gdbserver (I think it comes bundled with STM32CubeProgrammerCLI, it definetly comes with STM32CubeIDE)


## Installation

Once you have the dependencies installed

* only tested with neovim 0.9.2, use at your own peril
* With Lazy
```lua
{
    'fmaggi/stm32.nvim',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'mfussenegger/nvim-dap'
    },
    opts = {}
}
```

## Usage

### Debugging
you can start the server and gdb together
```lua
:lua require("stm32.debug").debug(true)
```

or just the server and start gdb yourself
```lua
:lua require("stm32.debug").debug(false)
```

### Flashing

TODO

## Configuration

if using lazy as your package manager you can pass your configs to ```opts``` otherwise you can call
```lua
require('stm32').setup({
    ...
})
```

([ST-LINK_gdbserver documentation](https://www.st.com/content/ccc/resource/technical/document/user_manual/group1/de/c1/e6/3d/89/18/4c/90/DM00613038/files/DM00613038.pdf/jcr:content/translations/en.DM00613038.pdf))

it comes with the following default config
```lua
local default_config = {
    -- configurations for ST-LINK_gdbserver
    stlink_gdb_server = {
        -- Server Path
        -- I've put the tools I need in my .local dir
        server = vim.fn.expand('~') .. '/.local/stm32/STLINKgdbServer/ST-LINK_gdbserver',
        halt = false,
        config_file = nil, -- custom config file, instead of using flags
        log_level = 1,
        log_file = nil,
        port = 61234, -- port for gdb client
        verbose = false,
        refresh_delay = nil,
        verify = true,

        -- whether server should exit when gdb server exits
        -- this is useful if you want to start the server once
        -- and then debug multiple times with your normal dap mappings
        persistant = true,

        -- options: 
        --     nil (use JTAG instead)
        --     table: 
        --          port (port where server dumps info)
        --          cpu_clock
        --          swo_clock_divider
        --
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

        -- ST-LINK_gdbserver needs STM32CubeProgrammerCLI
        -- by default it looks for it in ../STM32CubeProgrammer/bin
        -- or you can tell it where to look
        cube_programmer_path = nil,
        max_time_to_halt = nil,
        temp_path = nil,
        preserve_temps = false,
    },
    -- options:
    --      nil (do not configure dap)
    --      table:
    --          name (dap name)
    --          gdb_path (path to gdb)
    --          server_url (in case connecting remotely)
    --          program (program to debug. get_exe is a function that asks for a path first time, but then it remembers)
    --          stopAtEntry (whether to stop debugger at entry)
    --          languages (languages to configure dap for)
    -- It handles all the configuration in order to connect server and client
    dap = {
        name = 'Debug STM32',
        gdb_path = 'arm-none-eabi-gdb',
        server_url = 'localhost', -- it uses the stlink_gdb_server port
        program = get_exe,
        stopAtEntry = true,
        languages = { 'c', 'cpp', 'rust', 'zig' }
    },
}
```

## TODO

- [ ] Handle just flashing to the board
- [ ] Better logging
- [ ] Maybe include STM32CubeMX to generate config code
