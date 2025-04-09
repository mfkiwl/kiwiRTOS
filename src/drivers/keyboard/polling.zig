//! This file provides a polling-based keyboard driver based on the Intel 8042 PS/2 controller.

const arch = @import("../../arch/arch.zig");
const ps2 = @import("../ps2.zig");
const std = @import("std");

// // PS/2 Controller I/O Ports
// const PS2_DATA_PORT: u16 = 0x60;
// // PS/2 Controller I/O Ports
// const PS2_DATA_PORT: u16 = 0x60;
// const PS2_COMMAND_PORT: u16 = 0x64;
// const PS2_STATUS_PORT: u16 = 0x64;

/// PS/2 controller data port
pub const PS2_DATA_PORT = arch.PS2_DATA_PORT;

/// PS/2 controller status port
pub const PS2_STATUS_PORT = arch.PS2_STATUS_PORT;

/// PS/2 controller command port
pub const PS2_COMMAND_PORT = arch.PS2_COMMAND_PORT;

/// PS/2 controller status register
pub const PS2_STATUS_REGISTER = StatusRegister;

pub const StatusRegister = packed struct {
    /// Output buffer status (0 = empty, 1 = full)
    outputBuffer: u1,
    /// Input buffer status (0 = empty, 1 = full)
    inputBuffer: u1,
    /// System Flag (0 = cleared, 1 = set after self-test pass)
    systemFlag: u1,
    /// Command/data flag (0 = data for PS/2 device, 1 = for PS/2 command)
    commandData: u1,
    /// Chipset specific, possibly keyboard lock
    unknown: u1,
    /// Chip specific, possibly receive time-out or second port
    unknown2: u1,
    /// Time-out error (0 = no error, 1 = error)
    timeoutError: u1,
    /// Parity error (0 = no error, 1 = error)
    parityError: u1,
};

// // PS/2 Controller Commands
// const PS2_CMD_READ_CONFIG: u8 = 0x20;
// const PS2_CMD_WRITE_CONFIG: u8 = 0x60;
// const PS2_CMD_DISABLE_PORT1: u8 = 0xAD;
// const PS2_CMD_DISABLE_PORT2: u8 = 0xA7;
// const PS2_CMD_ENABLE_PORT1: u8 = 0xAE;

// // PS/2 Keyboard Commands
// const KB_CMD_RESET: u8 = 0xFF;
// const KB_CMD_SET_SCANCODE: u8 = 0xF0;
// const KB_CMD_ENABLE: u8 = 0xF4;
// const KB_CMD_SET_LEDS: u8 = 0xED;

// // PS/2 Controller Status Bits
// const PS2_STATUS_OUTPUT_FULL: u8 = 0x01;
// const PS2_STATUS_INPUT_FULL: u8 = 0x02;

// // PS/2 Controller Config Bits
// const PS2_CONFIG_PORT1_INT: u8 = 0x01;
// const PS2_CONFIG_PORT2_INT: u8 = 0x02;
// const PS2_CONFIG_PORT1_CLK: u8 = 0x10;
// const PS2_CONFIG_PORT2_CLK: u8 = 0x20;

// // PS/2 Keyboard Responses
// const KB_RESP_ACK: u8 = 0xFA;
// const KB_RESP_RESEND: u8 = 0xFE;
// const KB_RESP_SELF_TEST_PASS: u8 = 0xAA;

// // Print functions for debug
// extern fn printk(fmt: [*:0]const u8, ...) void;

// /// Read a byte from an I/O port
// inline fn inb(port: u16) u8 {
//     return asm volatile ("inb %[port], %[result]"
//         : [result] "={al}" (-> u8),
//         : [port] "N{dx}" (port),
//     );
// }

// /// Write a byte to an I/O port
// inline fn outb(port: u16, value: u8) void {
//     asm volatile ("outb %[value], %[port]"
//         :
//         : [value] "{al}" (value),
//           [port] "N{dx}" (port),
//     );
// }

// /// Wait for PS/2 controller to be ready for writing
// fn ps2WaitWrite() void {
//     var timeout: u16 = 1000;
//     while (timeout > 0) : (timeout -= 1) {
//         if ((inb(PS2_STATUS_PORT) & PS2_STATUS_INPUT_FULL) == 0) {
//             return;
//         }
//         // Short delay
//         asm volatile ("pause");
//     }
// }

// /// Wait for PS/2 controller to have data available
// fn ps2WaitRead() bool {
//     var timeout: u16 = 1000;
//     while (timeout > 0) : (timeout -= 1) {
//         if ((inb(PS2_STATUS_PORT) & PS2_STATUS_OUTPUT_FULL) != 0) {
//             return true;
//         }
//         // Short delay
//         asm volatile ("pause");
//     }
//     return false;
// }

// /// Send a command to the PS/2 controller
// fn ps2SendCommand(cmd: u8) void {
//     ps2WaitWrite();
//     outb(PS2_COMMAND_PORT, cmd);
// }

// /// Send data to the PS/2 controller
// fn ps2SendData(data: u8) void {
//     ps2WaitWrite();
//     outb(PS2_DATA_PORT, data);
// }

// /// Read data from the PS/2
// fn ps2ReadData() u8 {
//     _ = ps2WaitRead();
//     return inb(PS2_DATA_PORT);
// }

// /// Send a command to the keyboard
// fn kbSendCommand(cmd: u8) bool {
//     var retries: u8 = 3;
//     while (retries > 0) : (retries -= 1) {
//         ps2SendData(cmd);

//         if (ps2WaitRead()) {
//             const response = ps2ReadData();
//             if (response == KB_RESP_ACK) {
//                 return true;
//             } else if (response == KB_RESP_RESEND) {
//                 continue;
//             }
//         }
//     }
//     return false;
// }

// /// Send a command with a parameter to the keyboard
// fn kbSendCommandWithParam(cmd: u8, param: u8) bool {
//     var retries: u8 = 3;
//     while (retries > 0) : (retries -= 1) {
//         ps2SendData(cmd);

//         if (ps2WaitRead()) {
//             const response = ps2ReadData();
//             if (response == KB_RESP_ACK) {
//                 ps2SendData(param);
//                 if (ps2WaitRead()) {
//                     const param_response = ps2ReadData();
//                     if (param_response == KB_RESP_ACK) {
//                         return true;
//                     }
//                 }
//                 break;
//             } else if (response == KB_RESP_RESEND) {
//                 continue;
//             }
//         }
//     }
//     return false;
// }

// /// Initialize the PS/2 controller
// pub fn initController() bool {
//     // Disable both PS/2 ports
//     ps2SendCommand(PS2_CMD_DISABLE_PORT1);
//     ps2SendCommand(PS2_CMD_DISABLE_PORT2);

//     // Flush the output buffer
//     _ = inb(PS2_DATA_PORT);

//     // Read the current configuration
//     ps2SendCommand(PS2_CMD_READ_CONFIG);
//     const config = ps2ReadData();

//     // Modify configuration: enable port 1 interrupt and clock, disable port 2
//     const new_config = (config & ~(PS2_CONFIG_PORT2_INT | PS2_CONFIG_PORT2_CLK)) |
//         (PS2_CONFIG_PORT1_INT | PS2_CONFIG_PORT1_CLK);

//     // Write the new configuration
//     ps2SendCommand(PS2_CMD_WRITE_CONFIG);
//     ps2SendData(new_config);

//     // Enable PS/2 port 1
//     ps2SendCommand(PS2_CMD_ENABLE_PORT1);

//     return true;
// }

// /// Initialize the keyboard
// pub fn initKeyboard() bool {
//     // Reset the keyboard
//     if (!kbSendCommand(KB_CMD_RESET)) {
//         printk("Keyboard reset failed\n");
//         return false;
//     }

//     // Wait for self-test response
//     if (ps2WaitRead()) {
//         const self_test = ps2ReadData();
//         if (self_test != KB_RESP_SELF_TEST_PASS) {
//             printk("Keyboard self-test failed\n");
//             return false;
//         }
//     } else {
//         printk("Keyboard self-test timeout\n");
//         return false;
//     }

//     // Set scan code set 2 (most common)
//     if (!kbSendCommandWithParam(KB_CMD_SET_SCANCODE, 2)) {
//         printk("Setting scan code set failed\n");
//         return false;
//     }

//     // Enable keyboard
//     if (!kbSendCommand(KB_CMD_ENABLE)) {
//         printk("Enabling keyboard failed\n");
//         return false;
//     }

//     return true;
// }

// /// Initialize the keyboard driver
// pub fn init() bool {
//     const controller_ok = initController();
//     if (!controller_ok) {
//         printk("PS/2 controller initialization failed\n");
//         return false;
//     }

//     const keyboard_ok = initKeyboard();
//     if (!keyboard_ok) {
//         printk("Keyboard initialization failed\n");
//         return false;
//     }

//     printk("Keyboard initialized successfully\n");
//     return true;
// }

// /// Check if a key is available to read
// pub fn isKeyAvailable() bool {
//     return (inb(PS2_STATUS_PORT) & PS2_STATUS_OUTPUT_FULL) != 0;
// }

// /// Read a key from the keyboard (returns raw scan code)
// pub fn readScanCode() ?u8 {
//     if (isKeyAvailable()) {
//         return inb(PS2_DATA_PORT);
//     }
//     return null;
// }

// // Simple scancode set 2 to ASCII mapping for common keys
// // This is a simplified mapping for common keys only
// fn mapScanCodeToAscii(scan_code: u8) ?u8 {
//     const ascii_table = [_]?u8{
//         // 0x00-0x0F
//         null, null, null, null, null, null, null, null, null, null, null, null, null, '\t', '`',  null,
//         // 0x10-0x1F
//         null, null, null, null, null, 'q',  '1',  null, null, null, 'z',  's',  'a',  'w',  '2',  null,
//         // 0x20-0x2F
//         null, 'c',  'x',  'd',  'e',  '4',  '3',  null, null, ' ',  'v',  'f',  't',  'r',  '5',  null,
//         // 0x30-0x3F
//         null, 'n',  'b',  'h',  'g',  'y',  '6',  null, null, null, 'm',  'j',  'u',  '7',  '8',  null,
//         // 0x40-0x4F
//         null, ',',  'k',  'i',  'o',  '0',  '9',  null, null, '.',  '/',  'l',  ';',  'p',  '-',  null,
//         // 0x50-0x5F
//         null, null, '\'', null, '[',  '=',  null, null, null, null, '\n', ']',  null, '\\', null, null,
//     };

//     if (scan_code < ascii_table.len) {
//         return ascii_table[scan_code];
//     }

//     return null;
// }

// /// Read a key and return its ASCII representation
// pub fn readKey() ?u8 {
//     if (readScanCode()) |code| {
//         // Skip release codes (0xF0 prefix in scan code set 2)
//         if (code == 0xF0) {
//             _ = readScanCode(); // Consume the next byte (the actual key that was released)
//             return null;
//         }

//         return mapScanCodeToAscii(code);
//     }

//     return null;
// }

// /// Poll the keyboard until a key is pressed and return its ASCII value
// pub fn getChar() u8 {
//     while (true) {
//         if (readKey()) |c| {
//             return c;
//         }
//     }
// }
