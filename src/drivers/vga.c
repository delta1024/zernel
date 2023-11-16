#include <drivers/vga.h>
#include <kernel/io.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

#define VGA_CTRL_REGISTER 0x3d4
#define VGA_DATA_REGISTER 0x3d5
#define VGA_OFFSET_LOW 0x0f
#define VGA_OFFSET_HIGH 0x0e
#define GET_CHAR_POS(y, x) ((y) * VGA_WIDTH + (x))


size_t strlen(const char* str) {
  size_t len = 0;
  while (str[len])
    len++;
  return len;
}

void terminal_initialize(vga_terminal_t* terminal) {
  terminal->column = 0;
  terminal->row = 0;
  terminal->color = VGA_ENTRY_COLOR(VGA_COLOR_WHITE, VGA_COLOR_BLACK);
  terminal->buffer = (vga_entry_t*)0xb8000;
  terminal_clear(terminal);
}


void terminal_put_entry_at(vga_terminal_t* terminal,char c) {
  const size_t index = terminal_get_offset(terminal) / 2;
  terminal->buffer[index] = VGA_ENTRY(c, terminal->color);
}

void terminal_put_char(vga_terminal_t* terminal,char c) {
  if (c == '\n') {
    terminal_write_nl(terminal);
    return;
  }
 
  terminal_put_entry_at(terminal,c);
  if (++terminal->column == VGA_WIDTH) {
    terminal->column = 0;
    if (++terminal->row == VGA_HEIGH)
      terminal->row = 0;
  }
}

void terminal_write(vga_terminal_t* terminal,const char* data, size_t size) {
  for (size_t i = 0; i < size; i++)
    terminal_put_char(terminal, data[i]);
  set_cursor(terminal_get_offset(terminal));
}

void terminal_write_string(vga_terminal_t* terminal,const char* data) {
  terminal_write(terminal,data, strlen(data));
}
void terminal_write_nl(vga_terminal_t* terminal) {
  terminal->column  = 0;
  if (++terminal->row == VGA_HEIGH)
    terminal->row = 0;
  set_cursor(terminal_get_offset(terminal));
}
vga_cursor_t terminal_get_offset(vga_terminal_t* terminal) {
    return 2 * GET_CHAR_POS(terminal->row, terminal->column);
}

void terminal_clear(vga_terminal_t* terminal) {
  for (vga_entry_t i = 0; i < (VGA_WIDTH * VGA_HEIGH); i++)
    terminal->buffer[i] = VGA_ENTRY(' ', terminal->color);
  set_cursor(0);
}
void set_cursor(vga_cursor_t offset) {
  offset /= 2;
  port_byte_out(VGA_CTRL_REGISTER, VGA_OFFSET_HIGH);
  port_byte_out(VGA_DATA_REGISTER, (unsigned char) (offset >> 8));
  port_byte_out(VGA_CTRL_REGISTER, VGA_OFFSET_LOW);
  port_byte_out(VGA_DATA_REGISTER, (unsigned char) (offset & 0xff));
}
vga_cursor_t get_cursor() {
  port_byte_out(VGA_CTRL_REGISTER, VGA_OFFSET_HIGH);
  vga_cursor_t offset = port_byte_in(VGA_DATA_REGISTER) << 8;
  port_byte_out(VGA_CTRL_REGISTER, VGA_OFFSET_LOW);
  offset += port_byte_in(VGA_DATA_REGISTER);
  return offset * 2;
}

#undef  VGA_CTRL_REGISTER
#undef	VGA_DATA_REGISTER
#undef	VGA_OFFSET_LOW 
#undef	VGA_OFFSET_HIGH 
#undef GET_CHAR_POS
