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

size_t terminal_row;
size_t terminal_colunm;
uint8_t terminal_color;
uint16_t* terminal_buffer;

size_t strlen(const char* str) {
  size_t len = 0;
  while (str[len])
    len++;
  return len;
}
int get_row_from_offset(int offset) {
  return offset / (2 * VGA_WIDTH);
}
int get_colunm_from_offset(int offset) {
  return (offset / 2) - get_row_from_offset(offset);
};
int get_offset(int col, int row) {
  return 2 * GET_CHAR_POS(row, col);
}
int move_offset_to_new_line(int offset) {
  return get_offset(0, get_row_from_offset(offset) + 1);
}
void terminal_initialize() {
  terminal_row = terminal_colunm = 0;
  terminal_color = VGA_ENTRY_COLOR(VGA_COLOR_WHITE, VGA_COLOR_BLACK);
  terminal_buffer = (uint16_t*) 0xB8000;
  for (size_t y = 0; y < VGA_HEIGTH; y++) {
    for (size_t x = 0; x < VGA_WIDTH; x++) {
      const size_t index = GET_CHAR_POS(y,x);
      terminal_buffer[index] = VGA_ENTRY(' ', terminal_color);
    }
  }
  set_cursor(0);
}

void terminal_set_color(uint8_t color) {
  terminal_color = color;
}

void terminal_put_entry_at(char c, uint8_t color, int offset) {
  const size_t index = offset / 2;
  terminal_buffer[index] = VGA_ENTRY(c, color);
}

void terminal_put_char(char c) {
  if (c == '\n') {
    terminal_write_nl();
    return;
  }
 
  terminal_put_entry_at(c, terminal_color, get_offset(terminal_colunm, terminal_row));
  if (++terminal_colunm == VGA_WIDTH) {
    terminal_colunm = 0;
    if (++terminal_row == VGA_HEIGTH)
      terminal_row = 0;
  }
}

void terminal_write(const char* data, size_t size) {
  for (size_t i = 0; i < size; i++)
    terminal_put_char(data[i]);
  set_cursor(get_offset(terminal_colunm, terminal_row));
}

void terminal_write_string(const char* data) {
  terminal_write(data, strlen(data));
}
void terminal_write_nl() {
  terminal_colunm  = 0;
  if (++terminal_row == VGA_HEIGTH)
    terminal_row = 0;
  set_cursor(get_offset(terminal_colunm, terminal_row));
}
void set_cursor(int offset) {
  offset /= 2;
  port_byte_out(VGA_CTRL_REGISTER, VGA_OFFSET_HIGH);
  port_byte_out(VGA_DATA_REGISTER, (unsigned char) (offset >> 8));
  port_byte_out(VGA_CTRL_REGISTER, VGA_OFFSET_LOW);
  port_byte_out(VGA_DATA_REGISTER, (unsigned char) (offset & 0xff));
}

int get_cursor() {
  port_byte_out(VGA_CTRL_REGISTER, VGA_OFFSET_HIGH);
  int offset = port_byte_in(VGA_DATA_REGISTER) << 8;
  port_byte_out(VGA_CTRL_REGISTER, VGA_OFFSET_LOW);
  offset += port_byte_in(VGA_DATA_REGISTER);
  return offset * 2;
}

#undef  VGA_CTRL_REGISTER
#undef	VGA_DATA_REGISTER
#undef	VGA_OFFSET_LOW 
#undef	VGA_OFFSET_HIGH 
#undef GET_CHAR_POS
